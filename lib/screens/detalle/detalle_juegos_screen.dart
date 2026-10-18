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

class _PaqueteJuego {
  final String nombre;
  final String tipo;
  final double precio;
  final IconData icono;

  const _PaqueteJuego(this.nombre, this.tipo, this.precio, this.icono);
}

const _paquetesFreeFire = <_PaqueteJuego>[
  _PaqueteJuego('100 + 10', 'Diamantes', 2.90, Icons.diamond_outlined),
  _PaqueteJuego('310 + 31', 'Diamantes', 8.00, Icons.diamond_outlined),
  _PaqueteJuego('520 + 52', 'Diamantes', 13.50, Icons.diamond_outlined),
  _PaqueteJuego('1060 + 106', 'Diamantes', 24.50, Icons.diamond_outlined),
  _PaqueteJuego('2180 + 218', 'Diamantes', 48.00, Icons.diamond_outlined),
  _PaqueteJuego('3240 + 324', 'Diamantes', 71.00, Icons.diamond_outlined),
  _PaqueteJuego('5600 + 560', 'Diamantes', 121.00, Icons.diamond_outlined),
  _PaqueteJuego('11200 + 1120', 'Diamantes', 238.00, Icons.diamond_outlined),
  _PaqueteJuego('16800 + 1680', 'Diamantes', 355.00, Icons.diamond_outlined),
  _PaqueteJuego(
    'Membresía básica',
    'Membresías',
    1.69,
    Icons.workspace_premium_outlined,
  ),
  _PaqueteJuego(
    'Membresía semanal',
    'Membresías',
    5.90,
    Icons.workspace_premium_outlined,
  ),
  _PaqueteJuego(
    'Membresía mensual',
    'Membresías',
    27.90,
    Icons.workspace_premium_outlined,
  ),
];

class DetalleJuegosScreen extends ConsumerStatefulWidget {
  final Producto producto;

  const DetalleJuegosScreen({super.key, required this.producto});

  @override
  ConsumerState<DetalleJuegosScreen> createState() =>
      _DetalleJuegosScreenState();
}

class _DetalleJuegosScreenState extends ConsumerState<DetalleJuegosScreen> {
  final _jugador = TextEditingController();
  final _codigo = TextEditingController();
  int _seleccion = 0;
  bool _codigoAbierto = false;

  Producto get p => widget.producto;
  bool get _esFreeFire => p.nombre == 'FREE FIRE +10%';
  String get _nombreJuego =>
      p.nombre.startsWith('FREE FIRE') ? 'Free Fire' : p.nombre;
  List<_PaqueteJuego> get _paquetes => _esFreeFire
      ? _paquetesFreeFire
      : [
          _PaqueteJuego(
            p.nombre,
            p.subtitulo,
            p.precio ?? 0,
            Icons.sports_esports_outlined,
          ),
        ];
  _PaqueteJuego get _elegido => _paquetes[_seleccion];
  bool get _listo => p.disponible && _jugador.text.trim().isNotEmpty;

  @override
  void dispose() {
    _jugador.dispose();
    _codigo.dispose();
    super.dispose();
  }

  Producto _productoParaCarrito() {
    final paquete = _elegido;
    final detalle = _esFreeFire ? ' · ${paquete.nombre} ${paquete.tipo}' : '';
    return Producto(
      especial: true,
      nombre:
          '${_nombreJuego.toUpperCase()}$detalle · ID ${_jugador.text.trim()}',
      subtitulo: paquete.tipo,
      categoria: p.categoria,
      colores: p.colores,
      entrega: p.entrega,
      tipo: paquete.tipo,
      precio: paquete.precio,
      logo: p.logo,
      banner: p.banner,
    );
  }

  Future<void> _agregar({required bool abrirCarrito}) async {
    if (!_listo) return;
    final seleccionado = _productoParaCarrito();
    final ok = await ref.read(carritoProvider.notifier).agregar(seleccionado);
    if (!mounted) return;
    if (!ok) return;
    if (abrirCarrito) {
      Navigator.of(context).push(RutaConCarga(destino: const CarritoScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_nombreJuego añadido al carrito')),
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
                              _portada(),
                              const SizedBox(height: 24),
                              _paquetesVista(),
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
      const Icon(
        Icons.chevron_right,
        size: 16,
        color: AppColors.textoSecundario,
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 7),
        child: Text(
          'Juegos',
          style: TextStyle(color: AppColors.textoSecundario),
        ),
      ),
      const Icon(
        Icons.chevron_right,
        size: 16,
        color: AppColors.textoSecundario,
      ),
      Flexible(
        child: Text(
          _nombreJuego,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );

  Widget _contenido() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [_portada(), const SizedBox(height: 24), _paquetesVista()],
  );

  Widget _portada() => Container(
    width: double.infinity,
    height: MediaQuery.sizeOf(context).width < 600 ? 380 : 300,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
    foregroundDecoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _bordePanel),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        ImagenProducto.banner(
          p,
          fit: BoxFit.cover,
          alignment: p.nombre.startsWith('FREE FIRE')
              ? Alignment.topCenter
              : Alignment.center,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xF208101A), Color(0xC808101A), Color(0x2208101A)],
              stops: [0, .55, 1],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WEIKANG SHOP  ·  JUEGOS',
                style: TextStyle(
                  color: AppColors.acento,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _nombreJuego,
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
                constraints: const BoxConstraints(maxWidth: 470),
                child: Text(
                  _esFreeFire
                      ? 'Recarga diamantes y membresías para tu cuenta. Elige tu paquete y continúa con tu compra.'
                      : p.subtitulo,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD2DFEF),
                    height: 1.45,
                  ),
                ),
              ),
              const Spacer(),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: const [
                  _DatoPortada(Icons.diamond_outlined, 'Paquetes digitales'),
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

  Widget _paquetesVista() {
    final paquetes = _paquetes;
    final grupos = _esFreeFire
        ? <String, List<int>>{
            'DIAMANTES': [for (var i = 0; i < 9; i++) i],
            'MEMBRESÍAS': [for (var i = 9; i < paquetes.length; i++) i],
          }
        : <String, List<int>>{
            'PAQUETE DISPONIBLE': [0],
          };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final grupo in grupos.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Text(
                  grupo.key,
                  style: const TextStyle(
                    color: AppColors.acento,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(child: Divider(color: _bordePanel)),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, espacio) {
              final columnas = espacio.maxWidth >= 700
                  ? 3
                  : espacio.maxWidth >= 460
                  ? 2
                  : 1;
              const separacion = 10.0;
              final ancho =
                  (espacio.maxWidth - separacion * (columnas - 1)) / columnas;
              return Wrap(
                spacing: separacion,
                runSpacing: separacion,
                children: [
                  for (final indice in grupo.value)
                    SizedBox(width: ancho, child: _tarjetaPaquete(indice)),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
        ],
      ],
    );
  }

  Widget _tarjetaPaquete(int indice) {
    final paquete = _paquetes[indice];
    final activo = indice == _seleccion;
    return Semantics(
      button: true,
      selected: activo,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFF102D4D) : _fondoPanel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: activo ? AppColors.acento : _bordePanel,
            width: activo ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _seleccion = indice),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.acento.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      paquete.icono,
                      color: AppColors.acento,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paquete.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          paquete.tipo,
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
                  const SizedBox(width: 5),
                  Text(
                    formatoPrecio(paquete.precio),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
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
    padding: const EdgeInsets.all(20),
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
          '1  ·  Ingresa tu ID de jugador',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _jugador,
          onChanged: (_) => setState(() {}),
          maxLength: 32,
          buildCounter: (
            _, {
            required currentLength,
            required isFocused,
            maxLength,
          }) => null,
          decoration: const InputDecoration(
            hintText: 'ID o usuario del juego',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const Divider(height: 30, color: _bordePanel),
        const Text(
          '2  ·  Producto seleccionado',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF091827),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.acento.withValues(alpha: .5)),
          ),
          child: Row(
            children: [
              ImagenProducto.logo(p, width: 50, height: 50, radio: 9),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _elegido.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      _elegido.tipo,
                      style: const TextStyle(
                        color: AppColors.textoSecundario,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                formatoPrecio(_elegido.precio),
                style: const TextStyle(
                  color: AppColors.acento,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _codigoAbierto = !_codigoAbierto),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _bordePanel),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.confirmation_number_outlined,
                  color: AppColors.acento,
                  size: 18,
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'Código de descuento o regalo',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                Icon(
                  _codigoAbierto ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (_codigoAbierto) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _codigo,
            decoration: const InputDecoration(hintText: 'Ingresa tu código'),
          ),
          const SizedBox(height: 6),
          const Text(
            'Los descuentos estarán disponibles próximamente.',
            style: TextStyle(color: AppColors.textoSecundario, fontSize: 11),
          ),
        ],
        const Divider(height: 32, color: _bordePanel),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Total del producto',
                style: TextStyle(color: AppColors.textoSecundario),
              ),
            ),
            Text(
              formatoPrecio(_elegido.precio),
              style: const TextStyle(
                color: AppColors.acento,
                fontSize: 22,
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
        const SizedBox(height: 15),
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
      Text(
        titulo,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    ],
  );
}
