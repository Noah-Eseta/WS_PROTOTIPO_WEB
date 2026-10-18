import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/http/error_carrito.dart';
import '../models/dto/carrito_api_dto.dart';
import '../models/estado_carrito.dart';
import '../models/item_carrito.dart';
import '../models/producto.dart';
import '../repositories/cart_repository.dart';
import '../repositories/api_cart_repository.dart';
import 'auth_provider.dart';
import 'catalogo_provider.dart';
import 'cliente_http_provider.dart';

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => ApiCartRepository(ref.watch(clienteHttpProvider)),
);
final generarOperacionCarritoProvider = Provider<String Function()>(
  (ref) => () {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return [
      hex.substring(0, 8),
      hex.substring(8, 12),
      hex.substring(12, 16),
      hex.substring(16, 20),
      hex.substring(20),
    ].join('-');
  },
);
final carritoProvider = NotifierProvider<CarritoNotifier, EstadoCarrito>(
  CarritoNotifier.new,
);

/// Un solo estado. Los lotes privados son instantáneas de operaciones, no cachés remotas.
class CarritoNotifier extends Notifier<EstadoCarrito> {
  static const maxPorProducto = 99;
  int _generacion = 0;
  int _ocupadas = 0;
  int _revisionOperaciones = 0;
  bool _preparada = false;
  Future<void>? _cola;
  _Fusion? _fusion;

  @override
  EstadoCarrito build() {
    ref.onDispose(() => _generacion++);
    ref.listen(authProvider.select((s) => (s.usuario?.id, s.expiraEn)), (
      _,
      actual,
    ) {
      _sesion(actual.$1);
    });
    final id = ref.read(authProvider).usuario?.id;
    if (id != null) {
      Future.microtask(() {
        if (ref.mounted && !_preparada) {
          _sesion(ref.read(authProvider).usuario?.id);
        }
      });
    } else {
      _preparada = true;
    }
    return EstadoCarrito(usuarioId: id);
  }

  void _asegurarSesion() {
    final id = ref.read(authProvider).usuario?.id;
    if (!_preparada || id != state.usuarioId) _sesion(id);
  }

  void _sesion(int? id) {
    _generacion++;
    _revisionOperaciones++;
    _ocupadas = 0;
    _cola = null;
    _preparada = true;
    state = EstadoCarrito(
      items: state.locales,
      usuarioId: id,
      fusionPendiente: _fusion != null,
    );
    if (id != null) {
      unawaited(sincronizar());
    }
  }

  bool _vigente(int generacion) => ref.mounted && generacion == _generacion;

  Future<bool> _encolar(Future<void> Function(int generacion) accion) {
    final generacion = _generacion;
    final revision = _revisionOperaciones;
    _ocupadas++;
    state = state.copiar(sincronizando: true, limpiarError: true);
    final resultado = (_cola ?? Future<void>.value()).then((_) async {
      if (!_vigente(generacion)) return false;
      try {
        if (revision != _revisionOperaciones) return false;
        await accion(generacion);
        return _vigente(generacion);
      } catch (error) {
        if (_vigente(generacion)) {
          _revisionOperaciones++;
          final seguro = error is ErrorCarrito
              ? error
              : const ErrorCarrito(
                  'No se pudo sincronizar el carrito. Vuelve a consultarlo.',
                );
          state = state.copiar(
            error: seguro,
            necesitaConsulta: true,
            fusionPendiente: _fusion != null,
          );
          if (seguro.estadoHttp == 409) {
            try {
              await _consultar(generacion);
              if (_vigente(generacion)) {
                state = state.copiar(error: seguro, necesitaConsulta: false);
              }
            } catch (_) {
              /* Se conserva el error y se exige una consulta explícita. */
            }
          }
        }
        return false;
      } finally {
        if (_vigente(generacion)) {
          _ocupadas--;
          if (_ocupadas == 0) _cola = null;
          state = state.copiar(sincronizando: _ocupadas > 0);
        }
      }
    });
    _cola = resultado.then((_) {});
    return resultado;
  }

  Future<T> _peticion<T>(
    Future<T> Function(String token, CartRepository repo) accion,
  ) => ref
      .read(authProvider.notifier)
      .conToken((token) => accion(token, ref.read(cartRepositoryProvider)));

  Future<void> _consultar(int generacion) async {
    final dto = await _peticion((token, repo) => repo.consultar(token));
    final actuales = ref.read(catalogoProvider).asData?.value;
    final List<Producto> catalogo =
        actuales ?? (await ref.read(catalogoProvider.future));
    if (!_vigente(generacion)) return;
    state = state.copiar(
      remotos: dto.items.map((i) => i.aItem(catalogo)),
      version: dto.version,
      necesitaConsulta: false,
    );
  }

  Future<bool> sincronizar() {
    _asegurarSesion();
    if (state.usuarioId == null) return Future.value(true);
    return _encolar((generacion) async {
      await _consultar(generacion);
      if (!_vigente(generacion)) return;
      final compatibles = state.locales
          .where((i) => i.producto.sincronizable)
          .toList();
      if (_fusion == null && compatibles.isNotEmpty) {
        _fusion = _Fusion(
          ref.read(generarOperacionCarritoProvider)(),
          state.usuarioId!,
          compatibles,
        );
      }
      final lote = _fusion;
      if (lote == null) return;
      if (lote.usuario != state.usuarioId) {
        throw const ErrorCarrito(
          'Hay una fusión pendiente de otra cuenta. Vuelve a esa cuenta para resolverla; tus selecciones locales se conservan.',
        );
      }
      state = state.copiar(fusionPendiente: true);
      lote.incierta = true;
      try {
        final recibo = await _peticion(
          (token, repo) =>
              repo.fusionar(token, lote.id, lote.lineas, state.version!),
        );
        if (!_vigente(generacion)) return;
        if (recibo.operacion != lote.id ||
            recibo.cantidadLineas != lote.items.length) {
          throw const ErrorCarrito(
            'No se pudo verificar el comprobante de fusión.',
            resultadoIncierto: true,
          );
        }
        final locales = [...state.locales];
        for (final item in lote.items) {
          final index = locales.indexWhere((i) => i.clave == item.clave);
          if (index < 0) continue;
          final restante = locales[index].cantidad - item.cantidad;
          if (restante > 0) {
            locales[index] = locales[index].copyWith(cantidad: restante);
          } else {
            locales.removeAt(index);
          }
        }
        _fusion = null;
        state = state.copiar(
          locales: locales,
          fusionPendiente: false,
          necesitaConsulta: true,
        );
        await _consultar(generacion);
      } on ErrorCarrito catch (error) {
        if (_vigente(generacion) &&
            !error.resultadoIncierto &&
            (error.estadoHttp == 422 ||
                error.codigo == 'CART_VERSION_CONFLICT')) {
          lote.incierta = false;
        }
        rethrow;
      }
    });
  }

  /// Actualiza la vista sin reintentar modificaciones ni fusionar lotes.
  Future<bool> actualizar() {
    _asegurarSesion();
    if (state.usuarioId == null) return Future.value(true);
    return _encolar(_consultar);
  }

  void _comprobarRemoto() {
    if (state.version == null ||
        state.necesitaConsulta ||
        _fusion != null ||
        state.locales.any((i) => i.producto.sincronizable)) {
      throw const ErrorCarrito(
        'Primero consulta el carrito o resuelve la fusión pendiente.',
      );
    }
  }

  Future<void> _aceptar(CarritoApiDto dto, int generacion) async {
    final actuales = ref.read(catalogoProvider).asData?.value;
    final List<Producto> catalogo =
        actuales ?? (await ref.read(catalogoProvider.future));
    if (!_vigente(generacion)) return;
    state = state.copiar(
      remotos: dto.items.map((i) => i.aItem(catalogo)),
      version: dto.version,
      necesitaConsulta: false,
      limpiarError: true,
    );
  }

  Future<bool> agregar(Producto producto) {
    _asegurarSesion();
    if (!producto.disponible) return Future.value(false);
    if (state.usuarioId == null || !producto.sincronizable) {
      return Future.value(_agregarLocal(producto));
    }
    return _encolar((generacion) async {
      _comprobarRemoto();
      final actual =
          state.remotos
              .where((i) => i.producto.id == producto.id)
              .firstOrNull
              ?.cantidad ??
          0;
      if (actual >= maxPorProducto) {
        throw const ErrorCarrito('El máximo es 99 unidades.');
      }
      await _aceptar(
        await _peticion(
          (token, repo) =>
              repo.establecer(token, producto.id!, actual + 1, state.version!),
        ),
        generacion,
      );
    });
  }

  bool _editarLocal(String clave) {
    if (_fusion == null || !_fusion!.items.any((i) => i.clave == clave)) {
      return true;
    }
    if (_fusion!.incierta || _fusion!.usuario != state.usuarioId) {
      state = state.copiar(
        error: const ErrorCarrito(
          'Confirma primero la fusión pendiente. Su contenido se conserva para reintentar sin duplicados.',
        ),
      );
      return false;
    }
    _fusion = null;
    state = state.copiar(fusionPendiente: false);
    return true;
  }

  bool _agregarLocal(Producto producto) {
    final nuevo = ItemCarrito(producto);
    if (!_editarLocal(nuevo.clave)) return false;
    final locales = [...state.locales];
    final index = locales.indexWhere((i) => i.clave == nuevo.clave);
    if (index == -1) {
      locales.add(nuevo);
    } else if (locales[index].cantidad < maxPorProducto) {
      locales[index] = locales[index].copyWith(
        cantidad: locales[index].cantidad + 1,
      );
    } else {
      return false;
    }
    state = state.copiar(locales: locales);
    return true;
  }

  ItemCarrito? _buscar(String clave) => state.items
      .where(
        (i) =>
            i.clave == clave ||
            (i.producto.sincronizable && i.producto.id == clave),
      )
      .firstOrNull;

  Future<bool> cambiarCantidad(String clave, int delta) {
    _asegurarSesion();
    final item = _buscar(clave);
    if (item == null) return Future.value(false);
    if (!item.persistente) {
      if (!_editarLocal(item.clave)) return Future.value(false);
      final cantidad = item.cantidad + delta;
      if (cantidad <= 0) return quitar(item.clave);
      if (cantidad > maxPorProducto || delta == 0) return Future.value(false);
      state = state.copiar(
        locales: [
          for (final i in state.locales)
            if (i.clave == item.clave) i.copyWith(cantidad: cantidad) else i,
        ],
      );
      return Future.value(true);
    }
    return _encolar((generacion) async {
      _comprobarRemoto();
      final actual = _buscar(clave);
      if (actual == null) return;
      final cantidad = actual.cantidad + delta;
      if (cantidad > maxPorProducto || delta == 0) return;
      final dto = cantidad <= 0
          ? await _peticion(
              (token, repo) =>
                  repo.eliminar(token, actual.producto.id!, state.version!),
            )
          : await _peticion(
              (token, repo) => repo.establecer(
                token,
                actual.producto.id!,
                cantidad,
                state.version!,
              ),
            );
      await _aceptar(dto, generacion);
    });
  }

  Future<bool> quitar(String clave) {
    _asegurarSesion();
    final item = _buscar(clave);
    if (item == null) return Future.value(false);
    if (!item.persistente) {
      if (!_editarLocal(item.clave)) return Future.value(false);
      state = state.copiar(
        locales: state.locales.where((i) => i.clave != item.clave),
      );
      return Future.value(true);
    }
    return _encolar((generacion) async {
      _comprobarRemoto();
      await _aceptar(
        await _peticion(
          (token, repo) =>
              repo.eliminar(token, item.producto.id!, state.version!),
        ),
        generacion,
      );
    });
  }

  Future<bool> vaciar() {
    _asegurarSesion();
    if (state.usuarioId == null) {
      if (_fusion != null) return Future.value(false);
      state = EstadoCarrito();
      return Future.value(true);
    }
    final localesAlSolicitar = state.locales;
    return _encolar((generacion) async {
      _comprobarRemoto();
      final dto = await _peticion(
        (token, repo) => repo.vaciar(token, state.version!),
      );
      await _aceptar(dto, generacion);
      if (_vigente(generacion)) _consumirLocales(localesAlSolicitar);
    });
  }

  /// Solo una simulación exclusivamente local puede consumir sus selecciones.
  /// Este método no llama a ningún repositorio ni modifica las líneas remotas.
  void consumirDemostracion(EstadoCarrito instantanea) {
    if (instantanea.remotos.isNotEmpty ||
        instantanea.locales.any((i) => i.producto.sincronizable)) {
      return;
    }
    _consumirLocales(instantanea.locales);
  }

  void _consumirLocales(List<ItemCarrito> seleccion) {
    final locales = [...state.locales];
    for (final item in seleccion) {
      final index = locales.indexWhere(
        (i) => i.clave == item.clave && identical(i.producto, item.producto),
      );
      if (index < 0) continue;
      final restante = locales[index].cantidad - item.cantidad;
      if (restante <= 0) {
        locales.removeAt(index);
      } else {
        locales[index] = locales[index].copyWith(cantidad: restante);
      }
    }
    if (seleccion.isNotEmpty) state = state.copiar(locales: locales);
  }
}

final class _Fusion {
  final String id;
  final int usuario;
  final List<ItemCarrito> items;
  bool incierta = true;
  _Fusion(this.id, this.usuario, List<ItemCarrito> items)
    : items = List.unmodifiable(items);
  List<({String id, int cantidad})> get lineas => List.unmodifiable([
    for (final i in items) (id: i.producto.id!, cantidad: i.cantidad),
  ]);
}
