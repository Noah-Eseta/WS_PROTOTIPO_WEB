import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/core/http/error_carrito.dart';
import 'package:prototipo_app/models/dto/carrito_api_dto.dart';
import 'package:prototipo_app/models/estado_carrito.dart';
import 'package:prototipo_app/models/producto.dart';
import 'package:prototipo_app/models/usuario_autenticado.dart';
import 'package:prototipo_app/providers/carrito_provider.dart';
import 'package:prototipo_app/services/producto_service.dart';
import 'package:prototipo_app/services/pedido_service.dart';

import 'support/auth_test_repository.dart';

void main() {
  late ProviderContainer scope;
  late AuthTestRepository auth;
  late CartTestRepository server;
  late Producto canva;
  late CarritoNotifier carrito;
  EstadoCarrito estado() => scope.read(carritoProvider);
  const token = 'credencial-fixture-1';
  const demo = Producto(
    nombre: 'JUEGO · PAQUETE · ID 123',
    especial: true,
    subtitulo: '',
    categoria: 'Juegos',
    colores: [],
    entrega: '',
    precio: 8,
    logo: '',
    banner: '',
  );
  setUp(() async {
    auth = AuthTestRepository();
    server = CartTestRepository();
    scope = ProviderContainer(
      overrides: [
        walletRepositoryProvider.overrideWithValue(WalletTestRepository()),
        authRepositoryProvider.overrideWithValue(auth),
        cartRepositoryProvider.overrideWithValue(server),
        generarOperacionCarritoProvider.overrideWithValue(
          () => '5bb5ad46-c803-4d79-83ac-10c241f54a06',
        ),
      ],
    );
    canva = (await ProductoService().obtenerProductos()).firstWhere(
      (p) => p.nombre == 'CANVA PRO',
    );
    carrito = scope.read(carritoProvider.notifier);
  });
  tearDown(() => scope.dispose());

  test(
    'Los 34 UUID del mock son reales y se conservan en las copias',
    () async {
      final productos = await ProductoService().obtenerProductos();
      expect(productos.map((p) => p.id).toSet(), hasLength(34));
      for (final p in productos) {
        expect(uuidValido(p.id!), isTrue);
        expect(p.copiaInmutable().id, p.id);
        expect(server.catalogo[p.id]!['name'], p.nombre);
      }
      expect(productos.where((p) => !p.disponible), hasLength(11));
    },
  );

  test(
    'Visitante usa UUID y cantidades locales sin ninguna solicitud HTTP',
    () async {
      await carrito.agregar(canva);
      await carrito.agregar(
        canva.conPrecio(100, nombreActual: 'Nombre diferente'),
      );
      expect(estado().items, hasLength(1));
      expect(estado().cantidadTotal, 2);
      expect(estado().totalCentimos, 1580);
      expect(estado().items.single.producto.id, canva.id);
      expect(estado().items.single.producto.nombre, 'CANVA PRO');
      expect(server.llamadas, isEmpty);
      await carrito.cambiarCantidad(canva.id!, -1);
      await carrito.quitar(canva.id!);
      expect(estado().vacio, isTrue);
    },
  );

  test(
    'Login fusiona una vez y conserva las variantes sin convertirlas',
    () async {
      await carrito.agregar(canva);
      await carrito.agregar(canva);
      await carrito.agregar(demo);
      expect(await iniciarSesionPrueba(scope), isTrue);
      expect(estado().remotos.single.cantidad, 2);
      expect(estado().locales.single.producto.nombre, demo.nombre);
      expect(estado().locales.single.producto.especial, isTrue);
      expect(server.lotes.single.items, [(id: canva.id!, cantidad: 2)]);
      expect(estado().version, 1);
      await carrito.sincronizar();
      expect(server.lotes, hasLength(1));
      expect(estado().cantidadTotal, 3);
    },
  );

  test(
    'Otro dispositivo y un nuevo scope recuperan el carrito de la misma cuenta',
    () async {
      await iniciarSesionPrueba(scope);
      await carrito.agregar(canva);
      await carrito.agregar(canva);
      scope.dispose();
      scope = ProviderContainer(
        overrides: [
          walletRepositoryProvider.overrideWithValue(WalletTestRepository()),
          authRepositoryProvider.overrideWithValue(AuthTestRepository()),
          cartRepositoryProvider.overrideWithValue(server),
        ],
      );
      carrito = scope.read(carritoProvider.notifier);
      await iniciarSesionPrueba(scope);
      expect(estado().remotos.single.cantidad, 2);
      expect(estado().totalCentimos, 1580);
    },
  );

  test(
    'PUT y DELETE esperan confirmación y serializan las versiones',
    () async {
      await iniciarSesionPrueba(scope);
      final gate = Completer<void>();
      var primero = true;
      server.antes = (metodo) async {
        if (metodo == 'PUT' && primero) {
          primero = false;
          await gate.future;
        }
      };
      final uno = carrito.agregar(canva);
      final dos = carrito.agregar(canva);
      await Future<void>.delayed(Duration.zero);
      expect(estado().remotos, isEmpty);
      expect(estado().sincronizando, isTrue);
      gate.complete();
      expect(await uno, isTrue);
      expect(await dos, isTrue);
      expect(estado().remotos.single.cantidad, 2);
      expect(
        server.llamadas.where((p) => p.metodo == 'PUT').map((p) => p.version),
        [0, 1],
      );
      await carrito.cambiarCantidad(canva.id!, -1);
      expect(estado().remotos.single.cantidad, 1);
      await carrito.quitar(canva.id!);
      expect(estado().vacio, isTrue);
    },
  );

  test('409 recupera cambios ajenos y cancela modificaciones en cola sin repetir PUT', () async {
    await iniciarSesionPrueba(scope);
    server.sembrar(
      token,
      CarritoApiDto(5, [LineaCarritoApi(canva.id!, canva.nombre, 7, 850)]),
    );
    final uno = carrito.agregar(canva);
    final dos = carrito.agregar(canva);
    expect(await uno, isFalse);
    expect(await dos, isFalse);
    expect(estado().version, 5);
    expect(estado().remotos.single.cantidad, 7);
    expect(estado().totalCentimos, 5950);
    expect(estado().error?.estadoHttp, 409);
    expect(server.llamadas.where((p) => p.metodo == 'PUT'), hasLength(1));
  });

  test('Una respuesta perdida de merge conserva lote e ID y nunca duplica cantidades', () async {
    await carrito.agregar(canva);
    var perder = true;
    server.despues = (metodo) async {
      if (metodo == 'MERGE' && perder) {
        perder = false;
        throw const ErrorCarrito('Timeout', resultadoIncierto: true);
      }
    };
    await iniciarSesionPrueba(scope);
    expect(estado().locales.single.cantidad, 1);
    expect(estado().fusionPendiente, isTrue);
    expect(server.estado(token).items.single.cantidad, 1);
    expect(await carrito.quitar(estado().locales.single.clave), isFalse);
    expect(await carrito.sincronizar(), isTrue);
    expect(server.lotes, hasLength(2));
    expect(server.lotes[0].id, server.lotes[1].id);
    expect(server.lotes[0].items, server.lotes[1].items);
    expect(estado().locales, isEmpty);
    expect(estado().remotos.single.cantidad, 1);
  });

  test(
    'Un 422 de fusión no pierde selecciones y permite corregir el lote',
    () async {
      await carrito.agregar(canva);
      server.sembrar(
        token,
        CarritoApiDto(1, [LineaCarritoApi(canva.id!, canva.nombre, 99, 790)]),
      );
      await iniciarSesionPrueba(scope);
      expect(estado().locales.single.cantidad, 1);
      expect(estado().remotos.single.cantidad, 99);
      expect(server.estado(token).items.single.cantidad, 99);
      expect(await carrito.quitar(estado().locales.single.clave), isTrue);
      expect(estado().remotos.single.cantidad, 99);
    },
  );

  test(
    'Vaciar fallido conserva tanto productos persistentes como especiales',
    () async {
      await iniciarSesionPrueba(scope);
      await carrito.agregar(canva);
      await carrito.agregar(demo);
      server.errorMutacion = const ErrorCarrito(
        'Sin conexión',
        resultadoIncierto: true,
      );
      expect(await carrito.vaciar(), isFalse);
      expect(estado().remotos.single.producto.id, canva.id);
      expect(estado().locales.single.producto.nombre, demo.nombre);
      expect(server.estado(token).items.single.cantidad, 1);
      server.errorMutacion = null;
      await carrito.actualizar();
      expect(await carrito.vaciar(), isTrue);
      expect(estado().vacio, isTrue);
      expect(server.estado(token).items, isEmpty);
    },
  );

  test(
    '401 limpia autenticación y vista privada sin borrar PostgreSQL',
    () async {
      await iniciarSesionPrueba(scope);
      await carrito.agregar(canva);
      server.errorMutacion = const ErrorCarrito('Caducada', estadoHttp: 401);
      expect(await carrito.quitar(canva.id!), isFalse);
      expect(scope.read(authProvider).iniciada, isFalse);
      expect(estado().remotos, isEmpty);
      expect(server.estado(token).items.single.cantidad, 1);
      expect(server.llamadas.where((p) => p.metodo == 'DELETE_CART'), isEmpty);
    },
  );

  test(
    'Logout y cambio de cuenta no convierten artículos remotos en visitantes',
    () async {
      await iniciarSesionPrueba(scope);
      await carrito.agregar(canva);
      await scope.read(authProvider.notifier).cerrarSesion();
      expect(estado().items, isEmpty);
      expect(server.estado(token).items.single.cantidad, 1);
      auth.usuario = const UsuarioAutenticado(
        id: 2,
        nombre: 'Otra',
        correo: 'otra@example.test',
      );
      await iniciarSesionPrueba(scope);
      expect(estado().items, isEmpty);
      expect(server.lotes, isEmpty);
      expect(server.llamadas.where((p) => p.metodo == 'DELETE_CART'), isEmpty);
    },
  );

  test(
    'Una respuesta tardía de la cuenta anterior nunca restaura sus datos',
    () async {
      await iniciarSesionPrueba(scope);
      final gate = Completer<void>();
      server.antes = (metodo) async {
        if (metodo == 'PUT') await gate.future;
      };
      final pending = carrito.agregar(canva);
      await Future<void>.delayed(Duration.zero);
      await scope.read(authProvider.notifier).cerrarSesion();
      auth.usuario = const UsuarioAutenticado(
        id: 2,
        nombre: 'Otra',
        correo: 'otra@example.test',
      );
      await iniciarSesionPrueba(scope);
      gate.complete();
      expect(await pending, isFalse);
      expect(estado().usuarioId, 2);
      expect(estado().items, isEmpty);
    },
  );

  test(
    'No disponibles permanecen visibles y solo permiten reducir o eliminar',
    () async {
      server.sembrar(
        token,
        CarritoApiDto(2, [LineaCarritoApi(canva.id!, canva.nombre, 3, null)]),
      );
      server.catalogo[canva.id]!['price_cents'] = null;
      await iniciarSesionPrueba(scope);
      expect(estado().contieneNoDisponibles, isTrue);
      expect(estado().totalCentimos, 0);
      expect(estado().puedeSimular, isFalse);
      expect(await carrito.cambiarCantidad(canva.id!, 1), isFalse);
      await carrito.actualizar();
      expect(await carrito.cambiarCantidad(canva.id!, -1), isTrue);
      expect(estado().remotos.single.cantidad, 2);
      expect(await carrito.quitar(canva.id!), isTrue);
    },
  );

  test('Simular con persistentes o mezcla nunca llama DELETE ni consume selecciones', () async {
    await iniciarSesionPrueba(scope);
    await carrito.agregar(canva);
    for (final mixto in [false, true]) {
      if (mixto) await carrito.agregar(demo);
      final snapshot = estado();
      final peticiones = server.llamadas.length;
      PedidoService.instancia.registrar(
        snapshot,
        'Yape',
        sesionIniciada: true,
        vaciarCarrito: () => carrito.consumirDemostracion(snapshot),
      );
      expect(estado().remotos.single.cantidad, 1);
      expect(server.estado(token).items.single.cantidad, 1);
      expect(server.llamadas.length, peticiones);
      if (mixto) expect(estado().locales.single.producto.nombre, demo.nombre);
    }
  });

  test('Solo una simulación local completada consume especiales, nunca un registro fallido', () async {
    await carrito.agregar(demo);
    final snapshot = estado();
    expect(
      () => PedidoService.instancia.registrar(
        snapshot,
        'Yape',
        sesionIniciada: false,
        vaciarCarrito: () => carrito.consumirDemostracion(snapshot),
      ),
      throwsStateError,
    );
    expect(estado().cantidadTotal, 1);
    PedidoService.instancia.registrar(
      snapshot,
      'Yape',
      sesionIniciada: true,
      vaciarCarrito: () => carrito.consumirDemostracion(snapshot),
    );
    expect(estado().vacio, isTrue);
    expect(server.llamadas, isEmpty);
  });

  test('Una fusión incierta no se traslada a otra cuenta ni pierde el ID al volver', () async {
    await carrito.agregar(canva);
    server.despues = (metodo) async {
      if (metodo == 'MERGE') {
        throw const ErrorCarrito('Respuesta perdida', resultadoIncierto: true);
      }
    };
    await iniciarSesionPrueba(scope);
    final lote = server.lotes.single;
    await scope.read(authProvider.notifier).cerrarSesion();
    auth.usuario = const UsuarioAutenticado(
      id: 2,
      nombre: 'Otra',
      correo: 'otra@example.test',
    );
    await iniciarSesionPrueba(scope);
    expect(estado().remotos, isEmpty);
    expect(estado().locales.single.cantidad, 1);
    expect(server.lotes, hasLength(1));
    expect(await carrito.quitar(canva.id!), isFalse);
    await scope.read(authProvider.notifier).cerrarSesion();
    auth.usuario = const UsuarioAutenticado(
      id: 1,
      nombre: 'Persona',
      correo: 'persona@example.test',
    );
    server.despues = null;
    await iniciarSesionPrueba(scope);
    expect(server.lotes.last.id, lote.id);
    expect(server.lotes.last.items, lote.items);
    expect(estado().locales, isEmpty);
    expect(estado().remotos.single.cantidad, 1);
    expect(server.estado(token).items.single.cantidad, 1);
  });

  test('Un GET fallido después del comprobante no vuelve a sumar el lote confirmado', () async {
    await carrito.agregar(canva);
    server.despues = (metodo) async {
      if (metodo == 'MERGE') {
        server.errorConsulta = const ErrorCarrito('Sin conexión');
      }
    };
    await iniciarSesionPrueba(scope);
    expect(estado().locales, isEmpty);
    expect(estado().fusionPendiente, isFalse);
    expect(estado().necesitaConsulta, isTrue);
    server.errorConsulta = null;
    server.despues = null;
    expect(await carrito.sincronizar(), isTrue);
    expect(server.lotes, hasLength(1));
    expect(estado().remotos.single.cantidad, 1);
  });

  test('Vaciar espera Laravel y conserva selecciones locales agregadas durante la espera', () async {
    await iniciarSesionPrueba(scope);
    await carrito.agregar(canva);
    await carrito.agregar(demo);
    final gate = Completer<void>();
    server.antes = (metodo) async {
      if (metodo == 'DELETE_CART') await gate.future;
    };
    final pending = carrito.vaciar();
    await Future<void>.delayed(Duration.zero);
    expect(estado().remotos.single.cantidad, 1);
    expect(estado().locales.single.cantidad, 1);
    await carrito.agregar(demo);
    gate.complete();
    expect(await pending, isTrue);
    expect(estado().remotos, isEmpty);
    expect(estado().locales.single.cantidad, 1);
  });

  test('Una respuesta 401 tardía no cierra una cuenta nueva', () async {
    await iniciarSesionPrueba(scope);
    final gate = Completer<void>();
    server.antes = (metodo) async {
      if (metodo == 'PUT') {
        await gate.future;
        throw const ErrorCarrito('Caducada', estadoHttp: 401);
      }
    };
    final pending = carrito.agregar(canva);
    await Future<void>.delayed(Duration.zero);
    await scope.read(authProvider.notifier).cerrarSesion();
    auth.usuario = const UsuarioAutenticado(
      id: 2,
      nombre: 'Otra',
      correo: 'otra@example.test',
    );
    await iniciarSesionPrueba(scope);
    gate.complete();
    expect(await pending, isFalse);
    expect(scope.read(authProvider).usuario!.id, 2);
    expect(estado().usuarioId, 2);
  });

  test(
    'UUID remoto ajeno al catálogo se conserva como línea eliminable',
    () async {
      const id = '00000000-0000-4000-8000-000000000001';
      server.sembrar(
        token,
        CarritoApiDto(2, [
          const LineaCarritoApi(id, 'Producto posterior', 1, null),
        ]),
      );
      await iniciarSesionPrueba(scope);
      expect(estado().remotos.single.producto.id, id);
      expect(estado().remotos.single.producto.nombre, 'Producto posterior');
      expect(await carrito.quitar(id), isTrue);
    },
  );
}
