import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/core/app_theme.dart';
import 'package:prototipo_app/screens/home_screen.dart';
import 'package:prototipo_app/widgets/banner_bienvenida.dart';
import 'package:prototipo_app/widgets/tarjeta_interactiva.dart';
import 'package:prototipo_app/widgets/tarjeta_producto.dart';

void main() {
  testWidgets('Las ofertas se alinean con la portada en escritorio', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.tema, home: const HomeScreen()),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final portada = tester.getRect(find.byType(BannerBienvenida));
    final primera = tester.getRect(
      find
          .ancestor(
            of: find.text('CANVA PRO').first,
            matching: find.byType(TarjetaInteractiva),
          )
          .first,
    );
    final ultima = tester.getRect(
      find
          .ancestor(
            of: find.text('PARAMOUNT+').first,
            matching: find.byType(TarjetaInteractiva),
          )
          .first,
    );

    expect(primera.left, closeTo(portada.left, 1));
    expect(ultima.right, lessThanOrEqualTo(1440 - portada.left + 1));

    final scrollVertical = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('YOUTUBE PREMIUM'),
      400,
      scrollable: scrollVertical,
    );
    await tester.pump();
    final primeraStreaming = tester.getRect(
      find
          .ancestor(
            of: find.text('YOUTUBE PREMIUM'),
            matching: find.byType(TarjetaProducto),
          )
          .first,
    );
    final ultimaStreaming = tester.getRect(
      find
          .ancestor(
            of: find.text('PARAMOUNT+'),
            matching: find.byType(TarjetaProducto),
          )
          .first,
    );
    expect(primeraStreaming.left, closeTo(portada.left, 1));
    expect(ultimaStreaming.right, lessThanOrEqualTo(1440 - portada.left + 1));
  });
}
