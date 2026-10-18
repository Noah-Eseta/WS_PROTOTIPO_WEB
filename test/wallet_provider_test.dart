import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/core/http/error_billetera.dart';
import 'package:prototipo_app/models/billetera.dart';
import 'package:prototipo_app/models/usuario_autenticado.dart';
import 'package:prototipo_app/providers/admin_wallet_provider.dart';
import 'package:prototipo_app/providers/carrito_provider.dart';
import 'package:prototipo_app/services/producto_service.dart';

import 'support/auth_test_repository.dart';

void main() {
  late ProviderContainer c;
  late WalletTestRepository wallet;
  late AuthTestRepository auth;
  late CartTestRepository cart;
  setUp(() async {
    wallet = WalletTestRepository();
    auth = AuthTestRepository();
    cart = CartTestRepository();
    c = ProviderContainer(
      overrides: [
        walletRepositoryProvider.overrideWithValue(wallet),
        authRepositoryProvider.overrideWithValue(auth),
        cartRepositoryProvider.overrideWithValue(cart),
      ],
    );
    await iniciarSesionPrueba(c);
  });
  tearDown(() => c.dispose());
  Future<void> admin() async {
    wallet.admin = true;
    expect(await c.read(permisoAdminProvider.future), isTrue);
  }

  test('Genera UUID v4 distintos para intenciones independientes', () {
    final generar = c.read(generarOperacionWalletProvider);
    final ids = List.generate(10, (_) => generar());
    expect(ids.toSet(), hasLength(10));
    expect(
      ids.every(
        (id) => RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(id),
      ),
      isTrue,
    );
  });

  Future<void> acreditar({
    int cantidad = 2000,
    int destinatario = 1,
    String motivo = 'Presentación de demostración',
  }) => c
      .read(creditoWalletProvider.notifier)
      .acreditar(
        destinatario: destinatario,
        centimos: cantidad,
        justificacion: motivo,
      );

  test('Saldo remoto compartido, sin consultas duplicadas', () async {
    wallet.saldos[1] = 12345;
    expect((await c.read(walletProvider(1).future))!.centimos, 12345);
    expect((await c.read(walletProvider(1).future))!.centimos, 12345);
    expect(wallet.consultas, hasLength(1));
  });
  test('Sesiones sucesivas de la misma cuenta no conservan intentos ni permisos anteriores', () async {
    await c.read(authProvider.notifier).cerrarSesion();
    final instante = DateTime.now().toUtc();
    auth.reloj = () => instante;
    await iniciarSesionPrueba(c);
    await admin();
    wallet.falloDespuesDeAplicar = true;
    await acreditar();
    final vencimiento = c.read(authProvider).expiraEn;
    final identidad = c.read(sesionWalletProvider);
    await c.read(authProvider.notifier).cerrarSesion();
    wallet.admin = false;
    await iniciarSesionPrueba(c);
    expect(c.read(authProvider).expiraEn, vencimiento);
    expect(c.read(sesionWalletProvider), isNot(identidad));
    expect(c.read(creditoWalletProvider).intento, isNull);
    expect(await c.read(permisoAdminProvider.future), isFalse);
    expect(wallet.saldos[1], 2000);
  });
  test('Una actualización de /me no borra un crédito pendiente ni duplica consultas', () async {
    await admin();
    wallet.falloDespuesDeAplicar = true;
    await acreditar();
    final pendiente = c.read(creditoWalletProvider).intento;
    await c.read(authProvider.notifier).obtenerPerfil();
    expect(c.read(creditoWalletProvider).intento, same(pendiente));
    expect(wallet.comprobaciones, 1);
  });
  test(
    'Caducidad por reloj limpia todo sin modificar el saldo persistente',
    () async {
      c.dispose();
      var reloj = DateTime.now().toUtc();
      auth.reloj = () => reloj;
      c = ProviderContainer(
        overrides: [
          walletRepositoryProvider.overrideWithValue(wallet),
          authRepositoryProvider.overrideWithValue(auth),
          cartRepositoryProvider.overrideWithValue(cart),
          relojAuthProvider.overrideWithValue(() => reloj),
        ],
      );
      await iniciarSesionPrueba(c);
      await admin();
      wallet.falloDespuesDeAplicar = true;
      await acreditar();
      reloj = reloj.add(const Duration(minutes: 61));
      expect(c.read(authProvider.notifier).verificarVigencia(), isFalse);
      expect(c.read(authProvider).caducada, isTrue);
      expect(c.read(creditoWalletProvider).intento, isNull);
      expect(await c.read(walletProvider(1).future), isNull);
      expect(await c.read(permisoAdminProvider.future), isFalse);
      expect(wallet.saldos[1], 2000);
    },
  );
  test('Paginación administrativa conserva usuarios por ID', () async {
    await admin();
    const saldo = Billetera(id: null, centimos: 0, version: 0);
    const uno = UsuarioBilletera(id: 1, nombre: 'Uno', billetera: saldo);
    const dos = UsuarioBilletera(id: 2, nombre: 'Dos', billetera: saldo);
    wallet.paginasUsuarios[null] = PaginaBilletera([uno], 'mas');
    wallet.paginasUsuarios['mas'] = PaginaBilletera([uno, dos], null);
    await c.read(usuariosAdminProvider.future);
    await c.read(usuariosAdminProvider.notifier).siguiente();
    expect(
      c.read(usuariosAdminProvider).requireValue.elementos.map((u) => u.id),
      [1, 2],
    );
    expect(c.read(usuariosAdminProvider).requireValue.siguiente, isNull);
  });
  test(
    'Crédito a otro usuario consulta su saldo sin modificar el saldo propio',
    () async {
      await admin();
      wallet.saldos[1] = 700;
      await c.read(walletProvider(1).future);
      await acreditar(destinatario: 2);
      expect((await c.read(walletProvider(2).future))!.centimos, 2000);
      expect((await c.read(walletProvider(1).future))!.centimos, 700);
      expect(wallet.consultas.any((q) => q.$2 == 2), isTrue);
    },
  );
  test('Invitado no consulta saldo, historial ni permisos', () async {
    await c.read(authProvider.notifier).cerrarSesion();
    expect(await c.read(walletProvider(1).future), isNull);
    expect(
      (await c.read(movimientosWalletProvider(1).future)).elementos,
      isEmpty,
    );
    expect(await c.read(permisoAdminProvider.future), isFalse);
    expect(wallet.consultas, isEmpty);
    expect(wallet.comprobaciones, 0);
  });
  test(
    'Error remoto no se transforma en saldo cero ni reintenta automáticamente',
    () async {
      wallet.errorConsulta = ErrorBilletera('Sin conexión.');
      await expectLater(c.read(walletProvider(1).future), throwsA(anything));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(datosWallet(c.read(walletProvider(1))), isNull);
      expect(wallet.consultas, hasLength(1));
      wallet.errorConsulta = null;
      wallet.saldos[1] = 500;
      c.invalidate(walletProvider(1));
      expect((await c.read(walletProvider(1).future))!.centimos, 500);
    },
  );
  test('Cursor agrega páginas y deduplica sin inventar totales', () async {
    wallet.paginas[null] = PaginaBilletera([movimientoPrueba()], 'siguiente');
    wallet.paginas['siguiente'] = PaginaBilletera([
      movimientoPrueba(),
      movimientoPrueba(version: 2),
    ], null);
    await c.read(movimientosWalletProvider(1).future);
    await c.read(movimientosWalletProvider(1).notifier).siguiente();
    final pagina = c.read(movimientosWalletProvider(1)).requireValue;
    expect(pagina.elementos, hasLength(2));
    expect(pagina.siguiente, isNull);
    expect(wallet.cursores, [null, 'siguiente']);
    expect(() => pagina.elementos.clear(), throwsUnsupportedError);
  });
  test(
    'Error de página permite repetir el mismo cursor sin perder lo cargado',
    () async {
      wallet.paginas[null] = PaginaBilletera([movimientoPrueba()], 'mas');
      await c.read(movimientosWalletProvider(1).future);
      wallet.errorMovimientos = ErrorBilletera('Sin conexión.');
      await expectLater(
        c.read(movimientosWalletProvider(1).notifier).siguiente(),
        throwsA(anything),
      );
      expect(
        c.read(movimientosWalletProvider(1)).requireValue.elementos,
        hasLength(1),
      );
      wallet.errorMovimientos = null;
      await c.read(movimientosWalletProvider(1).notifier).siguiente();
      expect(wallet.cursores, [null, 'mas', 'mas']);
    },
  );
  test('ID 1 no concede permisos; solo respuesta autorizada', () async {
    expect(await c.read(permisoAdminProvider.future), isFalse);
    await acreditar();
    expect(wallet.intentos, isEmpty);
    wallet.admin = true;
    c.invalidate(permisoAdminProvider);
    expect(await c.read(permisoAdminProvider.future), isTrue);
    expect(wallet.comprobaciones, 2);
  });
  test('Permiso desconocido por red no habilita administración', () async {
    wallet.errorUsuarios = ErrorBilletera('Sin conexión.');
    await expectLater(c.read(permisoAdminProvider.future), throwsA(anything));
    expect(datosWallet(c.read(permisoAdminProvider)), isNull);
    await acreditar();
    expect(wallet.intentos, isEmpty);
  });
  test('403 oculta administración y conserva autenticación', () async {
    await admin();
    wallet.errorCredito = ErrorBilletera('Sin permiso.', estadoHttp: 403);
    await acreditar();
    expect(datosWallet(c.read(permisoAdminProvider)), isFalse);
    expect(c.read(authProvider).iniciada, isTrue);
  });
  for (final status in [401, 409, 422, 429]) {
    test('Crédito HTTP $status no reintenta POST', () async {
      await admin();
      wallet.errorCredito = ErrorBilletera('Error seguro.', estadoHttp: status);
      await acreditar();
      expect(wallet.intentos, hasLength(1));
      if (status == 401) {
        expect(c.read(authProvider).caducada, isTrue);
      } else {
        expect(c.read(creditoWalletProvider).error!.estadoHttp, status);
      }
    });
  }
  test(
    'Timeout después de aplicar: mismo UUID recupera recibo sin duplicar',
    () async {
      await admin();
      wallet.falloDespuesDeAplicar = true;
      await acreditar();
      final pendiente = c.read(creditoWalletProvider).intento!;
      expect(c.read(creditoWalletProvider).incierto, isTrue);
      expect(wallet.saldos[1], 2000);
      c.read(creditoWalletProvider.notifier).nuevaOperacion();
      expect(c.read(creditoWalletProvider).intento, same(pendiente));
      await acreditar();
      expect(wallet.intentos.map((i) => i.operacion).toSet(), {
        pendiente.operacion,
      });
      expect(wallet.recibos, hasLength(1));
      expect(wallet.saldos[1], 2000);
      expect(c.read(creditoWalletProvider).recibo!.repetido, isTrue);
      expect((await c.read(walletProvider(1).future))!.centimos, 2000);
    },
  );
  test('No permite cambiar el contenido de un intento incierto', () async {
    await admin();
    wallet.falloDespuesDeAplicar = true;
    await acreditar();
    final pendiente = c.read(creditoWalletProvider).intento;
    await acreditar(cantidad: 1000);
    expect(wallet.intentos, hasLength(1));
    expect(c.read(creditoWalletProvider).intento, same(pendiente));
  });
  test(
    'Recomprobar permisos no pierde la identidad del crédito incierto',
    () async {
      await admin();
      wallet.falloDespuesDeAplicar = true;
      await acreditar();
      final pendiente = c.read(creditoWalletProvider).intento;
      wallet.errorUsuarios = ErrorBilletera('Sin conexión.');
      c.invalidate(permisoAdminProvider);
      final comprobacion = c.read(permisoAdminProvider.future);
      await acreditar();
      await expectLater(comprobacion, throwsA(anything));
      expect(c.read(creditoWalletProvider).intento, same(pendiente));
      expect(c.read(creditoWalletProvider).incierto, isTrue);
      wallet.errorUsuarios = null;
      c.invalidate(permisoAdminProvider);
      expect(await c.read(permisoAdminProvider.future), isTrue);
      await acreditar();
      expect(wallet.saldos[1], 2000);
      expect(wallet.recibos, hasLength(1));
    },
  );
  test('Evita doble envío mientras hay una respuesta pendiente', () async {
    await admin();
    final pendiente = Completer<ReciboCredito>();
    wallet.creditoPendiente = pendiente;
    final tarea = acreditar();
    await acreditar();
    expect(wallet.intentos, hasLength(1));
    final intento = wallet.intentos.single;
    pendiente.complete(
      ReciboCredito(
        operacion: intento.operacion,
        repetido: false,
        movimiento: movimientoPrueba(operacion: intento.operacion),
      ),
    );
    await tarea;
    await acreditar();
    expect(wallet.intentos, hasLength(1));
  });
  test(
    'Recibo histórico nunca reemplaza saldo actual tras un replay',
    () async {
      await admin();
      wallet.falloDespuesDeAplicar = true;
      await acreditar();
      wallet.saldos[1] = 8500;
      await acreditar();
      expect(
        c.read(creditoWalletProvider).recibo!.movimiento.saldoPosterior,
        2000,
      );
      expect((await c.read(walletProvider(1).future))!.centimos, 8500);
    },
  );
  test('Crédito confirmado con GET fallido no vuelve a enviar POST', () async {
    await admin();
    wallet.errorConsulta = ErrorBilletera('Sin conexión.');
    await acreditar();
    expect(c.read(creditoWalletProvider).recibo, isNotNull);
    expect(c.read(creditoWalletProvider).aviso, isNotNull);
    await acreditar();
    expect(wallet.intentos, hasLength(1));
    wallet.errorConsulta = null;
    c.invalidate(walletProvider(1));
    expect((await c.read(walletProvider(1).future))!.centimos, 2000);
  });
  test('Saldo e historial no muestran valores anteriores durante una actualización', () async {
    wallet.saldos[1] = 2000;
    await c.read(walletProvider(1).future);
    wallet.saldoPendiente = Completer<Billetera>();
    c.invalidate(walletProvider(1));
    expect(datosWallet(c.read(walletProvider(1))), isNull);
    wallet.saldoPendiente!.complete(
      const Billetera(id: uuidWalletPrueba, centimos: 3000, version: 2),
    );
    expect((await c.read(walletProvider(1).future))!.centimos, 3000);
  });
  test(
    'Logout limpia saldo, historial, permisos e intento sin borrar servidor',
    () async {
      await admin();
      wallet.falloDespuesDeAplicar = true;
      await acreditar();
      await c.read(movimientosWalletProvider(1).future);
      await c.read(authProvider.notifier).cerrarSesion();
      expect(await c.read(walletProvider(1).future), isNull);
      expect(
        (await c.read(movimientosWalletProvider(1).future)).elementos,
        isEmpty,
      );
      expect(await c.read(permisoAdminProvider.future), isFalse);
      expect(c.read(creditoWalletProvider).intento, isNull);
      expect(wallet.saldos[1], 2000);
    },
  );
  test(
    'Una respuesta de saldo anterior no restaura datos tras cambiar de cuenta',
    () async {
      final pendiente = Completer<Billetera>();
      wallet.saldoPendiente = pendiente;
      final anterior = c.read(walletProvider(1).future);
      final comprobar = anterior.then(
        (saldo) => saldo?.centimos,
        onError: (_) => null,
      );
      await c.read(authProvider.notifier).cerrarSesion();
      expect(await c.read(walletProvider(1).future), isNull);
      wallet.saldoPendiente = null;
      auth.usuario = const UsuarioAutenticado(
        id: 2,
        nombre: 'Otra persona',
        correo: 'otra@example.test',
      );
      wallet.saldos[2] = 77;
      await iniciarSesionPrueba(c);
      pendiente.complete(
        const Billetera(id: uuidWalletPrueba, centimos: 9999, version: 1),
      );
      expect(await comprobar, isNot(9999));
      expect((await c.read(walletProvider(2).future))!.centimos, 77);
      expect(c.read(authProvider).usuario!.id, 2);
    },
  );
  test(
    'Crédito tardío no restaura formulario ni recibo de una sesión cerrada',
    () async {
      await admin();
      final pendiente = Completer<ReciboCredito>();
      wallet.creditoPendiente = pendiente;
      final tarea = acreditar();
      final intento = wallet.intentos.single;
      await c.read(authProvider.notifier).cerrarSesion();
      expect(c.read(creditoWalletProvider).intento, isNull);
      pendiente.complete(
        ReciboCredito(
          operacion: intento.operacion,
          repetido: false,
          movimiento: movimientoPrueba(operacion: intento.operacion),
        ),
      );
      await tarea;
      expect(c.read(creditoWalletProvider).recibo, isNull);
      expect(c.read(creditoWalletProvider).error, isNull);
    },
  );
  test(
    'Caducidad limpia billetera y un 401 de lectura cierra la sesión',
    () async {
      wallet.errorConsulta = ErrorBilletera(
        'Sesión caducada.',
        estadoHttp: 401,
      );
      final suscripcion = c.listen(walletProvider(1), (_, _) {});
      addTearDown(suscripcion.close);
      await expectLater(c.read(walletProvider(1).future), throwsA(anything));
      expect(c.read(authProvider).caducada, isTrue);
      await c.pump();
      expect(await c.read(walletProvider(1).future), isNull);
    },
  );
  test('Créditos, consultas y logout conservan productos y cantidades del carrito remoto', () async {
    final productos = await ProductoService().obtenerProductos();
    final producto = productos.firstWhere((p) => p.nombre == 'CANVA PRO');
    final carrito = c.read(carritoProvider.notifier);
    await carrito.agregar(producto);
    await carrito.agregar(producto);
    final antes = cart.estado('credencial-fixture-1');
    final llamadas = cart.llamadas.length;
    await admin();
    await acreditar();
    expect(c.read(carritoProvider).items.single.cantidad, 2);
    expect(cart.llamadas.length, llamadas);
    await c.read(authProvider.notifier).cerrarSesion();
    expect(cart.estado('credencial-fixture-1'), same(antes));
  });
}
