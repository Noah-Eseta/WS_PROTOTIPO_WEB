import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/core/app_theme.dart';
import 'package:prototipo_app/models/categoria.dart';
import 'package:prototipo_app/models/producto.dart';
import 'package:prototipo_app/providers/carrito_provider.dart';
import 'package:prototipo_app/providers/catalogo_provider.dart';
import 'package:prototipo_app/screens/carrito_screen.dart';
import 'package:prototipo_app/screens/detalle/detalle_producto_base.dart';
import 'package:prototipo_app/screens/home_screen.dart';
import 'package:prototipo_app/screens/pago_screen.dart';
import 'package:prototipo_app/services/pedido_service.dart';
import 'package:prototipo_app/services/sesion_service.dart';
import 'package:prototipo_app/widgets/cabecera_tienda.dart';
import 'package:prototipo_app/widgets/categorias_chips.dart';
import 'package:prototipo_app/widgets/home/catalogo_categoria.dart';
import 'package:prototipo_app/widgets/home/catalogo_inicio.dart';
import 'package:prototipo_app/widgets/imagen_producto.dart';

import 'support/catalogo_test_repository.dart';

void main() {
  late ProviderContainer container;
  late CatalogoTestRepository repositorio;

  setUp(() {
    repositorio = CatalogoTestRepository();
    SesionService.instancia.cerrarSesion();
  });
  tearDown(() {
    container.dispose();
    SesionService.instancia.cerrarSesion();
  });

  Future<void> montar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    container = ProviderContainer(
      overrides: [catalogoRepositoryProvider.overrideWithValue(repositorio)],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.tema, home: const HomeScreen()),
      ),
    );
  }

  Future<void> desmontar(WidgetTester tester) async {
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }

  Finder buscador() => find.descendant(
    of: find.byType(CabeceraTienda),
    matching: find.byType(TextField),
  );

  testWidgets('Conserva la carga y el mensaje de error sin reintentar', (
    tester,
  ) async {
    final carga = Completer<List<Producto>>();
    repositorio = CatalogoTestRepository(cargar: () => carga.future);
    await montar(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(CabeceraTienda), findsNothing);
    carga.completeError(Exception('Catálogo no disponible'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudieron cargar los productos'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pump(const Duration(seconds: 30));
    expect(repositorio.llamadas, 1);
    await desmontar(tester);
  });

  testWidgets('Un catálogo vacío conserva los mensajes y la navegación local', (
    tester,
  ) async {
    repositorio = CatalogoTestRepository(cargar: () async => []);
    await montar(tester);
    await tester.pumpAndSettle();
    expect(
      tester.widget<CabeceraTienda>(find.byType(CabeceraTienda)).productos,
      isEmpty,
    );
    tester.widget<CategoriasChips>(find.byType(CategoriasChips)).onSeleccion(1);
    await tester.pumpAndSettle();
    expect(find.text('No hay productos en esta categoría'), findsOneWidget);
    expect(
      tester
          .widget<CatalogoCategoria>(find.byType(CatalogoCategoria))
          .productos,
      isEmpty,
    );
    expect(repositorio.llamadas, 1);
    await desmontar(tester);
  });

  testWidgets('Home conserva las secciones, sus límites y las categorías', (
    tester,
  ) async {
    await montar(tester);
    await tester.pumpAndSettle();
    final portada = tester.widget<CatalogoInicio>(find.byType(CatalogoInicio));
    expect(portada.ofertas.map((p) => p.nombre), [
      'CANVA PRO',
      'PRIME VIDEO',
      'MAX PLATINO',
      'CRUNCHYROLL MEGA FAN',
      'VIX PREMIUM',
      'PARAMOUNT+',
    ]);
    expect(portada.masVendidos, hasLength(6));
    expect(portada.novedades, hasLength(6));
    expect(portada.productosPorCategoria.keys, Categoria.catalogo);
    expect(() => portada.ofertas.clear(), throwsUnsupportedError);
    final secciones = container.read(seccionesCatalogoProvider).requireValue;
    for (var i = 1; i < Categoria.lista.length; i++) {
      tester
          .widget<CategoriasChips>(find.byType(CategoriasChips))
          .onSeleccion(i);
      await tester.pumpAndSettle();
      final pagina = tester.widget<CatalogoCategoria>(
        find.byType(CatalogoCategoria),
      );
      expect(pagina.categoria, Categoria.lista[i]);
      expect(pagina.productos, same(secciones[Categoria.lista[i]]));
      expect(
        tester
            .widget<CategoriasChips>(find.byType(CategoriasChips))
            .seleccionada,
        i,
      );
    }
    expect(repositorio.llamadas, 1);
    await desmontar(tester);
  });

  testWidgets(
    'Búsqueda conserva seis sugerencias, el primer resultado y el texto al volver',
    (tester) async {
      await montar(tester);
      await tester.pumpAndSettle();
      final autocomplete = tester.widget<RawAutocomplete<Producto>>(
        find.byType(RawAutocomplete<Producto>),
      );
      final opciones = await autocomplete.optionsBuilder(
        const TextEditingValue(text: 'acceso'),
      );
      expect(opciones, hasLength(6));
      expect(opciones.first.nombre, 'PRIME VIDEO');
      await tester.enterText(buscador(), 'no existe');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(
        find.text('No se encontraron productos para "no existe"'),
        findsOneWidget,
      );

      await tester.enterText(buscador(), '  CÁNVA  ');
      await tester.pumpAndSettle();
      final lista = find.byWidgetPredicate(
        (widget) =>
            widget is ListView &&
            widget.shrinkWrap &&
            widget.scrollDirection == Axis.vertical,
      );
      expect(
        find.descendant(of: lista, matching: find.byType(ImagenProducto)),
        findsOneWidget,
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DetalleProductoBase>(find.byType(DetalleProductoBase))
            .producto
            .nombre,
        'CANVA PRO',
      );
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(buscador()).controller!.text,
        '  CÁNVA  ',
      );
      expect(repositorio.llamadas, 1);
      await desmontar(tester);
    },
  );

  testWidgets(
    'Comprar desde el catálogo conserva contador, carrito y confirmación',
    (tester) async {
      expect(
        SesionService.instancia.iniciarSesion('prueba@email.com', 'prueba_123'),
        isTrue,
      );
      await montar(tester);
      await tester.pumpAndSettle();
      await tester.enterText(buscador(), 'CANVA');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      final agregar = find.byTooltip('Agregar al carrito');
      await tester.ensureVisible(agregar);
      await tester.tap(agregar);
      await tester.pumpAndSettle();
      expect(container.read(carritoProvider).total, 7.90);
      final snapshot = container.read(carritoProvider);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      final badge = find.ancestor(
        of: find.byIcon(Icons.shopping_cart_outlined),
        matching: find.byType(Badge),
      );
      expect(
        find.descendant(of: badge, matching: find.text('1')),
        findsOneWidget,
      );
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(CarritoScreen), findsOneWidget);
      expect(container.read(carritoProvider), same(snapshot));
      final continuar = find.widgetWithText(FilledButton, 'Continuar');
      await tester.ensureVisible(continuar);
      await tester.tap(continuar);
      await tester.pumpAndSettle();
      expect(find.byType(PagoScreen), findsOneWidget);
      await tester.ensureVisible(find.text('Yape'));
      await tester.tap(find.text('Yape'));
      await tester.pumpAndSettle();
      final anteriores = PedidoService.instancia.pedidos.length;
      final confirmar = find.widgetWithText(FilledButton, 'Confirmar pedido');
      await tester.ensureVisible(confirmar);
      await tester.tap(confirmar);
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmacionPedidoScreen), findsOneWidget);
      expect(PedidoService.instancia.pedidos.length, anteriores + 1);
      expect(PedidoService.instancia.pedidos.first.productos, ['CANVA PRO x1']);
      expect(PedidoService.instancia.pedidos.first.total, 7.90);
      expect(container.read(carritoProvider).vacio, isTrue);
      expect(snapshot.total, 7.90);
      expect(repositorio.llamadas, 1);
      await desmontar(tester);
    },
  );
}
