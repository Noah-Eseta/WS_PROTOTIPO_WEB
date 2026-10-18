import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/core/app_theme.dart';
import 'package:prototipo_app/core/http/error_billetera.dart';
import 'package:prototipo_app/models/billetera.dart';
import 'package:prototipo_app/models/usuario_autenticado.dart';
import 'package:prototipo_app/providers/admin_wallet_provider.dart';
import 'package:prototipo_app/screens/saldo_screen.dart';
import 'package:prototipo_app/screens/admin_billetera_screen.dart';
import 'package:prototipo_app/screens/login_screen.dart';
import 'package:prototipo_app/screens/pago_screen.dart';
import 'package:prototipo_app/services/producto_service.dart';
import 'package:prototipo_app/providers/carrito_provider.dart';
import 'package:prototipo_app/widgets/perfil_billetera.dart';

import 'support/auth_test_repository.dart';

void main() {
  late ProviderContainer c;
  late WalletTestRepository wallet;
  late AuthTestRepository auth;
  setUp(() {
    wallet = WalletTestRepository();
    auth = AuthTestRepository();
    c = ProviderContainer(
      overrides: [
        walletRepositoryProvider.overrideWithValue(wallet),
        authRepositoryProvider.overrideWithValue(auth),
        cartRepositoryProvider.overrideWithValue(CartTestRepository()),
      ],
    );
  });
  tearDown(() => c.dispose());
  Future<void> montar(
    WidgetTester tester,
    Widget pantalla, {
    bool admin = false,
    double ancho = 390,
    bool login = true,
  }) async {
    tester.view.physicalSize = Size(ancho, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    wallet.admin = admin;
    if (login) await tester.runAsync(() => iniciarSesionPrueba(c));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(theme: AppTheme.tema, home: pantalla),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pulsar(WidgetTester tester, String texto) async {
    final boton = find.text(texto).last;
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();
  }

  for (final ancho in [360.0, 390.0, 600.0, 768.0, 1024.0, 1440.0]) {
    testWidgets('Saldo e historial responsive $ancho', (tester) async {
      wallet.saldos[1] = 100000000;
      wallet.paginas[null] = PaginaBilletera([movimientoPrueba()], 'mas');
      wallet.paginas['mas'] = PaginaBilletera([
        movimientoPrueba(version: 2),
      ], null);
      await montar(tester, const SaldoScreen(), ancho: ancho);
      expect(find.text('S/ 1000000.00'), findsOneWidget);
      final tarjeta = find.byKey(const ValueKey('wallet-card'));
      expect(tester.getSize(tarjeta).height, 210);
      expect(tester.getSize(tarjeta).width, (ancho < 720 ? ancho : 720) - 40);
      expect(tester.takeException(), isNull);
      await pulsar(tester, 'Cargar más movimientos');
      expect(
        find.text('2 movimiento(s) cargado(s). No es un total histórico.'),
        findsOneWidget,
      );
      expect(wallet.cursores, [null, 'mas']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.tema,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: PerfilSaldo(
                saldo: 1000000,
                recargas: [movimientoPrueba()],
                mostrarHistorial: false,
                onAgregarSaldo: () {},
                onTransacciones: () {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('Importe cargado'), findsOneWidget);
      expect(find.text('No es el total histórico'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    testWidgets('Administración y formulario responsive $ancho', (
      tester,
    ) async {
      await montar(
        tester,
        const AdminBilleteraScreen(),
        admin: true,
        ancho: ancho,
      );
      expect(find.text('Persona de prueba'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await pulsar(tester, 'Consultar billetera');
      await tester.ensureVisible(find.byKey(const ValueKey('credito-enviar')));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(wallet.intentos, isEmpty);
    });
  }
  testWidgets('Invitado no accede a billetera ni administración', (
    tester,
  ) async {
    await montar(tester, const AdminBilleteraScreen(), login: false);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(wallet.comprobaciones, 0);
  });
  testWidgets('403 oculta administración incluso con ID 1', (tester) async {
    await montar(tester, const AdminBilleteraScreen());
    expect(
      find.text('No tienes permiso para administrar billeteras.'),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsNothing);
    expect(c.read(authProvider).iniciada, isTrue);
  });
  testWidgets(
    'Confirmar pago simulado conserva saldo e historial de PostgreSQL',
    (tester) async {
      wallet.saldos[1] = 5000;
      wallet.paginas[null] = PaginaBilletera([
        movimientoPrueba(centimos: 5000),
      ], null);
      await tester.runAsync(() async {
        await iniciarSesionPrueba(c);
        final producto = (await ProductoService().obtenerProductos())
            .firstWhere((p) => p.nombre == 'CANVA PRO');
        await c.read(carritoProvider.notifier).agregar(producto);
        await c.read(walletProvider(1).future);
        await c.read(movimientosWalletProvider(1).future);
      });
      final saldoAnterior = c.read(walletProvider(1)).requireValue;
      final movimientos = c.read(movimientosWalletProvider(1)).requireValue;
      // La sesión ya está iniciada: montar directamente mantiene el mismo carrito.
      await montar(tester, const PagoScreen(), login: false);
      await pulsar(tester, 'Yape');
      await pulsar(tester, 'Confirmar pedido');
      expect(find.text('¡Simulación registrada!'), findsOneWidget);
      expect(wallet.intentos, isEmpty);
      expect(c.read(walletProvider(1)).requireValue, same(saldoAnterior));
      expect(
        c.read(movimientosWalletProvider(1)).requireValue,
        same(movimientos),
      );
      expect(wallet.saldos[1], 5000);
      expect(c.read(carritoProvider).remotos.single.cantidad, 1);
    },
  );
  testWidgets('Error de saldo muestra reintento sin fabricar cero', (
    tester,
  ) async {
    wallet.errorConsulta = ErrorBilletera('Sin conexión de billetera.');
    await montar(tester, const SaldoScreen());
    expect(find.text('Sin conexión de billetera.'), findsOneWidget);
    expect(find.text('S/ 0.00'), findsNothing);
    wallet.errorConsulta = null;
    wallet.saldos[1] = 456;
    await pulsar(tester, 'Reintentar');
    expect(find.text('S/ 4.56'), findsOneWidget);
  });
  testWidgets(
    'Formulario valida y reintenta UUID estable tras respuesta perdida',
    (tester) async {
      wallet.falloDespuesDeAplicar = true;
      await montar(tester, const AdminBilleteraScreen(), admin: true);
      await pulsar(tester, 'Consultar billetera');
      await pulsar(tester, 'Asignar crédito ficticio');
      expect(wallet.intentos, isEmpty);
      await tester.enterText(
        find.byKey(const ValueKey('credito-importe')),
        '20,01',
      );
      await tester.enterText(
        find.byKey(const ValueKey('credito-motivo')),
        'Demostración supervisada',
      );
      await pulsar(tester, 'Asignar crédito ficticio');
      expect(c.read(creditoWalletProvider).incierto, isTrue);
      final id = wallet.intentos.single.operacion;
      await pulsar(tester, 'Reintentar la misma operación');
      expect(wallet.recibos, hasLength(1));
      expect(wallet.saldos[1], 2001);
      expect(wallet.intentos.map((i) => i.operacion), [id, id]);
      expect(
        find.text(
          'Se recuperó el comprobante original; no se creó otro crédito.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Cambio de cuenta limpia formulario y destinatario anterior', (
    tester,
  ) async {
    await montar(tester, const AdminBilleteraScreen(), admin: true);
    await pulsar(tester, 'Consultar billetera');
    await tester.enterText(
      find.byKey(const ValueKey('credito-motivo')),
      'Justificación privada anterior',
    );
    auth.usuario = const UsuarioAutenticado(
      id: 2,
      nombre: 'Otra cuenta',
      correo: 'otra@example.test',
    );
    wallet.admin = false;
    await tester.runAsync(() => c.read(authProvider.notifier).cerrarSesion());
    await tester.runAsync(() => iniciarSesionPrueba(c));
    await tester.pumpAndSettle();
    expect(find.text('Justificación privada anterior'), findsNothing);
    expect(find.byKey(const ValueKey('credito-motivo')), findsNothing);
    expect(find.text('Persona de prueba'), findsNothing);
    expect(wallet.intentos, isEmpty);
  });
  testWidgets('403 durante crédito retira datos administrativos sin logout', (
    tester,
  ) async {
    await montar(tester, const AdminBilleteraScreen(), admin: true);
    await pulsar(tester, 'Consultar billetera');
    await tester.enterText(find.byKey(const ValueKey('credito-importe')), '1');
    await tester.enterText(
      find.byKey(const ValueKey('credito-motivo')),
      'Prueba de permiso revocado',
    );
    wallet.errorCredito = ErrorBilletera('Sin permiso.', estadoHttp: 403);
    await pulsar(tester, 'Asignar crédito ficticio');
    expect(find.byKey(const ValueKey('credito-motivo')), findsNothing);
    expect(c.read(authProvider).iniciada, isTrue);
  });
  testWidgets('No actualiza saldo optimista mientras espera confirmación', (
    tester,
  ) async {
    await montar(tester, const AdminBilleteraScreen(), admin: true);
    await pulsar(tester, 'Consultar billetera');
    await tester.enterText(find.byKey(const ValueKey('credito-importe')), '20');
    await tester.enterText(
      find.byKey(const ValueKey('credito-motivo')),
      'Presentación de demostración',
    );
    wallet.creditoPendiente = Completer<ReciboCredito>();
    final boton = find.byKey(const ValueKey('credito-enviar'));
    await tester.ensureVisible(boton);
    await tester.tap(boton);
    await tester.pump();
    expect((await c.read(walletProvider(1).future))!.centimos, 0);
    expect(tester.widget<FilledButton>(boton).onPressed, isNull);
    final intento = wallet.intentos.single;
    wallet.creditoPendiente!.complete(
      ReciboCredito(
        operacion: intento.operacion,
        repetido: false,
        movimiento: movimientoPrueba(operacion: intento.operacion),
      ),
    );
    await tester.pumpAndSettle();
    expect(wallet.intentos, hasLength(1));
  });
}
