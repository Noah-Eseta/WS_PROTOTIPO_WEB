import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/core/app_theme.dart';
import 'package:prototipo_app/models/categoria.dart';
import 'package:prototipo_app/models/producto.dart';
import 'package:prototipo_app/services/producto_service.dart';
import 'package:prototipo_app/widgets/home/catalogo_categoria.dart';
import 'package:prototipo_app/widgets/home/portada_inicio.dart';
import 'package:prototipo_app/widgets/tarjeta_producto.dart';

void main() {
  Future<void> montar(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.tema,
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('El catálogo entrega el producto seleccionado al callback', (
    tester,
  ) async {
    final productos = await ProductoService().obtenerProductos();
    final canva = productos.singleWhere((p) => p.nombre == 'CANVA PRO');
    final netflix = productos.singleWhere((p) => p.nombre == 'NETFLIX');
    final compras = <Producto>[];
    await montar(
      tester,
      CatalogoCategoria(
        categoria: Categoria.software,
        productos: [canva, netflix],
        margen: 32,
        ancho: 1024,
        onComprar: compras.add,
      ),
    );
    expect(find.byType(TarjetaProducto), findsNWidgets(2));
    final tarjetaCanva = find.byWidgetPredicate(
      (w) => w is TarjetaProducto && identical(w.producto, canva),
    );
    await tester.tap(
      find.descendant(
        of: tarjetaCanva,
        matching: find.widgetWithText(OutlinedButton, 'Agregar'),
      ),
    );
    expect(compras, [same(canva)]);
    final tarjetaNetflix = find.byWidgetPredicate(
      (w) => w is TarjetaProducto && identical(w.producto, netflix),
    );
    final botonNetflix = find.descendant(
      of: tarjetaNetflix,
      matching: find.widgetWithText(OutlinedButton, 'Agregar'),
    );
    expect(tester.widget<OutlinedButton>(botonNetflix).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('El catálogo conserva el estado vacío con los datos recibidos', (
    tester,
  ) async {
    final compras = <Producto>[];
    await montar(
      tester,
      CatalogoCategoria(
        categoria: Categoria.software,
        productos: const [],
        margen: 32,
        ancho: 1024,
        onComprar: compras.add,
      ),
    );
    expect(find.text('No hay productos en esta categoría'), findsOneWidget);
    expect(find.text('0 productos'), findsOneWidget);
    expect(find.byType(TarjetaProducto), findsNothing);
    expect(compras, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('La portada conserva las acciones de banners y promociones', (
    tester,
  ) async {
    var ofertas = 0;
    var app = 0;
    var beneficios = 0;
    var colaboradores = 0;
    await montar(
      tester,
      PortadaInicio(
        compacto: false,
        margen: 32,
        ancho: 1024,
        onOfertas: () => ofertas++,
        onApp: () => app++,
        onBeneficios: () => beneficios++,
        onColaboradores: () => colaboradores++,
      ),
    );
    await tester.tap(find.text('Explorar tienda'));
    await tester.tap(find.text('OFERTAS DIARIAS'));
    await tester.tap(find.text('DESCARGA LA APP'));
    expect(ofertas, 2);
    expect(app, 1);

    final banners = find.byType(PageView);
    await tester.drag(banners, const Offset(-700, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver beneficios').hitTestable());
    expect(beneficios, 1);
    await tester.drag(banners, const Offset(-700, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Postular ahora').hitTestable());
    expect(colaboradores, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
