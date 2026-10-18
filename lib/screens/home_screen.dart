import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/busqueda_producto.dart';
import '../core/http/error_api.dart';
import '../models/categoria.dart';
import '../models/producto.dart';
import '../providers/carrito_provider.dart';
import '../providers/catalogo_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/cabecera_tienda.dart';
import '../widgets/categorias_chips.dart';
import '../widgets/home/catalogo_categoria.dart';
import '../widgets/home/catalogo_inicio.dart';
import '../widgets/pantalla_base.dart';
import '../widgets/pantalla_carga.dart';
import '../widgets/soporte/soporte_flotante.dart';
import 'carrito_screen.dart';
import 'detalle/detalle_producto.dart';
import 'login_screen.dart';
import 'perfil_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Notifier para redibujar solo los chips, sin reconstruir las páginas.
  final _categoria = ValueNotifier<int>(0);

  final _paginas = PageController();

  @override
  void dispose() {
    _paginas.dispose();
    _categoria.dispose();
    super.dispose();
  }

  // Salta directo a la categoría, sin animar ni construir páginas intermedias.
  void _seleccionarCategoria(int indice) {
    _categoria.value = indice;
    if (_paginas.hasClients) _paginas.jumpToPage(indice);
  }

  // Lleva a la sección del producto cuyo nombre coincide con la búsqueda.
  void _buscar(String texto, List<Producto> productos) {
    if (normalizarBusqueda(texto).isEmpty) return;
    final resultados = buscarProductos(productos, texto);
    if (resultados.isNotEmpty) {
      _seleccionarResultado(resultados.first);
      return;
    }
    _aviso('No se encontraron productos para "$texto"');
  }

  void _seleccionarResultado(Producto producto) {
    final detalle = detalleParaProducto(producto);
    if (detalle != null) {
      Navigator.of(context).push(RutaConCarga(destino: detalle));
      return;
    }
    final indice = Categoria.lista.indexWhere(
      (categoria) => categoria.nombre == producto.categoria,
    );
    if (indice >= 0) {
      _seleccionarCategoria(indice);
      _aviso('${producto.nombre} está en ${producto.categoria}');
    }
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  void _abrirSeccionPerfil({required bool rewards}) {
    Navigator.of(context).push(
      RutaConCarga(
        destino: ref.read(authProvider).iniciada
            ? PerfilScreen(
                mostrarRewards: rewards,
                mostrarColaboradores: !rewards,
              )
            : const LoginScreen(),
      ),
    );
  }

  void _mostrarAppProximamente() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.phone_android, color: AppColors.acento),
        title: const Text('App móvil próximamente'),
        content: const Text(
          'Estamos preparando la app de WEIKANG SHOP. Por ahora puedes comprar desde esta tienda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final compacto = ancho < 700;
    final margen = ancho < 700 ? 16.0 : 32.0;

    return PantallaBase(
      maxAncho: double.infinity,
      floatingActionButton: const SoporteFlotante(),
      child: ref
          .watch(catalogoProvider)
          .when(
            skipLoadingOnRefresh: false,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No se pudieron cargar los productos'),
                  if (error is ErrorApi)
                    Text(error.mensaje, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: () => ref.invalidate(catalogoProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
            data: (productos) => _contenido(productos, compacto, margen, ancho),
          ),
    );
  }

  Widget _contenido(
    List<Producto> todos,
    bool compacto,
    double margen,
    double ancho,
  ) {
    final secciones = ref.watch(seccionesCatalogoProvider).requireValue;
    final categorias = ref.watch(categoriasCatalogoProvider).requireValue;
    return Column(
      children: [
        CabeceraTienda(
          compacto: compacto,
          margen: margen,
          productos: todos,
          onSeleccionarProducto: _seleccionarResultado,
          onBuscar: (texto) => _buscar(texto, todos),
          onLogin: () =>
              Navigator.of(context)
                  .push(RutaConCarga(destino: const LoginScreen())),
          onCarrito: () =>
              Navigator.of(context)
                  .push(RutaConCarga(destino: const CarritoScreen())),
        ),
        ValueListenableBuilder<int>(
          valueListenable: _categoria,
          builder: (_, seleccionada, _) => CategoriasChips(
            margen: margen,
            seleccionada: seleccionada,
            onSeleccion: _seleccionarCategoria,
          ),
        ),
        Expanded(
          child: ScrollConfiguration(
            // Permite arrastrar con mouse además de táctil.
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: PageView.builder(
              controller: _paginas,
              itemCount: Categoria.lista.length,
              onPageChanged: (i) => _categoria.value = i,
              itemBuilder: (_, i) => RepaintBoundary(
                child: i == 0
                    ? CatalogoInicio(
                        ofertas: List.unmodifiable(
                          secciones[Categoria.ofertas]!.take(6),
                        ),
                        masVendidos: List.unmodifiable(
                          secciones[Categoria.masVendidos]!.take(6),
                        ),
                        novedades: List.unmodifiable(
                          secciones[Categoria.novedades]!.take(6),
                        ),
                        productosPorCategoria: categorias,
                        compacto: compacto,
                        margen: margen,
                        ancho: ancho,
                        onSeleccionarCategoria: (categoria) =>
                            _seleccionarCategoria(
                              Categoria.lista.indexOf(categoria),
                            ),
                        onComprar: _comprar,
                        onBeneficios: () => _abrirSeccionPerfil(rewards: true),
                        onColaboradores: () =>
                            _abrirSeccionPerfil(rewards: false),
                        onApp: _mostrarAppProximamente,
                      )
                    : CatalogoCategoria(
                        categoria: Categoria.lista[i],
                        productos: secciones[Categoria.lista[i]]!,
                        margen: margen,
                        ancho: ancho,
                        onComprar: _comprar,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _comprar(Producto producto) async {
    if (!producto.disponible) {
      _aviso('${producto.nombre} no está disponible por ahora');
      return;
    }
    final detalle = detalleParaProducto(producto);
    if (detalle != null) {
      Navigator.of(context).push(RutaConCarga(destino: detalle));
      return;
    }
    final ok = await ref.read(carritoProvider.notifier).agregar(producto);
    if (!mounted) return;
    if (!ok) {
      _aviso(
        ref.read(carritoProvider).error?.mensaje ??
            'No se pudo agregar el producto.',
      );
      return;
    }
    _aviso('${producto.nombre} añadido al carrito');
  }
}
