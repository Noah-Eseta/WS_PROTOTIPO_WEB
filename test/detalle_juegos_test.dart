import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'support/carrito_test_scope.dart';

import 'package:prototipo_app/core/app_theme.dart';
import 'package:prototipo_app/models/producto.dart';
import 'package:prototipo_app/screens/detalle/detalle_juegos_screen.dart';
import 'package:prototipo_app/screens/detalle/detalle_producto.dart';
import 'package:prototipo_app/providers/carrito_provider.dart';
import 'package:prototipo_app/services/sesion_service.dart';

void main() {
  late ProviderContainer container;
  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  const freeFire = Producto(
    nombre: 'FREE FIRE +10%',
    subtitulo: 'DIAMANTES Y PAQUETES',
    categoria: 'Juegos',
    logo: 'assets/images/Productos/free_fire/freefire_logo.webp',
    banner: 'assets/images/Productos/free_fire/freefire_banner.webp',
    colores: [Colors.blue],
    entrega: 'Automática',
    precio: 19.90,
  );
  const mobileLegends = Producto(
    nombre: 'MOBILE LEGENDS',
    subtitulo: 'DIAMANTES Y PASE SEMANAL',
    categoria: 'Juegos',
    logo: 'assets/images/Productos/mobile_legends/mobilelegends_logo.webp',
    banner: 'assets/images/Productos/mobile_legends/mobilelegends_banner.webp',
    colores: [Colors.blue],
    entrega: 'Automática',
    precio: 8.90,
  );

  testWidgets('El juego abre detalle y conserva paquete e ID en el carrito', (
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

    expect(detalleParaProducto(freeFire), isA<DetalleJuegosScreen>());
    await tester.pumpWidget(
      conCarritoScope(
        container,
        MaterialApp(
          theme: AppTheme.tema,
          home: const DetalleJuegosScreen(producto: freeFire),
        ),
      ),
    );
    expect(find.text('DIAMANTES'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final paquete = find.text('310 + 31').first;
    await tester.ensureVisible(paquete);
    await tester.tap(paquete);
    await tester.pumpAndSettle();
    final jugador = find.byType(TextField).first;
    await tester.ensureVisible(jugador);
    await tester.enterText(jugador, '12345');
    await tester.pump();
    final agregar = find.byIcon(Icons.add_shopping_cart_outlined);
    await tester.ensureVisible(agregar);
    await tester.tap(agregar);
    await tester.pump();

    expect(container.read(carritoProvider).items.single.producto.precio, 8);
    expect(
      container.read(carritoProvider).items.single.producto.nombre,
      contains('310 + 31'),
    );
    expect(
      container.read(carritoProvider).items.single.producto.nombre,
      contains('ID 12345'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Otro juego usa su precio del catálogo y cabe en móvil', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      conCarritoScope(
        container,
        MaterialApp(
          theme: AppTheme.tema,
          home: const DetalleJuegosScreen(producto: mobileLegends),
        ),
      ),
    );
    expect(find.text('PAQUETE DISPONIBLE'), findsOneWidget);
    expect(find.text('S/ 8.90'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('El detalle de Free Fire cabe en móvil y escritorio', (
    tester,
  ) async {
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
            home: const DetalleJuegosScreen(producto: freeFire),
          ),
        ),
      );
      expect(find.text('Resumen de compra'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
