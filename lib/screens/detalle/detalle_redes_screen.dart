import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/formato.dart';
import '../../models/producto.dart';
import '../../providers/carrito_provider.dart';
import '../../widgets/cabecera_tienda.dart';
import '../../widgets/imagen_producto.dart';
import '../../widgets/pantalla_base.dart';
import '../../widgets/pantalla_carga.dart';
import '../../widgets/pie_tienda.dart';
import '../carrito_screen.dart';
import '../login_screen.dart';

const _fondoPanel = Color(0xFF101D30);
const _bordePanel = Color(0xFF214463);

class _ServicioRed {
  final String categoria;
  final String nombre;
  final String descripcion;
  final double precioPorMil;
  int get minimo => 100;
  int get maximo => 100000;

  const _ServicioRed({
    required this.categoria,
    required this.nombre,
    required this.descripcion,
    required this.precioPorMil,
  });
}

class DetalleRedesScreen extends ConsumerStatefulWidget {
  final Producto producto;

  const DetalleRedesScreen({super.key, required this.producto});

  @override
  ConsumerState<DetalleRedesScreen> createState() => _DetalleRedesScreenState();
}

class _DetalleRedesScreenState extends ConsumerState<DetalleRedesScreen> {
  final _busqueda = TextEditingController();
  final _enlace = TextEditingController();
  _ServicioRed? _seleccionado;
  String _categoria = 'Seguidores';
  int _cantidad = 1000;

  Producto get p => widget.producto;
  bool get _esTikTok => p.nombre.toUpperCase() == 'TIKTOK';
  String get _nombreRed {
    final nombre = p.nombre.toLowerCase();
    if (nombre == 'tiktok') return 'TikTok';
    if (nombre == 'instagram') return 'Instagram';
    return p.nombre;
  }

  List<_ServicioRed> get _servicios {
    if (!p.disponible) return const [];
    if (_esTikTok) {
      return const [
        _ServicioRed(
          categoria: 'Seguidores',
          nombre: 'Seguidores · estándar',
          descripcion: 'Servicio digital para perfiles de TikTok',
          precioPorMil: 8.01,
        ),
        _ServicioRed(
          categoria: 'Seguidores',
          nombre: 'Seguidores · gradual',
          descripcion: 'Entrega gradual · opción recomendada',
          precioPorMil: 3.88,
        ),
        _ServicioRed(
          categoria: 'Seguidores',
          nombre: 'Seguidores · prioritario',
          descripcion: 'Servicio digital prioritario',
          precioPorMil: 5.22,
        ),
        _ServicioRed(
          categoria: 'Me gusta',
          nombre: 'Me gusta para publicación',
          descripcion: 'Para un enlace público de TikTok',
          precioPorMil: 5.90,
        ),
        _ServicioRed(
          categoria: 'Visualizaciones',
          nombre: 'Visualizaciones para video',
          descripcion: 'Para un enlace público de TikTok',
          precioPorMil: 5.90,
        ),
      ];
    }
    return [
      for (final categoria in ['Seguidores', 'Me gusta', 'Visualizaciones'])
        _ServicioRed(
          categoria: categoria,
          nombre: '$categoria para $_nombreRed',
          descripcion: categoria == 'Seguidores'
              ? 'Para un perfil público de $_nombreRed'
              : 'Para una publicación pública de $_nombreRed',
          precioPorMil: p.precio!,
        ),
    ];
  }

  List<_ServicioRed> get _visibles {
    final consulta = _busqueda.text.trim().toLowerCase();
    return _servicios.where((servicio) {
      return servicio.categoria == _categoria &&
          (consulta.isEmpty ||
              '${servicio.nombre} ${servicio.descripcion}'
                  .toLowerCase()
                  .contains(consulta));
    }).toList();
  }

  bool get _enlaceValido {
    final uri = Uri.tryParse(_enlace.text.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.contains('.');
  }

  bool get _listo => p.disponible && _seleccionado != null && _enlaceValido;
  double get _total => (_seleccionado?.precioPorMil ?? 0) * _cantidad / 1000;

  @override
  void dispose() {
    _busqueda.dispose();
    _enlace.dispose();
    super.dispose();
  }

  void _cambiarCantidad(int delta) {
    final servicio = _seleccionado;
    if (servicio == null) return;
    setState(() {
      _cantidad = (_cantidad + delta).clamp(servicio.minimo, servicio.maximo);
    });
  }

  Future<void> _agregar({required bool abrirCarrito}) async {
    if (!_listo) return;
    final servicio = _seleccionado!;
    final producto = Producto(
      especial: true,
      nombre:
          '${p.nombre} · ${servicio.nombre} · $_cantidad · ${_enlace.text.trim()}',
      subtitulo: '$_cantidad ${servicio.categoria.toLowerCase()}',
      categoria: p.categoria,
      colores: p.colores,
      entrega: p.entrega,
      tipo: 'Servicio digital',
      precio: _total,
      logo: p.logo,
      banner: p.banner,
    );
    final ok = await ref.read(carritoProvider.notifier).agregar(producto);
    if (!mounted) return;
    if (!ok) return;
    if (abrirCarrito) {
      Navigator.of(context).push(RutaConCarga(destino: const CarritoScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Servicio añadido al carrito')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final escritorio = ancho >= 950;
    final margen = ancho < 600 ? 16.0 : 28.0;
    return PantallaBase(
      maxAncho: double.infinity,
      child: Column(
        children: [
          CabeceraTienda(
            compacto: ancho < 700,
            margen: ancho < 700 ? 16 : 32,
            onLogin: () =>
                Navigator.of(context)
                    .push(RutaConCarga(destino: const LoginScreen())),
            onCarrito: () =>
                Navigator.of(context)
                    .push(RutaConCarga(destino: const CarritoScreen())),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1480),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(margen, 22, margen, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _migas(),
                            const SizedBox(height: 24),
                            if (escritorio)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _contenido()),
                                  const SizedBox(width: 22),
                                  SizedBox(width: 360, child: _resumen()),
                                ],
                              )
                            else ...[
                              _contenido(),
                              const SizedBox(height: 22),
                              _resumen(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const PieTienda(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _migas() => Row(
    children: [
      TextButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.home_outlined, size: 16),
        label: const Text('Inicio'),
      ),
      const Icon(Icons.chevron_right, size: 16),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          'Redes',
          style: TextStyle(color: AppColors.textoSecundario),
        ),
      ),
      const Icon(Icons.chevron_right, size: 16),
      Flexible(
        child: Text(
          _nombreRed,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );

  Widget _contenido() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [_portada(), const SizedBox(height: 22), _selectorServicios()],
  );

  Widget _portada() => Container(
    width: double.infinity,
    height: MediaQuery.sizeOf(context).width < 600 ? 320 : 270,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
    foregroundDecoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _bordePanel),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        ImagenProducto.banner(p, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFA080F19), Color(0xD0080F19), Color(0x28080F19)],
              stops: [0, .58, 1],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WEIKANG SHOP  ·  REDES',
                style: TextStyle(
                  color: AppColors.acento,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _nombreRed,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Text(
                  'Elige un servicio para tu perfil o publicación y continúa con tu compra.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFD2DFEF), height: 1.4),
                ),
              ),
              const Spacer(),
              const Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _DatoPortada(Icons.people_outline, 'Servicios digitales'),
                  _DatoPortada(Icons.verified_user_outlined, 'Compra segura'),
                  _DatoPortada(Icons.bolt_outlined, 'Entrega digital'),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _selectorServicios() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _fondoPanel,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _bordePanel),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SELECCIÓN WEIKANG',
          style: TextStyle(
            color: AppColors.acento,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              _categoria,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            SizedBox(
              width: 210,
              child: DropdownButton<String>(
                isExpanded: true,
                value: _categoria,
                items: ['Seguidores', 'Me gusta', 'Visualizaciones']
                    .map(
                      (categoria) => DropdownMenuItem(
                        value: categoria,
                        child: Text(categoria),
                      ),
                    )
                    .toList(),
                onChanged: (categoria) {
                  if (categoria == null) return;
                  setState(() {
                    _categoria = categoria;
                    _seleccionado = null;
                    _busqueda.clear();
                  });
                },
              ),
            ),
          ],
        ),
        Text(
          '${_servicios.where((s) => s.categoria == _categoria).length} servicios · Precios de demostración',
          style: const TextStyle(
            color: AppColors.textoSecundario,
            fontSize: 11,
          ),
        ),
        const Divider(height: 30, color: _bordePanel),
        const Text(
          'Elige un servicio',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _busqueda,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Buscar servicio',
            prefixIcon: Icon(Icons.search, size: 19),
          ),
        ),
        const SizedBox(height: 14),
        if (_visibles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No hay servicios disponibles para esta búsqueda.',
                style: TextStyle(color: AppColors.textoSecundario),
              ),
            ),
          )
        else
          for (final servicio in _visibles) ...[
            _tarjetaServicio(servicio),
            const SizedBox(height: 9),
          ],
      ],
    ),
  );

  Widget _tarjetaServicio(_ServicioRed servicio) {
    final activo =
        _seleccionado?.nombre == servicio.nombre &&
        _seleccionado?.categoria == servicio.categoria;
    return Semantics(
      button: true,
      selected: activo,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFF102D4D) : const Color(0xFF0C1726),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: activo ? AppColors.acento : _bordePanel,
            width: activo ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: () => setState(() {
              _seleccionado = servicio;
              _cantidad = _cantidad.clamp(servicio.minimo, servicio.maximo);
            }),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    activo
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 18,
                    color: activo
                        ? AppColors.acento
                        : AppColors.textoSecundario,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          servicio.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${servicio.descripcion} · Mín ${servicio.minimo} · Máx ${servicio.maximo}',
                          style: const TextStyle(
                            color: AppColors.textoSecundario,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatoPrecio(servicio.precioPorMil),
                    style: const TextStyle(
                      color: AppColors.acento,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _resumen() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF102540), Color(0xFF0B1728)],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _bordePanel),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(Icons.shopping_cart_outlined, color: AppColors.acento),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Resumen de compra',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const Divider(height: 30, color: _bordePanel),
        const Text(
          'Servicio seleccionado',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF091827),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.acento.withValues(alpha: .5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.people_outline, color: AppColors.acento),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _seleccionado?.nombre ?? 'Selecciona un servicio',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      _seleccionado == null
                          ? 'Elige una opción disponible.'
                          : '${formatoPrecio(_seleccionado!.precioPorMil)} por 1,000',
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
        const Divider(height: 30, color: _bordePanel),
        const Text('Cantidad', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 9),
        Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _bordePanel),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Reducir cantidad',
                onPressed: _seleccionado == null
                    ? null
                    : () => _cambiarCantidad(-100),
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Text(
                  '$_cantidad',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Aumentar cantidad',
                onPressed: _seleccionado == null
                    ? null
                    : () => _cambiarCantidad(100),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Text(
          _seleccionado == null
              ? 'Selecciona un servicio para ver sus límites.'
              : 'Mínimo ${_seleccionado!.minimo} · Máximo ${_seleccionado!.maximo}',
          style: const TextStyle(
            color: AppColors.textoSecundario,
            fontSize: 11,
          ),
        ),
        const Divider(height: 30, color: _bordePanel),
        const Text(
          'Enlace del perfil / publicación',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _enlace,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'https://...',
            prefixIcon: Icon(Icons.link_outlined),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          _enlace.text.isNotEmpty && !_enlaceValido
              ? 'Ingresa un enlace válido que empiece por https://'
              : 'Ingresa el enlace público exacto que recibirá el servicio.',
          style: TextStyle(
            color: _enlace.text.isNotEmpty && !_enlaceValido
                ? Colors.orangeAccent
                : AppColors.textoSecundario,
            fontSize: 11,
          ),
        ),
        const Divider(height: 30, color: _bordePanel),
        Row(
          children: [
            const Expanded(child: Text('Total del producto')),
            Text(
              _seleccionado == null ? '—' : formatoPrecio(_total),
              style: const TextStyle(
                color: AppColors.acento,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _listo ? () => _agregar(abrirCarrito: true) : null,
                icon: const Icon(Icons.bolt_outlined, size: 18),
                label: const Text('Comprar ahora'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _listo ? () => _agregar(abrirCarrito: false) : null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: EdgeInsets.zero,
                side: const BorderSide(color: AppColors.acento),
              ),
              child: const Tooltip(
                message: 'Agregar al carrito',
                child: Icon(Icons.add_shopping_cart_outlined, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'El método de pago se selecciona al continuar con la compra.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textoSecundario, fontSize: 11),
        ),
      ],
    ),
  );
}

class _DatoPortada extends StatelessWidget {
  final IconData icono;
  final String titulo;

  const _DatoPortada(this.icono, this.titulo);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icono, color: AppColors.acento, size: 18),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          titulo,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}
