import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/core/app_theme.dart';
import 'package:prototipo_app/services/sesion_service.dart';
import 'package:prototipo_app/widgets/cabecera_tienda.dart';
import 'package:prototipo_app/widgets/ventana_notificaciones.dart';

void main() {
  testWidgets('La ventana de notificaciones hereda el estilo de la tienda', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      SesionService.instancia.cerrarSesion();
    });
    SesionService.instancia.iniciarSesion('Prueba@email.com', 'prueba_123');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.tema,
        home: Scaffold(
          body: CabeceraTienda(
            compacto: false,
            margen: 16,
            onLogin: () {},
            onCarrito: () {},
          ),
        ),
      ),
    );

    for (var intento = 0; intento < 3; intento++) {
      await tester.tap(find.byIcon(Icons.notifications_none));
      await tester.pumpAndSettle();

      final mensaje = find.text('No tienes notificaciones');
      expect(mensaje, findsOneWidget);
      final estilo = DefaultTextStyle.of(tester.element(mensaje)).style;
      expect(estilo.fontSize, lessThanOrEqualTo(16));
      expect(estilo.decoration, isNot(TextDecoration.underline));

      final ventana = tester.getRect(find.byType(VentanaNotificaciones));
      expect(ventana.left, greaterThanOrEqualTo(0));
      expect(ventana.right, lessThanOrEqualTo(900));
      expect(ventana.bottom, lessThanOrEqualTo(700));
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(VentanaNotificaciones), findsNothing);
    }

    await tester.tap(find.byIcon(Icons.notifications_none));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'En móvil la cabecera oculta saldo, notificaciones y carrito sin sesión',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      SesionService.instancia.cerrarSesion();
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        SesionService.instancia.cerrarSesion();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.tema,
          home: Scaffold(
            body: CabeceraTienda(
              compacto: true,
              margen: 16,
              onLogin: () {},
              onCarrito: () {},
            ),
          ),
        ),
      );

      expect(find.text('WEIKANG SHOP'), findsOneWidget);
      expect(find.text('PLATAFORMA DIGITAL'), findsNothing);
      expect(find.byIcon(Icons.account_balance_wallet_outlined), findsNothing);
      final campana = find.ancestor(
        of: find.byIcon(Icons.notifications_none),
        matching: find.byType(IconButton),
      );
      expect(campana, findsNothing);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsNothing);
      expect(tester.takeException(), isNull);

      SesionService.instancia.iniciarSesion('Prueba@email.com', 'prueba_123');
      await tester.pump();
      expect(find.text('S/ 0.00'), findsOneWidget);
      expect(campana, findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
      expect(tester.widget<IconButton>(campana).onPressed, isNotNull);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(find.text('Prueba@email.com'), findsOneWidget);
      expect(find.text('Mi perfil'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tapAt(const Offset(8, 300));
      await tester.pumpAndSettle();

      await tester.tap(campana);
      await tester.pumpAndSettle();
      expect(find.byType(VentanaNotificaciones), findsOneWidget);
      expect(tester.takeException(), isNull);

      SesionService.instancia.cerrarSesion();
      await tester.pump();
      expect(find.byType(VentanaNotificaciones), findsNothing);
      expect(find.text('S/ 0.00'), findsNothing);
      expect(campana, findsNothing);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
