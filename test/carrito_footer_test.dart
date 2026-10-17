import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'support/carrito_test_scope.dart';

import 'package:prototipo_app/core/app_theme.dart';
import 'package:prototipo_app/models/producto.dart';
import 'package:prototipo_app/screens/carrito_screen.dart';
import 'package:prototipo_app/providers/carrito_provider.dart';
import 'package:prototipo_app/widgets/pie_tienda.dart';

void main() {
  late ProviderContainer container;
  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  testWidgets(
    'El pie del carrito llega al borde inferior con pocos productos',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      final carrito = container.read(carritoProvider.notifier);
      carrito.vaciar();
      carrito.agregar(
        const Producto(
          nombre: 'MAX PLATINO',
          subtitulo: 'ACCESO COMPARTIDO',
          categoria: 'Streaming',
          colores: [Colors.blue],
          entrega: 'Automática',
          precio: 6,
          logo: 'assets/images/Productos/max/hbomax_logo.webp',
          banner: 'assets/images/Productos/max/hbomax_banner.webp',
        ),
      );
      addTearDown(() {
        carrito.vaciar();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        conCarritoScope(
          container,
          MaterialApp(theme: AppTheme.tema, home: const CarritoScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PieTienda), findsOneWidget);
      expect(tester.getBottomRight(find.byType(PieTienda)).dy, 1000);
      tester.view.physicalSize = const Size(1200, 900);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -150),
      );
      await tester.pumpAndSettle();
      expect(tester.getBottomRight(find.byType(PieTienda)).dy, 900);
      expect(tester.takeException(), isNull);
    },
  );
}
