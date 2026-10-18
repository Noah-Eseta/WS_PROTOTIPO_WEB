import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/core/app_theme.dart';
import 'package:prototipo_app/core/http/error_carrito.dart';
import 'package:prototipo_app/models/producto.dart';
import 'package:prototipo_app/providers/carrito_provider.dart';
import 'package:prototipo_app/screens/carrito_screen.dart';
import 'package:prototipo_app/screens/home_screen.dart';
import 'package:prototipo_app/screens/pago_screen.dart';
import 'package:prototipo_app/services/pedido_service.dart';
import 'package:prototipo_app/services/producto_service.dart';
import 'package:prototipo_app/widgets/cabecera_tienda.dart';
import 'package:prototipo_app/widgets/carrito/estado_sincronizacion_carrito.dart';

import 'support/auth_test_repository.dart';

void main() {
  late ProviderContainer scope;
  late CartTestRepository server;
  late CarritoNotifier cart;
  late Producto canva;
  const demo = Producto(
    nombre: 'Paquete especial · ID 123',
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
    server = CartTestRepository();
    scope = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(AuthTestRepository()),
        cartRepositoryProvider.overrideWithValue(server),
      ],
    );
    cart = scope.read(carritoProvider.notifier);
    canva = (await ProductoService().obtenerProductos()).firstWhere(
      (p) => p.nombre == 'CANVA PRO',
    );
  });
  tearDown(() => scope.dispose());

  Future<void> mount(WidgetTester tester, Widget home, double width) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scope,
        child: MaterialApp(theme: AppTheme.tema, home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in [360.0, 390.0, 600.0, 768.0, 1024.0, 1440.0]) {
    testWidgets(
      'Estado de cuenta, mezcla, error y pago se adaptan a $width px',
      (tester) async {
        await tester.runAsync(() => iniciarSesionPrueba(scope));
        await cart.agregar(canva);
        await cart.agregar(demo);
        server.errorMutacion = const ErrorCarrito(
          'No se pudo conectar. Tus productos se conservan.',
        );
        await cart.agregar(canva);
        await mount(
          tester,
          const Scaffold(body: EstadoSincronizacionCarrito()),
          width,
        );
        expect(find.text('Reintentar sincronización'), findsOneWidget);
        expect(find.textContaining('Cuenta: S/ 7.90'), findsOneWidget);
        expect(tester.takeException(), isNull);
        server.errorMutacion = null;
        await tester.tap(find.text('Reintentar sincronización'));
        await tester.pumpAndSettle();
        expect(scope.read(carritoProvider).necesitaConsulta, isFalse);
        expect(scope.read(carritoProvider).remotos.single.cantidad, 1);
        await mount(tester, const PagoScreen(), width);
        expect(find.textContaining('Simulación local:'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final tipo in ['persistente', 'mixto', 'local especial']) {
    testWidgets(
      'Confirmar simulación $tipo no envía DELETE y solo consume locales exclusivos',
      (tester) async {
        await tester.runAsync(() => iniciarSesionPrueba(scope));
        if (tipo != 'local especial') await cart.agregar(canva);
        if (tipo != 'persistente') await cart.agregar(demo);
        final remoteBefore = server.estado('credencial-fixture-1');
        await mount(tester, const PagoScreen(), 1024);
        await tester.ensureVisible(find.text('Yape'));
        await tester.tap(find.text('Yape'));
        await tester.pumpAndSettle();
        final count = PedidoService.instancia.pedidos.length;
        final button = find.widgetWithText(FilledButton, 'Confirmar pedido');
        await tester.ensureVisible(button);
        // Dos eventos antes de reconstruir deben registrar una sola demostración.
        final enviar = tester.widget<FilledButton>(button).onPressed!;
        enviar();
        enviar();
        await tester.pumpAndSettle();
        expect(find.byType(ConfirmacionPedidoScreen), findsOneWidget);
        expect(find.text('¡Simulación registrada!'), findsOneWidget);
        expect(PedidoService.instancia.pedidos.length, count + 1);
        final remoteAfter = server.estado('credencial-fixture-1');
        expect(remoteAfter.version, remoteBefore.version);
        expect(
          remoteAfter.items.map((i) => (i.id, i.cantidad, i.precioCentimos)),
          remoteBefore.items.map((i) => (i.id, i.cantidad, i.precioCentimos)),
        );
        expect(
          server.llamadas.where((r) => r.metodo.startsWith('DELETE')),
          isEmpty,
        );
        expect(
          scope.read(carritoProvider).remotos.length,
          tipo == 'local especial' ? 0 : 1,
        );
        expect(
          scope.read(carritoProvider).locales.length,
          tipo == 'mixto' ? 1 : 0,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Eliminar fallido conserva la fila y ofrece actualizar sin repetir DELETE',
    (tester) async {
      await tester.runAsync(() => iniciarSesionPrueba(scope));
      await cart.agregar(canva);
      await mount(tester, const CarritoScreen(), 1024);
      server.errorMutacion = const ErrorCarrito(
        'Sin conexión; consulta antes de reintentar.',
        resultadoIncierto: true,
      );
      await tester.tap(find.byTooltip('Quitar'));
      await tester.pumpAndSettle();
      expect(scope.read(carritoProvider).remotos.single.producto.id, canva.id);
      expect(find.text('CANVA PRO'), findsNWidgets(2));
      expect(
        server.llamadas.where((r) => r.metodo == 'DELETE_ITEM'),
        hasLength(1),
      );
      server.errorMutacion = null;
      await tester.tap(find.text('Actualizar'));
      await tester.pumpAndSettle();
      expect(
        server.llamadas.where((r) => r.metodo == 'DELETE_ITEM'),
        hasLength(1),
      );
      expect(scope.read(carritoProvider).remotos.single.cantidad, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Visitante ve el catálogo y accede a su carrito sin autenticarse',
    (tester) async {
      await cart.agregar(canva);
      await mount(tester, const HomeScreen(), 1024);
      final badge = find.ancestor(
        of: find.byIcon(Icons.shopping_cart_outlined),
        matching: find.byType(Badge),
      );
      expect(
        find.descendant(of: badge, matching: find.text('1')),
        findsOneWidget,
      );
      expect(find.byType(CabeceraTienda), findsOneWidget);
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(CarritoScreen), findsOneWidget);
      expect(find.text('CANVA PRO'), findsNWidgets(2));
      expect(find.text('SELECCIÓN DE VISITANTE'), findsOneWidget);
      expect(scope.read(authProvider).iniciada, isFalse);
      expect(server.llamadas, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
