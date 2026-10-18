import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/core/app_theme.dart';
import 'package:prototipo_app/core/configuracion_api.dart';
import 'package:prototipo_app/core/http/error_api.dart';
import 'package:prototipo_app/models/categoria.dart';
import 'package:prototipo_app/providers/carrito_provider.dart';
import 'package:prototipo_app/providers/catalogo_provider.dart';
import 'package:prototipo_app/providers/cliente_http_provider.dart';
import 'package:prototipo_app/repositories/api_catalogo_repository.dart';
import 'package:prototipo_app/screens/home_screen.dart';
import 'package:prototipo_app/screens/carrito_screen.dart';
import 'package:prototipo_app/screens/detalle/detalle_producto_base.dart';
import 'package:prototipo_app/screens/pago_screen.dart';
import 'package:prototipo_app/services/pedido_service.dart';
import 'package:prototipo_app/services/producto_service.dart';

import 'support/auth_test_repository.dart';

import 'package:prototipo_app/widgets/cabecera_tienda.dart';

import 'support/dio_test_adapter.dart';

void main() {
  late ProviderContainer container;
  late DioTestAdapter adapter;
  setUp(() async {
    adapter = DioTestAdapter((_) => respuestaJson(jsonCatalogoApi()));
    container = ProviderContainer(
      overrides: [
        cartRepositoryProvider.overrideWithValue(CartTestRepository()),
        walletRepositoryProvider.overrideWithValue(WalletTestRepository()),
        authRepositoryProvider.overrideWithValue(AuthTestRepository()),
        configuracionApiProvider.overrideWithValue(
          ConfiguracionApi(origen: 'api'),
        ),
      ],
    );
    container.read(clienteHttpProvider).httpClientAdapter = adapter;
  });
  tearDown(() {
    container.dispose();
  });

  Future<void> montar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.tema, home: const HomeScreen()),
      ),
    );
  }

  test(
    'Mock predeterminado no crea un cliente HTTP ni solicita datos remotos',
    () async {
      final local = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(CartTestRepository()),
          walletRepositoryProvider.overrideWithValue(WalletTestRepository()),
          authRepositoryProvider.overrideWithValue(AuthTestRepository()),
          clienteHttpProvider.overrideWith(
            (ref) => throw StateError('Mock no debe leer HTTP'),
          ),
        ],
      );
      addTearDown(local.dispose);
      expect(local.read(catalogoRepositoryProvider), isA<ProductoService>());
      expect(await local.read(catalogoProvider.future), hasLength(34));
    },
  );

  test(
    'El cliente comparte URL, timeouts y cabecera y se cierra con el scope',
    () {
      final cliente = container.read(clienteHttpProvider);
      expect(container.read(clienteHttpProvider), same(cliente));
      expect(cliente.options.baseUrl, ConfiguracionApi.urlProduccion);
      expect(cliente.options.connectTimeout, const Duration(seconds: 10));
      expect(cliente.options.receiveTimeout, const Duration(seconds: 20));
      expect(cliente.options.headers['Accept'], 'application/json');
      expect(adapter.cerrado, isFalse);
      container.dispose();
      expect(adapter.cerrado, isTrue);
      expect(adapter.cierreForzado, isTrue);
    },
  );

  test('API es la única carga compartida para datos y secciones', () async {
    expect(
      container.read(catalogoRepositoryProvider),
      isA<ApiCatalogoRepository>(),
    );
    final datos = await container.read(catalogoProvider.future);
    final categorias = container.read(categoriasCatalogoProvider).requireValue;
    final secciones = container.read(seccionesCatalogoProvider).requireValue;
    expect(datos, hasLength(34));
    expect(datos.where((p) => !p.disponible), hasLength(11));
    expect(categorias.keys, Categoria.catalogo);
    expect(secciones[Categoria.ofertas], hasLength(16));
    expect(categorias[Categoria.software]!.first, same(datos[3]));
    expect(() => datos.clear(), throwsUnsupportedError);
    expect(adapter.peticiones, hasLength(1));
  });

  test(
    'El reintento actualiza catálogo y derivados conservando cliente y carrito',
    () async {
      final originales = await container.read(catalogoProvider.future);
      final carrito = container.read(carritoProvider.notifier);
      carrito.agregar(originales[3]);
      carrito.agregar(originales[3]);
      final snapshot = container.read(carritoProvider);
      final cliente = container.read(clienteHttpProvider);
      final nuevo = jsonCatalogoApi();
      (nuevo['data'] as List).removeAt(3);
      final actualizado = DioTestAdapter((_) => respuestaJson(nuevo));
      cliente.httpClientAdapter = actualizado;
      addTearDown(() => adapter.close(force: true));

      container.invalidate(catalogoProvider);
      final datos = await container.read(catalogoProvider.future);

      expect(datos, hasLength(33));
      expect(
        container
            .read(categoriasCatalogoProvider)
            .requireValue[Categoria.software],
        hasLength(7),
      );
      expect(container.read(clienteHttpProvider), same(cliente));
      expect(actualizado.cerrado, isFalse);
      expect(
        container.read(carritoProvider).cantidadTotal,
        snapshot.cantidadTotal,
      );
      expect(
        container.read(carritoProvider).totalCentimos,
        snapshot.totalCentimos,
      );
      expect(snapshot.cantidadTotal, 2);
      expect(snapshot.total, 15.80);
      await carrito.cambiarCantidad(originales[3].id!, 1);
      expect(container.read(carritoProvider).cantidadTotal, 3);
      await carrito.quitar(originales[3].id!);
      expect(container.read(carritoProvider).vacio, isTrue);
    },
  );

  testWidgets(
    'Error HTTP no mezcla mock; Reintentar vuelve a cargar con el mismo cliente',
    (tester) async {
      final respuesta = Completer<ResponseBody>();
      adapter = DioTestAdapter((_) => respuesta.future);
      final cliente = container.read(clienteHttpProvider)
        ..httpClientAdapter = adapter;
      await montar(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      respuesta.complete(
        respuestaJson({'message': 'No disponible'}, estado: 503),
      );
      await tester.pumpAndSettle();
      expect(find.text('No se pudieron cargar los productos'), findsOneWidget);
      expect(find.textContaining('HTTP 503'), findsOneWidget);
      expect(find.byType(CabeceraTienda), findsNothing);
      expect(container.read(catalogoProvider).error, isA<ErrorApi>());
      await tester.pump(const Duration(seconds: 30));
      expect(adapter.peticiones, hasLength(1));

      final recuperado = DioTestAdapter(
        (_) => respuestaJson(jsonCatalogoApi()),
      );
      cliente.httpClientAdapter = recuperado;
      addTearDown(() => adapter.close(force: true));
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Reintentar'), findsNothing);
      expect(find.byType(CabeceraTienda), findsOneWidget);
      expect(container.read(catalogoProvider).requireValue, hasLength(34));
      expect(container.read(clienteHttpProvider), same(cliente));
      expect(recuperado.peticiones, hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Catálogo HTTP conserva búsqueda, compra, cantidades, contador y confirmación',
    (tester) async {
      expect(
        await tester.runAsync(() => iniciarSesionPrueba(container)),
        isTrue,
      );
      await montar(tester);
      await tester.pumpAndSettle();
      final buscador = find.descendant(
        of: find.byType(CabeceraTienda),
        matching: find.byType(TextField),
      );
      await tester.enterText(buscador, 'CANVA');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.byType(DetalleProductoBase), findsOneWidget);
      final agregar = find.byTooltip('Agregar al carrito');
      await tester.ensureVisible(agregar);
      await tester.tap(agregar);
      await tester.pumpAndSettle();
      await tester.tap(agregar);
      await tester.pumpAndSettle();
      expect(container.read(carritoProvider).cantidadTotal, 2);
      expect(container.read(carritoProvider).total, 15.80);
      final snapshot = container.read(carritoProvider);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      final badge = find.ancestor(
        of: find.byIcon(Icons.shopping_cart_outlined),
        matching: find.byType(Badge),
      );
      expect(
        find.descendant(of: badge, matching: find.text('2')),
        findsOneWidget,
      );
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(CarritoScreen), findsOneWidget);
      expect(
        container.read(carritoProvider).cantidadTotal,
        snapshot.cantidadTotal,
      );
      expect(
        container.read(carritoProvider).totalCentimos,
        snapshot.totalCentimos,
      );
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
      expect(PedidoService.instancia.pedidos.first.productos, ['CANVA PRO x2']);
      expect(PedidoService.instancia.pedidos.first.total, 15.80);
      expect(
        container.read(carritoProvider).cantidadTotal,
        snapshot.cantidadTotal,
      );
      expect(container.read(carritoProvider).remotos, isNotEmpty);
      expect(snapshot.cantidadTotal, 2);
      expect(adapter.peticiones, hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
