import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'support/carrito_test_scope.dart';

import 'package:prototipo_app/core/app_theme.dart';
import 'package:prototipo_app/models/producto.dart';
import 'package:prototipo_app/screens/detalle/detalle_producto.dart';
import 'package:prototipo_app/screens/detalle/detalle_redes_screen.dart';
import 'package:prototipo_app/providers/carrito_provider.dart';
import 'package:prototipo_app/services/sesion_service.dart';

void main() {
  late ProviderContainer container;
  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  const tiktok = Producto(
    nombre: 'TIKTOK',
    subtitulo: 'SEGUIDORES, LIKES Y VISUALIZACIONES',
    categoria: 'Redes',
    colores: [Colors.black],
    entrega: 'Automática',
    precio: 5.90,
    logo: 'assets/images/Productos/tiktok/tiktok_logo.webp',
    banner: 'assets/images/Productos/tiktok/tiktok_banner.webp',
  );

  testWidgets('Redes abre detalle y guarda servicio, cantidad y enlace', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    final carrito = container.read(carritoProvider.notifier);
    carrito.vaciar();
    SesionService.instancia.iniciarSesion('Prueba@email.com', 'prueba_123');
    addTearDown(() {
      carrito.vaciar();
      SesionService.instancia.cerrarSesion();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    expect(detalleParaProducto(tiktok), isA<DetalleRedesScreen>());
    await tester.pumpWidget(
      conCarritoScope(
        container,
        MaterialApp(
          theme: AppTheme.tema,
          home: const DetalleRedesScreen(producto: tiktok),
        ),
      ),
    );
    expect(tester.takeException(), isNull);

    final servicio = find.text('Seguidores · gradual');
    await tester.ensureVisible(servicio);
    await tester.tap(servicio);
    await tester.pumpAndSettle();
    final aumentar = find.byTooltip('Aumentar cantidad');
    await tester.ensureVisible(aumentar);
    await tester.tap(aumentar);
    await tester.pump();
    expect(find.text('1100'), findsOneWidget);
    expect(find.text('S/ 4.27'), findsOneWidget);

    final enlace = find.byType(TextField).last;
    await tester.ensureVisible(enlace);
    await tester.enterText(enlace, 'https://www.tiktok.com/@prueba');
    await tester.pump();
    final agregar = find.byIcon(Icons.add_shopping_cart_outlined);
    await tester.ensureVisible(agregar);
    await tester.tap(agregar);
    await tester.pump();

    expect(
      container.read(carritoProvider).items.single.producto.nombre,
      contains('Seguidores · gradual'),
    );
    expect(
      container.read(carritoProvider).items.single.producto.nombre,
      contains('1100'),
    );
    expect(
      container.read(carritoProvider).items.single.producto.nombre,
      contains('tiktok.com/@prueba'),
    );
    expect(
      container.read(carritoProvider).items.single.producto.precio,
      closeTo(4.268, .001),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('El detalle cabe en móvil y escritorio', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    for (final ancho in [320.0, 950.0, 1200.0]) {
      tester.view.physicalSize = Size(ancho, 900);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        conCarritoScope(
          container,
          MaterialApp(
            theme: AppTheme.tema,
            home: const DetalleRedesScreen(producto: tiktok),
          ),
        ),
      );
      expect(find.text('Resumen de compra'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
