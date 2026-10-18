import 'dart:convert';

import 'package:prototipo_app/core/http/error_carrito.dart';
import 'package:prototipo_app/models/dto/carrito_api_dto.dart';
import 'package:prototipo_app/repositories/cart_repository.dart';

import 'dio_test_adapter.dart';

/// Servidor en memoria exclusivo de pruebas; varias instancias de Flutter pueden compartirlo.
class CartTestRepository implements CartRepository {
  final datos = <String, CarritoApiDto>{};
  final recibos = <String, (String, ComprobanteFusion)>{};
  final llamadas = <({String metodo, String? id, int? version})>[];
  Future<void> Function(String metodo)? antes;
  Future<void> Function(String metodo)? despues;
  ErrorCarrito? errorConsulta;
  ErrorCarrito? errorMutacion;
  final catalogo = {
    for (final p in jsonCatalogoApi()['data'] as List)
      p['id'] as String: p as Map,
  };
  final lotes = <({String id, List<({String id, int cantidad})> items})>[];
  CarritoApiDto estado(String token) =>
      datos[token] ?? CarritoApiDto(0, const []);
  void sembrar(String token, CarritoApiDto carrito) => datos[token] = carrito;
  Future<void> _iniciar(String metodo, {String? id, int? version}) async {
    llamadas.add((metodo: metodo, id: id, version: version));
    await antes?.call(metodo);
    final error = metodo == 'GET' ? errorConsulta : errorMutacion;
    if (error != null) throw error;
  }

  void _version(String token, int version) {
    if (estado(token).version != version) {
      throw const ErrorCarrito(
        'Conflicto',
        estadoHttp: 409,
        codigo: 'CART_VERSION_CONFLICT',
      );
    }
  }

  LineaCarritoApi _linea(String id, int qty) {
    final p = catalogo[id];
    if (p == null) throw const ErrorCarrito('No existe', estadoHttp: 404);
    return LineaCarritoApi(id, p['name'], qty, p['price_cents']);
  }

  @override
  Future<CarritoApiDto> consultar(String token) async {
    await _iniciar('GET');
    return estado(token);
  }

  @override
  Future<CarritoApiDto> establecer(
    String token,
    String productoId,
    int cantidad,
    int version,
  ) async {
    await _iniciar('PUT', id: productoId, version: version);
    _version(token, version);
    final old = estado(token);
    final previous = old.items.where((i) => i.id == productoId).firstOrNull;
    final nueva = _linea(productoId, cantidad);
    if (cantidad < 1 ||
        cantidad > 99 ||
        (nueva.precioCentimos == null &&
            (previous == null || cantidad > previous.cantidad))) {
      throw const ErrorCarrito('No disponible', estadoHttp: 422);
    }
    final lines = [...old.items];
    final index = lines.indexWhere((i) => i.id == productoId);
    if (index < 0) {
      lines.add(nueva);
    } else {
      lines[index] = nueva;
    }
    datos[token] = CarritoApiDto(
      old.version + (previous?.cantidad == cantidad ? 0 : 1),
      lines,
    );
    await despues?.call('PUT');
    return estado(token);
  }

  @override
  Future<CarritoApiDto> eliminar(
    String token,
    String productoId,
    int version,
  ) async {
    await _iniciar('DELETE_ITEM', id: productoId, version: version);
    _version(token, version);
    final old = estado(token);
    final lines = old.items.where((i) => i.id != productoId).toList();
    datos[token] = CarritoApiDto(
      old.version + (lines.length == old.items.length ? 0 : 1),
      lines,
    );
    await despues?.call('DELETE_ITEM');
    return estado(token);
  }

  @override
  Future<CarritoApiDto> vaciar(String token, int version) async {
    await _iniciar('DELETE_CART', version: version);
    _version(token, version);
    final old = estado(token);
    datos[token] = CarritoApiDto(old.version + (old.items.isEmpty ? 0 : 1), []);
    await despues?.call('DELETE_CART');
    return estado(token);
  }

  @override
  Future<ComprobanteFusion> fusionar(
    String token,
    String operacion,
    List<({String id, int cantidad})> items,
    int version,
  ) async {
    lotes.add((id: operacion, items: List.unmodifiable(items)));
    await _iniciar('MERGE', version: version);
    final ordered = [...items]..sort((a, b) => a.id.compareTo(b.id));
    final hash = jsonEncode([
      for (final i in ordered) [i.id, i.cantidad],
    ]);
    final key = '$token/$operacion';
    final previous = recibos[key];
    if (previous != null) {
      if (previous.$1 != hash) {
        throw const ErrorCarrito(
          'Otro contenido',
          estadoHttp: 409,
          codigo: 'CART_MERGE_CONTENT_CONFLICT',
        );
      }
      final p = previous.$2;
      return ComprobanteFusion(
        p.operacion,
        p.versionAplicada,
        p.cantidadLineas,
        true,
      );
    }
    _version(token, version);
    final lines = [...estado(token).items];
    for (final item in items) {
      final index = lines.indexWhere((i) => i.id == item.id);
      final qty = item.cantidad + (index < 0 ? 0 : lines[index].cantidad);
      final line = _linea(item.id, qty);
      if (qty > 99 || line.precioCentimos == null) {
        throw const ErrorCarrito('Lote inválido', estadoHttp: 422);
      }
      if (index < 0) {
        lines.add(line);
      } else {
        lines[index] = line;
      }
    }
    final next = CarritoApiDto(version + 1, lines);
    final result = ComprobanteFusion(
      operacion,
      next.version,
      items.length,
      false,
    );
    datos[token] = next;
    recibos[key] = (hash, result);
    await despues?.call('MERGE');
    return result;
  }
}
