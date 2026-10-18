import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prototipo_app/core/app_theme.dart';
import 'package:prototipo_app/widgets/cabecera_tienda.dart';

import 'support/auth_test_repository.dart';

void main() {
  testWidgets(
    'Saldo remoto se comparte entre cabecera y billetera sin autorrecarga',
    (tester) async {
      final wallet = WalletTestRepository();
      final container = ProviderContainer(
        overrides: [
          walletRepositoryProvider.overrideWithValue(wallet),
          cartRepositoryProvider.overrideWithValue(CartTestRepository()),
          authRepositoryProvider.overrideWithValue(AuthTestRepository()),
        ],
      );
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.runAsync(() async {
        await iniciarSesionPrueba(container);
        await container.read(walletProvider(1).future);
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
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
      expect(find.text('Saldo de demostración'), findsWidgets);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Yape'), findsNothing);
      expect(find.text('Administrar créditos ficticios'), findsNothing);
      wallet.saldos[1] = 2000;
      await tester.tap(find.text('Actualizar billetera'));
      await tester.pumpAndSettle();
      expect(find.text('S/ 20.00'), findsWidgets);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('S/ 20.00'), findsOneWidget);
      expect(wallet.intentos, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
