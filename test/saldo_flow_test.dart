import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/core/app_theme.dart';
import 'package:prototipo_app/screens/saldo_screen.dart';
import 'package:prototipo_app/services/sesion_service.dart';
import 'package:prototipo_app/widgets/cabecera_tienda.dart';

void main() {
  testWidgets('El saldo se ve en móvil y se actualiza después de recargar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
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
            compacto: true,
            margen: 16,
            onLogin: () {},
            onCarrito: () {},
          ),
        ),
      ),
    );

    expect(find.text('S/ 0.00'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('S/ 0.00'));
    await tester.pumpAndSettle();
    expect(find.text('Agregar saldo'), findsWidgets);

    await tester.enterText(find.byType(TextFormField), '20');
    final listaRecarga = find
        .descendant(
          of: find.byType(SaldoScreen).last,
          matching: find.byType(Scrollable),
        )
        .first;
    final metodoYape = find.descendant(
      of: find.byType(SaldoScreen).last,
      matching: find.byWidgetPredicate(
        (widget) => widget is RadioListTile<String> && widget.value == 'Yape',
      ),
    );
    await tester.scrollUntilVisible(metodoYape, 200, scrollable: listaRecarga);
    await tester.ensureVisible(metodoYape);
    await tester.pumpAndSettle();
    await tester.tap(metodoYape);
    final botonRecargar = find.descendant(
      of: find.byType(SaldoScreen).last,
      matching: find.widgetWithText(FilledButton, 'Agregar saldo'),
    );
    await tester.scrollUntilVisible(
      botonRecargar,
      200,
      scrollable: listaRecarga,
    );
    await tester.ensureVisible(botonRecargar);
    await tester.pumpAndSettle();
    await tester.tap(botonRecargar);
    await tester.pumpAndSettle();

    expect(find.text('¡Saldo agregado!'), findsOneWidget);
    expect(find.text('Nuevo saldo: S/ 20.00'), findsOneWidget);
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('S/ 20.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
