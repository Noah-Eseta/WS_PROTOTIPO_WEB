import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'support/carrito_test_scope.dart';

import 'package:prototipo_app/core/app_theme.dart';
import 'package:prototipo_app/models/producto.dart';
import 'package:prototipo_app/screens/detalle/detalle_software_screen.dart';
import 'package:prototipo_app/screens/detalle/detalle_streaming_screen.dart';

void main() {
  late ProviderContainer container;
  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  const software = Producto(
    nombre: 'KASPERSKY PREMIUM + VPN',
    subtitulo: 'ACTIVACIÓN A DOMINIO',
    categoria: 'Software',
    logo: 'assets/images/Productos/kaspersky/kaspersky_logo.webp',
    banner: 'assets/images/Productos/kaspersky/kaspersky_banner.webp',
    colores: [Colors.green],
    entrega: 'Activación',
    tipo: '12 meses',
    precio: 39.90,
  );
  const streaming = Producto(
    nombre: 'CRUNCHYROLL MEGA FAN',
    subtitulo: 'ACCESO COMPARTIDO',
    categoria: 'Streaming',
    logo: 'assets/images/Productos/crunchyroll/crunchyroll_logo.webp',
    banner: 'assets/images/Productos/crunchyroll/crunchyroll_banner.webp',
    colores: [Colors.orange],
    entrega: 'Automática',
    tipo: '30 días',
    precio: 6,
  );

  testWidgets('Las portadas de software y streaming caben en varios anchos', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    for (final ancho in [320.0, 900.0, 1200.0]) {
      tester.view.physicalSize = Size(ancho, 900);
      tester.view.devicePixelRatio = 1;
      for (final pantalla in [
        const DetalleSoftwareScreen(producto: software),
        const DetalleStreamingScreen(producto: streaming),
      ]) {
        await tester.pumpWidget(
          conCarritoScope(
            container,
            MaterialApp(theme: AppTheme.tema, home: pantalla),
          ),
        );
        expect(
          find.text(
            'WEIKANG SHOP  ·  ${pantalla is DetalleSoftwareScreen ? 'SOFTWARE' : 'STREAMING'}',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });
}
