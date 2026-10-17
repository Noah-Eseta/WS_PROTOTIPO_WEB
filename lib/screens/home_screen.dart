import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/acceso_compra.dart';
import '../core/busqueda_producto.dart';
import '../core/formato.dart';
import '../models/categoria.dart';
import '../models/producto.dart';
import '../services/carrito_service.dart';
import '../services/producto_service.dart';
import '../services/sesion_service.dart';
import '../widgets/banner_bienvenida.dart';
import '../widgets/cabecera_tienda.dart';
import '../widgets/categorias_chips.dart';
import '../widgets/chat_soporte_ventana.dart';
import '../widgets/imagen_producto.dart';
import '../widgets/pantalla_base.dart';
import '../widgets/pantalla_carga.dart';
import '../widgets/pie_tienda.dart';
import '../widgets/tarjeta_producto.dart';
import '../widgets/tarjeta_interactiva.dart';
import 'carrito_screen.dart';
import 'detalle/detalle_producto.dart';
import 'login_screen.dart';
import 'perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _espacioTarjeta = 18.0;

  double _anchoFila(double ancho, double margen, int cantidad, double normal) {
    if (cantidad != 6) return normal;
    final ajustado =
        (ancho - margen * 2 - _espacioTarjeta * (cantidad - 1)) / cantidad;
    return ajustado >= 195 ? ajustado : normal;
  }

  final _servicio = ProductoService();
  late final Future<List<Producto>> _productos = _servicio.obtenerProductos();

  // Notifier para redibujar solo los chips, sin reconstruir las páginas.
  final _categoria = ValueNotifier<int>(0);

  final _paginas = PageController();
  bool _chatAbierto = false;
  bool _soporteHover = false;

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
        destino: SesionService.instancia.iniciada
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

  List<Producto> _productosDe(Categoria seccion, List<Producto> todos) {
    return switch (seccion.nombre) {
      'Ofertas del día' =>
        todos
            .where(
              (p) =>
                  p.precio != null &&
                  p.precioAntes != null &&
                  p.precioAntes! > p.precio!,
            )
            .toList(growable: false),
      'Más vendidos' => todos.where((p) => p.top).toList(growable: false),
      'Novedades' => todos.where((p) => p.nuevo).toList(growable: false),
      _ =>
        todos
            .where((p) => p.categoria == seccion.nombre)
            .toList(growable: false),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final compacto = ancho < 700;
    final margen = ancho < 700 ? 16.0 : 32.0;

    return PantallaBase(
      maxAncho: double.infinity,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _chatAbierto
                ? Padding(
                    key: const ValueKey('chat-abierto'),
                    padding: const EdgeInsets.only(bottom: 14),
                    child: SizedBox(
                      width: ancho < 420 ? ancho - 32 : 380,
                      height: (MediaQuery.sizeOf(context).height - 190).clamp(
                        220.0,
                        480.0,
                      ),
                      child: ChatSoporteVentana(
                        onCerrar: () => setState(() => _chatAbierto = false),
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('chat-cerrado')),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _soporteHover = true),
            onExit: (_) => setState(() => _soporteHover = false),
            child: AnimatedScale(
              scale: _soporteHover ? 1.08 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: FloatingActionButton(
                backgroundColor: AppColors.acento,
                foregroundColor: Colors.white,
                tooltip: null,
                onPressed: () => setState(() => _chatAbierto = !_chatAbierto),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    key: ValueKey(_chatAbierto),
                    _chatAbierto ? Icons.close : Icons.headset_mic_outlined,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      child: FutureBuilder<List<Producto>>(
        future: _productos,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudieron cargar los productos'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _contenido(snapshot.data!, compacto, margen, ancho);
        },
      ),
    );
  }

  Widget _contenido(
    List<Producto> todos,
    bool compacto,
    double margen,
    double ancho,
  ) {
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
                    ? _paginaTodos(todos, compacto, margen, ancho)
                    : _paginaCategoria(
                        Categoria.lista[i],
                        todos,
                        margen,
                        ancho,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _paginaCategoria(
    Categoria categoria,
    List<Producto> todos,
    double margen,
    double ancho,
  ) {
    final productos = _productosDe(categoria, todos);
    return CustomScrollView(
      slivers: [
        _sliverCentrado(
          SliverToBoxAdapter(
            child: _encabezadoSeccion(
              margen: margen,
              icono: categoria.icono,
              color: AppColors.acento,
              titulo: categoria.nombre,
              subtitulo: '${productos.length} productos',
              trailing: const SizedBox.shrink(),
            ),
          ),
          ancho,
        ),
        if (productos.isEmpty)
          _sliverCentrado(
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('No hay productos en esta categoría'),
                ),
              ),
            ),
            ancho,
          )
        else
          _sliverCentrado(
            SliverPadding(
              padding: EdgeInsets.fromLTRB(margen, _espacioTarjeta, margen, 96),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 230,
                  mainAxisExtent: 370,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                ),
                itemCount: productos.length,
                itemBuilder: (_, i) => TarjetaProducto(
                  producto: productos[i],
                  onComprar: () => _comprar(productos[i]),
                ),
              ),
            ),
            ancho,
          ),
        const SliverToBoxAdapter(child: PieTienda()),
      ],
    );
  }

  Widget _paginaTodos(
    List<Producto> todos,
    bool compacto,
    double margen,
    double ancho,
  ) {
    final ofertas = _productosDe(Categoria.ofertas, todos).take(6).toList();
    final masVendidos = _productosDe(
      Categoria.masVendidos,
      todos,
    ).take(6).toList();
    final novedades = _productosDe(Categoria.novedades, todos).take(6).toList();
    final seccionesCategoria = _seccionesCategoria(
      todos,
      compacto: compacto,
      margen: margen,
    );

    final contenido = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(margen, 14, margen, 0),
          child: ancho >= 950
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: BannerBienvenida(
                        compacto: false,
                        onExplorar: () => _seleccionarCategoria(
                          Categoria.lista.indexOf(Categoria.ofertas),
                        ),
                        onBeneficios: () => _abrirSeccionPerfil(rewards: true),
                        onColaboradores: () =>
                            _abrirSeccionPerfil(rewards: false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 270,
                      height: 340,
                      child: _PromocionesLaterales(
                        horizontal: false,
                        onApp: _mostrarAppProximamente,
                        onOfertas: () => _seleccionarCategoria(
                          Categoria.lista.indexOf(Categoria.ofertas),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BannerBienvenida(
                      compacto: compacto,
                      onExplorar: () => _seleccionarCategoria(
                        Categoria.lista.indexOf(Categoria.ofertas),
                      ),
                      onBeneficios: () => _abrirSeccionPerfil(rewards: true),
                      onColaboradores: () =>
                          _abrirSeccionPerfil(rewards: false),
                    ),
                    if (ancho >= 600) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 104,
                        child: _PromocionesLaterales(
                          horizontal: true,
                          onApp: _mostrarAppProximamente,
                          onOfertas: () => _seleccionarCategoria(
                            Categoria.lista.indexOf(Categoria.ofertas),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
      SliverToBoxAdapter(
        child: _encabezadoSeccion(
          margen: margen,
          icono: Icons.local_fire_department,
          titulo: 'Ofertas del día',
          subtitulo: 'Grandes descuentos por tiempo limitado',
          trailing: _BotonVerTodo(
            onTap: () => _seleccionarCategoria(
              Categoria.lista.indexOf(Categoria.ofertas),
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: 240 + _espacioTarjeta * 2,
            child: ListView.separated(
              clipBehavior: Clip.none,
              padding: EdgeInsets.symmetric(
                horizontal: margen,
                vertical: _espacioTarjeta,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: ofertas.length,
              separatorBuilder: (_, _) => const SizedBox(width: 18),
              itemBuilder: (_, i) => SizedBox(
                width: _anchoFila(
                  constraints.maxWidth,
                  margen,
                  ofertas.length,
                  compacto ? 210 : 230,
                ),
                child: _OfertaCard(
                  producto: ofertas[i],
                  descuento:
                      '-${((1 - ofertas[i].precio! / ofertas[i].precioAntes!) * 100).round()}%',
                  onComprar: () => _comprar(ofertas[i]),
                ),
              ),
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: _encabezadoSeccion(
          margen: margen,
          icono: Icons.star,
          titulo: 'Más vendidos',
          subtitulo: 'Lo que nuestros clientes más compran',
          trailing: _BotonVerTodo(
            onTap: () => _seleccionarCategoria(
              Categoria.lista.indexOf(Categoria.masVendidos),
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: 100 + _espacioTarjeta * 2,
            child: ListView.separated(
              clipBehavior: Clip.none,
              padding: EdgeInsets.symmetric(
                horizontal: margen,
                vertical: _espacioTarjeta,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: masVendidos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 18),
              itemBuilder: (_, i) => SizedBox(
                width: _anchoFila(
                  constraints.maxWidth,
                  margen,
                  masVendidos.length,
                  compacto ? 260 : 250,
                ),
                child: _MasVendido(
                  producto: masVendidos[i],
                  puesto: i + 1,
                  onComprar: () => _comprar(masVendidos[i]),
                ),
              ),
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: _encabezadoSeccion(
          margen: margen,
          icono: Icons.auto_awesome,
          titulo: 'Novedades',
          subtitulo: 'Descubre lo nuevo en la tienda',
          trailing: _BotonVerTodo(
            onTap: () => _seleccionarCategoria(
              Categoria.lista.indexOf(Categoria.novedades),
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: 370 + _espacioTarjeta * 2,
            child: ListView.separated(
              clipBehavior: Clip.none,
              padding: EdgeInsets.symmetric(
                horizontal: margen,
                vertical: _espacioTarjeta,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: novedades.length,
              separatorBuilder: (_, _) => const SizedBox(width: 18),
              itemBuilder: (_, i) => SizedBox(
                width: _anchoFila(
                  constraints.maxWidth,
                  margen,
                  novedades.length,
                  compacto ? 210 : 230,
                ),
                child: TarjetaProducto(
                  producto: novedades[i],
                  onComprar: () => _comprar(novedades[i]),
                ),
              ),
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(margen, 22, margen, 0),
          child: const _Beneficios(),
        ),
      ),
      ...seccionesCategoria,
    ];

    return CustomScrollView(
      slivers: [
        for (final sliver in contenido) _sliverCentrado(sliver, ancho),
        const SliverToBoxAdapter(child: PieTienda()),
      ],
    );
  }

  Widget _sliverCentrado(Widget sliver, double ancho) {
    final espacioLateral = ancho > 1400 ? (ancho - 1400) / 2 : 0.0;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: espacioLateral),
      sliver: sliver,
    );
  }

  List<Widget> _seccionesCategoria(
    List<Producto> productos, {
    required bool compacto,
    required double margen,
  }) {
    final categorias = Categoria.catalogo
        .where(
          (categoria) => productos.any((p) => p.categoria == categoria.nombre),
        )
        .toList();
    final productosPorCategoria = {
      for (final categoria in categorias)
        categoria.nombre: productos
            .where((p) => p.categoria == categoria.nombre)
            .toList(growable: false),
    };

    if (categorias.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No hay productos en esta categoría')),
          ),
        ),
      ];
    }

    return [
      for (final categoria in categorias) ...[
        SliverToBoxAdapter(
          child: _encabezadoSeccion(
            margen: margen,
            icono: categoria.icono,
            color: AppColors.acento,
            titulo: categoria.nombre,
            subtitulo:
                '${productosPorCategoria[categoria.nombre]!.length} productos',
            trailing: _BotonVerTodo(
              onTap: () =>
                  _seleccionarCategoria(Categoria.lista.indexOf(categoria)),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final lista = productosPorCategoria[categoria.nombre]!;
              final margenExterior = (margen - _espacioTarjeta).clamp(
                0.0,
                margen,
              );
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: margenExterior),
                child: SizedBox(
                  height: 370 + _espacioTarjeta * 2,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: margen - margenExterior,
                      vertical: _espacioTarjeta,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: lista.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: _espacioTarjeta),
                    itemBuilder: (_, i) => SizedBox(
                      width: _anchoFila(
                        constraints.maxWidth,
                        margen,
                        lista.length >= 6 ? 6 : lista.length,
                        compacto ? 210 : 230,
                      ),
                      child: TarjetaProducto(
                        producto: lista[i],
                        onComprar: () => _comprar(lista[i]),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ];
  }

  Future<void> _comprar(Producto producto) async {
    if (!producto.disponible) {
      _aviso('${producto.nombre} no está disponible por ahora');
      return;
    }
    if (!await solicitarSesionParaComprar(context) || !mounted) return;
    final detalle = detalleParaProducto(producto);
    if (detalle != null) {
      Navigator.of(context).push(RutaConCarga(destino: detalle));
      return;
    }
    CarritoService.instancia.agregar(producto);
    _aviso('${producto.nombre} añadido al carrito');
  }

  Widget _encabezadoSeccion({
    required double margen,
    required IconData icono,
    Color? color,
    required String titulo,
    required String subtitulo,
    required Widget trailing,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(margen, 18, margen, 10),
      child: Row(
        children: [
          Icon(
            icono,
            color:
                color ??
                (icono == Icons.star
                    ? const Color(0xFFFFC928)
                    : const Color(0xFFFF613D)),
            size: 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    color: AppColors.textoSecundario,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _BotonVerTodo extends StatelessWidget {
  final VoidCallback onTap;

  const _BotonVerTodo({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.arrow_forward, size: 16),
      label: const Text('Ver todas', style: TextStyle(fontSize: 14)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        side: const BorderSide(color: AppColors.acento),
        foregroundColor: AppColors.acento,
      ),
    );
  }
}

class _OfertaCard extends StatelessWidget {
  final Producto producto;
  final String descuento;
  final VoidCallback onComprar;

  const _OfertaCard({
    required this.producto,
    required this.descuento,
    required this.onComprar,
  });

  @override
  Widget build(BuildContext context) {
    return TarjetaInteractiva(
      onTap: producto.disponible ? onComprar : null,
      radio: 12,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.superficie,
          border: Border.all(color: AppColors.borde),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: ImagenProducto.banner(producto)),
                  Positioned(
                    left: 8,
                    top: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E4D),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        descuento,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          producto.disponible
                              ? formatoPrecio(producto.precio!)
                              : 'Sin disponibilidad',
                          style: TextStyle(
                            fontSize: producto.disponible ? 16 : 12,
                            fontWeight: FontWeight.w800,
                            color: producto.disponible
                                ? null
                                : AppColors.textoSecundario,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 34,
                        child: FilledButton(
                          onPressed: producto.disponible ? onComprar : null,
                          style: FilledButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          child: const Text('Comprar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasVendido extends StatelessWidget {
  final Producto producto;
  final int puesto;
  final VoidCallback onComprar;

  const _MasVendido({
    required this.producto,
    required this.puesto,
    required this.onComprar,
  });

  @override
  Widget build(BuildContext context) {
    return TarjetaInteractiva(
      onTap: producto.disponible ? onComprar : null,
      radio: 11,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          border: Border.all(color: AppColors.borde),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            ImagenProducto.logo(producto, width: 48, height: 48),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    producto.subtitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                  Text(
                    producto.disponible
                        ? formatoPrecio(producto.precio!)
                        : 'Sin disponibilidad',
                    style: TextStyle(
                      fontSize: producto.disponible ? 15 : 12,
                      fontWeight: FontWeight.w800,
                      color: producto.disponible
                          ? null
                          : AppColors.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '#$puesto',
              style: TextStyle(
                color: puesto < 4
                    ? const Color(0xFFFF9D21)
                    : AppColors.textoSecundario,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromocionesLaterales extends StatelessWidget {
  final bool horizontal;
  final VoidCallback onApp;
  final VoidCallback onOfertas;

  const _PromocionesLaterales({
    required this.horizontal,
    required this.onApp,
    required this.onOfertas,
  });

  @override
  Widget build(BuildContext context) {
    return horizontal
        ? Row(
            children: [
              Expanded(
                child: _PromoCard(
                  imagen: 'assets/images/Banners/promo_app.png',
                  titulo: 'DESCARGA LA APP',
                  texto: 'Compra más rápido desde tu celular',
                  onTap: onApp,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PromoCard(
                  imagen: 'assets/images/Banners/promo_ofertas.png',
                  titulo: 'OFERTAS DIARIAS',
                  texto: 'Hasta 50% OFF',
                  onTap: onOfertas,
                ),
              ),
            ],
          )
        : Column(
            children: [
              Expanded(
                child: _PromoCard(
                  imagen: 'assets/images/Banners/promo_app.png',
                  titulo: 'DESCARGA LA APP',
                  texto: 'Compra más rápido desde tu celular',
                  onTap: onApp,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _PromoCard(
                  imagen: 'assets/images/Banners/promo_ofertas.png',
                  titulo: 'OFERTAS DIARIAS',
                  texto: 'Hasta 50% OFF',
                  onTap: onOfertas,
                ),
              ),
            ],
          );
  }
}

class _PromoCard extends StatelessWidget {
  final String imagen;
  final String titulo;
  final String texto;
  final VoidCallback onTap;

  const _PromoCard({
    required this.imagen,
    required this.titulo,
    required this.texto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TarjetaInteractiva(
      onTap: onTap,
      radio: 12,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.acento.withValues(alpha: 0.55)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(imagen, fit: BoxFit.cover, alignment: Alignment.center),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xED07172B),
                    Color(0xA607172B),
                    Color(0x0007172B),
                  ],
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: constraints.maxWidth * 0.64,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            color: AppColors.acento,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          texto,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Beneficios extends StatelessWidget {
  const _Beneficios();

  @override
  Widget build(BuildContext context) {
    const beneficios = [
      (
        Icons.bolt,
        'Entrega digital inmediata',
        'Recibe tus productos al instante',
      ),
      (
        Icons.verified_user_outlined,
        'Pagos seguros',
        'Múltiples métodos de pago',
      ),
      (Icons.groups, '5000+ clientes satisfechos', 'Confían en WEIKANG SHOP'),
      (
        Icons.headset_mic_outlined,
        'Soporte 24/7',
        'Te ayudamos en todo momento',
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borde),
          bottom: BorderSide(color: AppColors.borde),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 12,
        children: beneficios.map((beneficio) {
          return SizedBox(
            width: MediaQuery.sizeOf(context).width < 600 ? 230 : 270,
            child: Row(
              children: [
                Icon(beneficio.$1, color: AppColors.acento, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        beneficio.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        beneficio.$3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
