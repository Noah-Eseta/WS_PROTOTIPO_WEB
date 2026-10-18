import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'support/carrito_test_scope.dart';

import 'package:prototipo_app/core/app_theme.dart';
import 'package:prototipo_app/screens/saldo_screen.dart';

import 'support/auth_test_repository.dart';

import 'package:prototipo_app/widgets/cabecera_tienda.dart';

void main() {
  late ProviderContainer container;
  setUp(
    () => container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(AuthTestRepository()),
      ],
    ),
  );
  tearDown(() => container.dispose());

  testWidgets('El saldo se ve en móvil y se actualiza después de recargar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.runAsync(() => iniciarSesionPrueba(container));
    await tester.pumpWidget(
      conCarritoScope(
        container,
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
