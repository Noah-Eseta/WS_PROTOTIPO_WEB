import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/busqueda_producto.dart';
import '../core/formato.dart';
import '../models/producto.dart';
import '../providers/carrito_provider.dart';
import '../services/pedido_service.dart';
import '../services/saldo_service.dart';
import '../providers/auth_provider.dart';
import '../screens/perfil_screen.dart';
import '../screens/saldo_screen.dart';
import 'ventana_notificaciones.dart';
import 'pantalla_carga.dart';
import 'logo_marca.dart';
import 'imagen_producto.dart';

class CabeceraTienda extends ConsumerStatefulWidget {
  final bool compacto;
  final double margen;
  final VoidCallback onLogin;
  final VoidCallback onCarrito;
  final List<Producto> productos;
  final ValueChanged<Producto>? onSeleccionarProducto;
  // Si es null, la cabecera se muestra sin buscador.
  final ValueChanged<String>? onBuscar;

  const CabeceraTienda({
    super.key,
    required this.compacto,
    required this.margen,
    required this.onLogin,
    required this.onCarrito,
    this.productos = const [],
    this.onSeleccionarProducto,
    this.onBuscar,
  });

  @override
  ConsumerState<CabeceraTienda> createState() => _CabeceraTiendaState();
}

class _CabeceraTiendaState extends ConsumerState<CabeceraTienda> {
  final _busqueda = TextEditingController();
  final _focoBusqueda = FocusNode();
  final _botonNotificacionesKey = GlobalKey();
  OverlayEntry? _notificacionesOverlay;

  @override
  void initState() {
    super.initState();
    ref.listenManual(authProvider, (_, actual) {
      if (!actual.iniciada) _cerrarNotificaciones();
    });
  }

  @override
  void dispose() {
    _cerrarNotificaciones();
    _busqueda.dispose();
    _focoBusqueda.dispose();
    super.dispose();
  }

  void _buscar() {
    widget.onBuscar?.call(_busqueda.text);
    FocusScope.of(context).unfocus();
  }

  void _mostrarNotificaciones() {
    if (!ref.read(authProvider).iniciada) return;
    if (_notificacionesOverlay != null) {
      _cerrarNotificaciones();
      return;
    }

    final capa = Overlay.of(context, rootOverlay: true);
    final renderCapa = capa.context.findRenderObject() as RenderBox;
    final boton =
        _botonNotificacionesKey.currentContext?.findRenderObject()
            as RenderBox?;
    if (boton == null || !boton.hasSize || !renderCapa.hasSize) return;

    final tamano = renderCapa.size;
    final extremo = boton.localToGlobal(
      Offset(boton.size.width, boton.size.height),
      ancestor: renderCapa,
    );
    final ancho = (tamano.width - 24).clamp(0.0, 460.0);
    final alto = (tamano.height * 0.75)
        .clamp(280.0, 600.0)
        .clamp(0.0, tamano.height - 16);
    final limiteIzquierdo = (tamano.width - ancho - 12).clamp(
      12.0,
      double.infinity,
    );
    final limiteSuperior = (tamano.height - alto - 8).clamp(
      8.0,
      double.infinity,
    );
    final izquierda = (extremo.dx - ancho).clamp(12.0, limiteIzquierdo);
    final arriba = (extremo.dy + 8).clamp(8.0, limiteSuperior);
    _notificacionesOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _cerrarNotificaciones,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: izquierda,
            top: arriba,
            width: ancho,
            height: alto,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              builder: (context, progreso, child) => Opacity(
                opacity: progreso,
                child: Transform.translate(
                  offset: Offset(0, -10 * (1 - progreso)),
                  child: child,
                ),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: VentanaNotificaciones(
                  pedidos: PedidoService.instancia.pedidos,
                  recargas: SaldoService.instancia.recargas,
                  onCerrar: _cerrarNotificaciones,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    capa.insert(_notificacionesOverlay!);
  }

  void _cerrarNotificaciones() {
    _notificacionesOverlay?.remove();
    _notificacionesOverlay?.dispose();
    _notificacionesOverlay = null;
  }

  bool get compacto => widget.compacto;
  double get margen => widget.margen;
  VoidCallback get onLogin => widget.onLogin;
  VoidCallback get onCarrito => widget.onCarrito;

  Widget _construirBuscador() {
    return LayoutBuilder(
      builder: (context, constraints) => RawAutocomplete<Producto>(
        textEditingController: _busqueda,
        focusNode: _focoBusqueda,
        displayStringForOption: (producto) => producto.nombre,
        optionsBuilder: (texto) =>
            buscarProductos(widget.productos, texto.text).take(6),
        onSelected: (producto) {
          _focoBusqueda.unfocus();
          widget.onSeleccionarProducto?.call(producto);
        },
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
            SizedBox(
              height: 38,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _buscar(),
                decoration: InputDecoration(
                  hintText: compacto
                      ? 'Buscar juegos, recargas...'
                      : 'Busca juegos, recargas, cuentas, software...',
                  prefixIcon: const Icon(Icons.search, size: 17),
                  suffixIcon: GestureDetector(
                    onTap: _buscar,
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.acento,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.search,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  filled: true,
                  fillColor: const Color(0xFF0B1B2D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borde),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borde),
                  ),
                ),
                style: const TextStyle(fontSize: 15),
              ),
            ),
        optionsViewBuilder: (context, onSelected, opciones) {
          final resultados = opciones.toList(growable: false);
          return Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: constraints.maxWidth,
              child: Material(
                elevation: 12,
                color: AppColors.superficie,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.borde),
                ),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 340),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: resultados.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColors.borde),
                    itemBuilder: (context, indice) {
                      final producto = resultados[indice];
                      return InkWell(
                        onTap: () => onSelected(producto),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          child: Row(
                            children: [
                              ImagenProducto.logo(
                                producto,
                                width: 42,
                                height: 42,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      producto.nombre,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      producto.categoria,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textoSecundario,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                producto.disponible
                                    ? formatoPrecio(producto.precio!)
                                    : 'Sin precio',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _saldoCuenta() => ListenableBuilder(
    listenable: Listenable.merge([SaldoService.instancia]),
    builder: (context, _) {
      if (!ref.read(authProvider).iniciada) return const SizedBox.shrink();
      return _EscalaAlPasarCursor(
        child: InkWell(
          onTap: () =>
              Navigator.of(context)
                  .push(RutaConCarga(destino: const SaldoScreen())),
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compacto ? 7 : 9,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: AppColors.superficie,
              border: Border.all(color: AppColors.borde),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 14,
                  color: AppColors.acento,
                ),
                const SizedBox(width: 5),
                Text(
                  formatoPrecio(SaldoService.instancia.saldo),
                  style: TextStyle(
                    fontSize: compacto ? 11 : 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);
    return Container(
      padding: EdgeInsets.fromLTRB(margen, 12, margen, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF132234))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              LogoMarca(tamano: compacto ? 34 : 40, compacto: compacto),
              SizedBox(width: compacto ? 6 : 30),
              if (!compacto)
                widget.onBuscar == null
                    ? const Spacer()
                    : Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: _construirBuscador(),
                          ),
                        ),
                      ),
              if (compacto) const Spacer(),
              if (!compacto) const SizedBox(width: 28),
              ListenableBuilder(
                listenable: Listenable.merge([
                  PedidoService.instancia,
                  SaldoService.instancia,
                ]),
                builder: (context, _) {
                  final activa = ref.read(authProvider).iniciada;
                  if (!activa) return const SizedBox.shrink();
                  final hayAvisos =
                      PedidoService.instancia.pedidos.isNotEmpty ||
                      SaldoService.instancia.recargas.isNotEmpty;
                  return _EscalaAlPasarCursor(
                    child: IconButton(
                      key: _botonNotificacionesKey,
                      tooltip: 'Notificaciones',
                      onPressed: _mostrarNotificaciones,
                      padding: compacto ? EdgeInsets.zero : null,
                      constraints: compacto
                          ? const BoxConstraints.tightFor(width: 36, height: 36)
                          : null,
                      visualDensity: VisualDensity.compact,
                      icon: Badge(
                        isLabelVisible: hayAvisos,
                        smallSize: 7,
                        backgroundColor: const Color(0xFFFF335B),
                        child: const Icon(Icons.notifications_none, size: 20),
                      ),
                    ),
                  );
                },
              ),
              Builder(
                builder: (context) {
                  return Consumer(
                    builder: (context, ref, _) {
                      final cantidad = ref.watch(
                        carritoProvider.select(
                          (estado) => estado.cantidadTotal,
                        ),
                      );
                      return _EscalaAlPasarCursor(
                        child: IconButton(
                          tooltip: null,
                          onPressed: onCarrito,
                          padding: compacto ? EdgeInsets.zero : null,
                          constraints: compacto
                              ? const BoxConstraints.tightFor(
                                  width: 36,
                                  height: 36,
                                )
                              : null,
                          visualDensity: VisualDensity.compact,
                          icon: Badge(
                            isLabelVisible: cantidad > 0,
                            label: Text('$cantidad'),
                            child: const Icon(
                              Icons.shopping_cart_outlined,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              SizedBox(width: compacto ? 4 : 6),
              if (!compacto) _saldoCuenta(),
              SizedBox(width: compacto ? 6 : 16),
              _EscalaAlPasarCursor(
                child: Builder(
                  builder: (context) {
                    final sesion = ref.read(authProvider);
                    if (!sesion.iniciada) {
                      return Semantics(
                        label: 'Iniciar sesión',
                        button: true,
                        child: InkWell(
                          onTap: onLogin,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.superficie,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.borde),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              size: 20,
                              color: AppColors.acento,
                            ),
                          ),
                        ),
                      );
                    }
                    return PopupMenuButton<String>(
                      tooltip: '',
                      offset: const Offset(0, 12),
                      color: const Color(0xFF101D30),
                      surfaceTintColor: Colors.transparent,
                      shadowColor: Colors.black.withValues(alpha: .45),
                      elevation: 18,
                      clipBehavior: Clip.antiAlias,
                      constraints: const BoxConstraints(
                        minWidth: 230,
                        maxWidth: 260,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.borde),
                      ),
                      onSelected: (valor) async {
                        if (valor == 'perfil') {
                          Navigator.of(
                            context,
                          ).push(RutaConCarga(destino: const PerfilScreen()));
                        } else if (valor == 'salir') {
                          await ref.read(authProvider.notifier).cerrarSesion();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ref.read(authProvider).error?.mensaje ??
                                    'Sesión cerrada',
                              ),
                            ),
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem<String>(
                          enabled: false,
                          height: 72,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 19,
                                backgroundColor: AppColors.acentoSuave,
                                child: Text(
                                  sesion.nombre.isEmpty
                                      ? 'P'
                                      : sesion.nombre.characters.first
                                            .toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.acento,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sesion.nombre,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      sesion.correo ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textoSecundario,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        const PopupMenuItem(
                          value: 'perfil',
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                color: AppColors.acento,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text('Mi perfil'),
                              Spacer(),
                              Icon(
                                Icons.chevron_right,
                                color: AppColors.textoSecundario,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'salir',
                          child: Row(
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: Color(0xFFFF718A),
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text('Cerrar sesión'),
                            ],
                          ),
                        ),
                      ],
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.acento,
                        child: Text(
                          sesion.nombre.isEmpty
                              ? 'P'
                              : sesion.nombre.characters.first.toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (compacto)
            Builder(
              builder: (context) => ref.read(authProvider).iniciada
                  ? Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _saldoCuenta(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          if (compacto && widget.onBuscar != null) ...[
            const SizedBox(height: 12),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _construirBuscador(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EscalaAlPasarCursor extends StatefulWidget {
  final Widget child;

  const _EscalaAlPasarCursor({required this.child});

  @override
  State<_EscalaAlPasarCursor> createState() => _EscalaAlPasarCursorState();
}

class _EscalaAlPasarCursorState extends State<_EscalaAlPasarCursor> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.12 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
