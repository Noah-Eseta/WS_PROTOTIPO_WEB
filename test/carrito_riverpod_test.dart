import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/core/app_theme.dart';
import 'package:prototipo_app/models/estado_carrito.dart';
import 'package:prototipo_app/models/producto.dart';
import 'package:prototipo_app/providers/carrito_provider.dart';
import 'package:prototipo_app/screens/carrito_screen.dart';
import 'package:prototipo_app/screens/pago_screen.dart';
import 'package:prototipo_app/services/pedido_service.dart';

import 'support/auth_test_repository.dart';

import 'package:prototipo_app/widgets/cabecera_tienda.dart';
import 'package:prototipo_app/widgets/pantalla_carga.dart';

import 'support/carrito_test_scope.dart';

const producto = Producto(
  nombre: 'CANVA PRO',
  subtitulo: 'Digital',
  categoria: 'Software',
  colores: [Colors.blue],
  entrega: 'Automática',
  precio: 6,
  logo: 'assets/images/Productos/canva_pro/canva_logo.webp',
  banner: 'assets/images/Productos/canva_pro/canva_banner.webp',
);

void main() {
  late ProviderContainer container;
  late CarritoNotifier carrito;
  EstadoCarrito estado() => container.read(carritoProvider);
  setUp(() async {
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(AuthTestRepository()),
      ],
    );
    carrito = container.read(carritoProvider.notifier);
    await iniciarSesionPrueba(container);
  });
  tearDown(() {
    container.dispose();
  });

  Future<void> montar(
    WidgetTester tester,
    Widget home, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      conCarritoScope(container, MaterialApp(theme: AppTheme.tema, home: home)),
    );
    await tester.pumpAndSettle();
  }

  Widget cabecera() => Scaffold(
    body: Builder(
      builder: (context) => CabeceraTienda(
        compacto: true,
        margen: 16,
        onLogin: () {},
        onCarrito: () =>
            Navigator.of(context)
                .push(RutaConCarga(destino: const CarritoScreen())),
      ),
    ),
  );

  Finder badge() => find.ancestor(
    of: find.byIcon(Icons.shopping_cart_outlined),
    matching: find.byType(Badge),
  );

  testWidgets('La cabecera actualiza su contador desde el único carrito', (
    tester,
  ) async {
    await montar(tester, cabecera());
    expect(tester.widget<Badge>(badge()).isLabelVisible, isFalse);
    carrito.agregar(producto);
    carrito.agregar(producto);
    await tester.pump();
    expect(
      find.descendant(of: badge(), matching: find.text('2')),
      findsOneWidget,
    );
    carrito.cambiarCantidad(producto.nombre, -1);
    await tester.pump();
    expect(
      find.descendant(of: badge(), matching: find.text('1')),
      findsOneWidget,
    );
    carrito.quitar(producto.nombre);
    await tester.pump();
    expect(tester.widget<Badge>(badge()).isLabelVisible, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Navegar, modificar y volver conserva el carrito y el contador', (
    tester,
  ) async {
    carrito.agregar(producto);
    // El flujo de estado se comprueba en escritorio. La cabecera del carrito
    // tiene un overflow móvil previo, registrado aparte en PENDIENTES_UI.md.
    await montar(tester, cabecera(), size: const Size(1024, 900));
    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(CarritoScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Aumentar'));
    await tester.pump();
    expect(estado().cantidadTotal, 2);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: badge(), matching: find.text('2')),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    await tester.pumpAndSettle();
    expect(estado().cantidadTotal, 2);
    await tester.tap(find.byTooltip('Disminuir'));
    await tester.pump();
    expect(estado().cantidadTotal, 1);
    await tester.tap(find.byTooltip('Quitar'));
    await tester.pump();
    expect(estado().vacio, isTrue);
    expect(find.text('No agregaste productos'), findsOneWidget);
    carrito.agregar(producto);
    await tester.pump();
    await tester.tap(find.byTooltip('Vaciar carrito'));
    await tester.pump();
    expect(estado().vacio, isTrue);
    expect(find.text('No agregaste productos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('El pago observa cambios y deshabilita confirmar al vaciar', (
    tester,
  ) async {
    carrito.agregar(producto);
    await montar(tester, const PagoScreen());
    await tester.ensureVisible(find.text('Yape'));
    await tester.tap(find.text('Yape'));
    await tester.pumpAndSettle();
    final confirmar = find.widgetWithText(FilledButton, 'Confirmar pedido');
    expect(tester.widget<FilledButton>(confirmar).onPressed, isNotNull);
    carrito.cambiarCantidad(producto.nombre, 1);
    await tester.pump();
    expect(find.text('S/ 12.00'), findsNWidgets(2));
    carrito.vaciar();
    await tester.pump();
    expect(tester.widget<FilledButton>(confirmar).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Confirmar registra la instantánea y después vacía el carrito', (
    tester,
  ) async {
    carrito.agregar(producto);
    carrito.agregar(producto);
    final snapshot = estado();
    final pedidos = PedidoService.instancia;
    final anteriores = pedidos.pedidos.length;
    bool? vacioAlNotificar;
    void alRegistrar() => vacioAlNotificar = estado().vacio;
    pedidos.addListener(alRegistrar);
    addTearDown(() => pedidos.removeListener(alRegistrar));
    await montar(tester, const PagoScreen());
    await tester.ensureVisible(find.text('Yape'));
    await tester.tap(find.text('Yape'));
    await tester.pumpAndSettle();
    final confirmar = find.widgetWithText(FilledButton, 'Confirmar pedido');
    await tester.ensureVisible(confirmar);
    await tester.tap(confirmar);
    await tester.pumpAndSettle();
    expect(find.byType(ConfirmacionPedidoScreen), findsOneWidget);
    expect(find.text('¡Gracias por tu pedido!'), findsOneWidget);
    expect(pedidos.pedidos.length, anteriores + 1);
    expect(pedidos.pedidos.first.productos, ['CANVA PRO x2']);
    expect(pedidos.pedidos.first.total, 12);
    expect(pedidos.pedidos.first.metodoPago, 'Yape');
    expect(estado().vacio, isTrue);
    expect(vacioAlNotificar, isTrue);
    expect(snapshot.cantidadTotal, 2);
    expect(snapshot.total, 12);
    expect(
      () => pedidos.pedidos.first.productos.clear(),
      throwsUnsupportedError,
    );
    expect(tester.takeException(), isNull);
  });

  test('Registrar sin sesión no guarda ni vacía el carrito', () async {
    carrito.agregar(producto);
    await container.read(authProvider.notifier).cerrarSesion();
    final pedidos = PedidoService.instancia;
    final anteriores = pedidos.pedidos.length;
    var vaciados = 0;
    expect(
      () => pedidos.registrar(
        estado(),
        'Yape',
        sesionIniciada: container.read(authProvider).iniciada,
        vaciarCarrito: () {
          vaciados++;
          carrito.vaciar();
        },
      ),
      throwsStateError,
    );
    expect(vaciados, 0);
    expect(estado().cantidadTotal, 1);
    expect(pedidos.pedidos.length, anteriores);
  });

  test(
    'Registrar un carrito vacío no crea un pedido ni ejecuta el vaciado',
    () {
      final pedidos = PedidoService.instancia;
      final anteriores = pedidos.pedidos.length;
      var vaciados = 0;
      expect(
        () => pedidos.registrar(
          estado(),
          'Yape',
          sesionIniciada: container.read(authProvider).iniciada,
          vaciarCarrito: () => vaciados++,
        ),
        throwsStateError,
      );
      expect(vaciados, 0);
      expect(pedidos.pedidos.length, anteriores);
    },
  );

  test('El pedido ya está almacenado antes de ejecutar el vaciado', () {
    carrito.agregar(producto);
    final snapshot = estado();
    final pedidos = PedidoService.instancia;
    final anteriores = pedidos.pedidos.length;
    final pedido = pedidos.registrar(
      snapshot,
      'Plin',
      sesionIniciada: container.read(authProvider).iniciada,
      vaciarCarrito: () {
        expect(pedidos.pedidos.length, anteriores + 1);
        expect(pedidos.pedidos.first.total, snapshot.total);
        expect(estado().vacio, isFalse);
        carrito.vaciar();
      },
    );
    expect(estado().vacio, isTrue);
    expect(pedido.productos, ['CANVA PRO x1']);
    expect(snapshot.items.single.cantidad, 1);
  });
}
