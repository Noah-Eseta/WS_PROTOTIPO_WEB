import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prototipo_app/core/http/error_autenticacion.dart';
import 'package:prototipo_app/models/dto/autenticacion_api_dto.dart';
import 'package:prototipo_app/models/usuario_autenticado.dart';
import 'package:prototipo_app/providers/carrito_provider.dart';
import 'package:prototipo_app/services/producto_service.dart';
import 'package:prototipo_app/services/pedido_service.dart';
import 'package:prototipo_app/services/saldo_service.dart';

import 'support/auth_test_repository.dart';

void main() {
  late ProviderContainer container;
  late AuthTestRepository repo;
  setUp(() {
    repo = AuthTestRepository();
    container = ProviderContainer(
      overrides: [
        cartRepositoryProvider.overrideWithValue(CartTestRepository()),
        authRepositoryProvider.overrideWithValue(repo),
      ],
    );
  });
  tearDown(() => container.dispose());

  test(
    'Registro correcto establece una única sesión y /me actualiza el perfil',
    () async {
      final notifier = container.read(authProvider.notifier);
      expect(
        await notifier.registrar(
          nombre: 'Persona',
          correo: 'p@example.test',
          password: 'entrada-fixture',
          confirmacion: 'entrada-fixture',
        ),
        isTrue,
      );
      expect(repo.registros, 1);
      repo.usuario = const UsuarioAutenticado(
        id: 1,
        nombre: 'Nombre actualizado',
        correo: 'real@example.test',
      );
      expect(await notifier.obtenerPerfil(), isTrue);
      expect(container.read(authProvider).nombre, 'Nombre actualizado');
      expect(container.read(authProvider).correo, 'real@example.test');
      expect(repo.perfiles, 1);
    },
  );

  for (final code in [401, 422, 429]) {
    test('Login y registro incorrectos HTTP $code no crean sesión', () async {
      repo.errorLogin = ErrorAutenticacion('Error seguro', estadoHttp: code);
      expect(await iniciarSesionPrueba(container), isFalse);
      expect(container.read(authProvider).iniciada, isFalse);
      expect(container.read(authProvider).error?.estadoHttp, code);
      expect(
        await container
            .read(authProvider.notifier)
            .registrar(
              nombre: 'Persona',
              correo: 'p@example.test',
              password: 'entrada-fixture',
              confirmacion: 'entrada-fixture',
            ),
        isFalse,
      );
      expect(container.read(authProvider).enProceso, isFalse);
    });
  }
  test('No duplica solicitudes ni restaura una sesión cerrada con respuesta tardía', () async {
    repo.pendiente = Completer<AutenticacionApiDto>();
    final first = iniciarSesionPrueba(container);
    expect(await iniciarSesionPrueba(container), isFalse);
    expect(repo.logins, 1);
    await container.read(authProvider.notifier).cerrarSesion();
    repo.pendiente!.complete(repo.sesion());
    expect(await first, isFalse);
    expect(container.read(authProvider).iniciada, isFalse);
  });
  test('La respuesta tardía de /me no restaura la sesión', () async {
    await iniciarSesionPrueba(container);
    repo.perfilPendiente = Completer<UsuarioAutenticado>();
    final pending = container.read(authProvider.notifier).obtenerPerfil();
    await container.read(authProvider.notifier).cerrarSesion();
    repo.perfilPendiente!.complete(repo.usuario);
    expect(await pending, isFalse);
    expect(container.read(authProvider).iniciada, isFalse);
  });
  test(
    '401 en /me limpia sesión; pérdida de conexión permite reintentar',
    () async {
      await iniciarSesionPrueba(container);
      repo.errorPerfil = ErrorAutenticacion('Sin conexión');
      expect(
        await container.read(authProvider.notifier).obtenerPerfil(),
        isFalse,
      );
      expect(container.read(authProvider).iniciada, isTrue);
      repo.errorPerfil = null;
      expect(
        await container.read(authProvider.notifier).obtenerPerfil(),
        isTrue,
      );
      repo.errorPerfil = ErrorAutenticacion('No autenticado', estadoHttp: 401);
      expect(
        await container.read(authProvider.notifier).obtenerPerfil(),
        isFalse,
      );
      expect(container.read(authProvider).caducada, isTrue);
    },
  );
  test(
    'Logout revoca, oculta el carrito remoto y limpia datos financieros demo',
    () async {
      final productos = await ProductoService().obtenerProductos();
      final carrito = container.read(carritoProvider.notifier);
      await carrito.agregar(productos.firstWhere((p) => p.disponible));
      await carrito.agregar(productos.firstWhere((p) => p.disponible));
      final snapshot = container.read(carritoProvider);
      await iniciarSesionPrueba(container);
      expect(
        container.read(carritoProvider).cantidadTotal,
        snapshot.cantidadTotal,
      );
      PedidoService.instancia.registrar(
        snapshot,
        'Yape',
        sesionIniciada: true,
        vaciarCarrito: () {},
      );
      SaldoService.instancia.recargar(centimos: 1200, metodoPago: 'Yape');
      await container.read(authProvider.notifier).cerrarSesion();
      expect(repo.salidas, 1);
      expect(container.read(authProvider).iniciada, isFalse);
      expect(container.read(carritoProvider).remotos, isEmpty);
      expect(snapshot.cantidadTotal, 2);
      expect(SaldoService.instancia.centimos, 0);
      expect(PedidoService.instancia.pedidos, isEmpty);
      repo.usuario = const UsuarioAutenticado(
        id: 2,
        nombre: 'Otra persona',
        correo: 'otra@example.test',
      );
      await iniciarSesionPrueba(container);
      expect(container.read(authProvider).usuario!.id, 2);
      expect(container.read(carritoProvider).remotos, isEmpty);
      expect(PedidoService.instancia.pedidos, isEmpty);
    },
  );
  test(
    'Logout sin conexión borra la sesión e informa de revocación pendiente',
    () async {
      await iniciarSesionPrueba(container);
      repo.errorLogout = ErrorAutenticacion('Sin conexión');
      await container.read(authProvider.notifier).cerrarSesion();
      expect(container.read(authProvider).iniciada, isFalse);
      expect(
        container.read(authProvider).error!.mensaje,
        contains('revocación'),
      );
    },
  );
  test(
    'Expiración oculta la vista privada sin modificar la instantánea',
    () async {
      var now = DateTime.utc(2026);
      container.dispose();
      repo.reloj = () => now;
      container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(CartTestRepository()),
          authRepositoryProvider.overrideWithValue(repo),
          relojAuthProvider.overrideWithValue(() => now),
        ],
      );
      await iniciarSesionPrueba(container);
      final products = await ProductoService().obtenerProductos();
      final carrito = container.read(carritoProvider.notifier);
      await carrito.agregar(products.firstWhere((p) => p.disponible));
      await carrito.agregar(products.firstWhere((p) => p.disponible));
      final snapshot = container.read(carritoProvider);
      expect(snapshot.cantidadTotal, 2);
      now = now.add(const Duration(minutes: 61));
      expect(
        container.read(authProvider.notifier).verificarVigencia(),
        isFalse,
      );
      expect(container.read(authProvider).caducada, isTrue);
      expect(container.read(carritoProvider).remotos, isEmpty);
      expect(snapshot.cantidadTotal, 2);
    },
  );
  testWidgets('El temporizador caduca la sesión aunque no haya navegación', (
    tester,
  ) async {
    repo.vigencia = const Duration(seconds: 2);
    await iniciarSesionPrueba(container);
    expect(container.read(authProvider).iniciada, isTrue);
    await tester.pump(const Duration(seconds: 3));
    expect(container.read(authProvider).caducada, isTrue);
  });

  test('Una respuesta de login ya caducada no autentica', () async {
    repo.vigencia = const Duration(minutes: -1);
    expect(await iniciarSesionPrueba(container), isFalse);
    expect(container.read(authProvider).caducada, isTrue);
  });
  test('Un perfil con ID diferente cierra la sesión por seguridad', () async {
    await iniciarSesionPrueba(container);
    repo.usuario = const UsuarioAutenticado(
      id: 99,
      nombre: 'Otra cuenta',
      correo: 'otra@example.test',
    );
    expect(
      await container.read(authProvider.notifier).obtenerPerfil(),
      isFalse,
    );
    expect(container.read(authProvider).iniciada, isFalse);
  });
  test(
    'Descartar el scope ignora un login pendiente y no crea otra sesión',
    () async {
      repo.pendiente = Completer<AutenticacionApiDto>();
      final pending = iniciarSesionPrueba(container);
      container.dispose();
      container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(CartTestRepository()),
          authRepositoryProvider.overrideWithValue(repo),
        ],
      );
      repo.pendiente!.complete(repo.sesion());
      expect(await pending, isFalse);
      expect(container.read(authProvider).iniciada, isFalse);
    },
  );
}
