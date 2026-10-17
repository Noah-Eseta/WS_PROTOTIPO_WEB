import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/core/app_theme.dart';
import 'package:prototipo_app/core/formato.dart';
import 'package:prototipo_app/models/producto.dart';
import 'package:prototipo_app/services/producto_service.dart';
import 'package:prototipo_app/widgets/imagen_producto.dart';
import 'package:prototipo_app/widgets/tarjeta_producto.dart';

void main() {
  Future<void> montar(
    WidgetTester tester,
    Producto producto,
    Size pantalla,
    double ancho,
    VoidCallback onComprar,
  ) async {
    tester.view.physicalSize = pantalla;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.tema,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: ancho,
              height: 370,
              child: TarjetaProducto(producto: producto, onComprar: onComprar),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Anchos de tarjeta de las filas de Home en estas resoluciones.
  for (final caso in const [
    (Size(360, 800), 210.0),
    (Size(390, 844), 210.0),
    (Size(600, 960), 210.0),
    (Size(768, 1024), 230.0),
    (Size(1024, 768), 230.0),
    (Size(1440, 900), 207.66666666666663),
  ]) {
    testWidgets('CANVA PRO conserva precios y compra en ${caso.$1.width} px', (
      tester,
    ) async {
      final productos = await ProductoService().obtenerProductos();
      final canva = productos.singleWhere((p) => p.nombre == 'CANVA PRO');
      var compras = 0;
      await montar(tester, canva, caso.$1, caso.$2, () => compras++);

      expect(tester.getSize(find.byType(TarjetaProducto)), Size(caso.$2, 370));
      expect(tester.getSize(find.byType(ImagenProducto)).height, 100);
      for (final precio in [canva.precioAntes!, canva.precio!]) {
        final texto = find.text(formatoPrecio(precio));
        expect(texto, findsOneWidget);
        final parrafo = tester.renderObject<RenderParagraph>(texto);
        expect(parrafo.didExceedMaxLines, isFalse);
        expect(
          parrafo.size.width,
          greaterThanOrEqualTo(parrafo.getMaxIntrinsicWidth(double.infinity)),
          reason: 'El precio completo debe caber sin partirse ni recortarse',
        );
        expect(
          tester
              .getRect(find.byType(TarjetaProducto))
              .contains(tester.getBottomRight(texto)),
          isTrue,
        );
      }
      final boton = find.widgetWithText(OutlinedButton, 'Agregar');
      expect(
        tester.getTopLeft(boton).dy,
        greaterThanOrEqualTo(tester.getBottomRight(find.text('S/ 7.90')).dy),
      );
      await tester.tap(boton);
      expect(compras, 1);
      await tester.tap(find.byType(ImagenProducto));
      expect(compras, 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('El pie conserva la fila cuando hay ancho suficiente', (
    tester,
  ) async {
    final productos = await ProductoService().obtenerProductos();
    final canva = productos.singleWhere((p) => p.nombre == 'CANVA PRO');
    await montar(tester, canva, const Size(1440, 900), 400, () {});
    final precio = tester.getRect(find.text('S/ 7.90'));
    final boton = tester.getRect(
      find.widgetWithText(OutlinedButton, 'Agregar'),
    );
    expect(precio.right, lessThanOrEqualTo(boton.left));
    expect(precio.top, lessThan(boton.bottom));
    expect(precio.bottom, greaterThan(boton.top));
    expect(tester.getSize(find.byType(TarjetaProducto)), const Size(400, 370));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Una tarjeta sin disponibilidad conserva la compra deshabilitada',
    (tester) async {
      final productos = await ProductoService().obtenerProductos();
      final netflix = productos.singleWhere((p) => p.nombre == 'NETFLIX');
      var compras = 0;
      await montar(
        tester,
        netflix,
        const Size(1440, 900),
        230,
        () => compras++,
      );
      expect(find.text('Sin disponibilidad'), findsOneWidget);
      final boton = find.widgetWithText(OutlinedButton, 'Agregar');
      expect(tester.widget<OutlinedButton>(boton).onPressed, isNull);
      await tester.tap(find.byType(ImagenProducto));
      expect(compras, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
