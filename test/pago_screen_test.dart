import 'support/auth_test_repository.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'support/carrito_test_scope.dart';

import 'package:prototipo_app/core/app_theme.dart';
import 'package:prototipo_app/models/producto.dart';
import 'package:prototipo_app/screens/pago_screen.dart';
import 'package:prototipo_app/providers/carrito_provider.dart';
import 'package:prototipo_app/services/pedido_service.dart';

void main() {
  late ProviderContainer container;
  setUp(() async {
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(AuthTestRepository()),
      ],
    );
    await iniciarSesionPrueba(container);
  });
  tearDown(() => container.dispose());

  const producto = Producto(
    nombre: 'Producto de prueba',
    subtitulo: 'Digital',
    categoria: 'Software',
    colores: [Colors.blue],
    entrega: 'Automática',
    precio: 6,
    logo: '',
    banner: '',
  );

  testWidgets('El pago permite elegir método y cabe en móvil y escritorio', (
    tester,
  ) async {
    final carrito = container.read(carritoProvider.notifier);
    carrito.vaciar();
    carrito.agregar(producto);
    addTearDown(carrito.vaciar);

    for (final ancho in [320.0, 360.0, 1200.0]) {
      tester.view.physicalSize = Size(ancho, 800);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        conCarritoScope(
          container,
          MaterialApp(theme: AppTheme.tema, home: const PagoScreen()),
        ),
      );
      expect(find.text('Métodos de pago'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final yape = find.text('Yape');
      await tester.ensureVisible(yape);
      await tester.tap(yape);
      await tester.pumpAndSettle();
      final confirmar = find.ancestor(
        of: find.text('Confirmar pedido'),
        matching: find.byType(FilledButton),
      );
      expect(tester.widget<FilledButton>(confirmar).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('La confirmación muestra los datos del pedido en móvil', (
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
          home: ConfirmacionPedidoScreen(
            pedido: PedidoDemo(
              numero: 1,
              fecha: DateTime(2026, 10, 17),
              metodoPago: 'Yape',
              productos: const ['Producto de prueba x1'],
              total: 6,
            ),
          ),
        ),
      ),
    );
    expect(find.text('¡Gracias por tu pedido!'), findsOneWidget);
    expect(find.text('Yape'), findsOneWidget);
    expect(find.text('S/ 6.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
