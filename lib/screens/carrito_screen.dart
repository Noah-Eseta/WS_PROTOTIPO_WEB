import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/acceso_compra.dart';
import '../core/formato.dart';
import '../models/item_carrito.dart';
import '../providers/carrito_provider.dart';
import '../models/estado_carrito.dart';
import '../widgets/imagen_producto.dart';
import '../widgets/carrito/estado_sincronizacion_carrito.dart';
import '../widgets/logo_marca.dart';
import '../widgets/pantalla_base.dart';
import '../widgets/pie_tienda.dart';
import '../widgets/pantalla_carga.dart';
import 'pago_screen.dart';

const _fondoPanel = Color(0xFF080C12);
const _rojo = Color(0xFFEF4444);

class CarritoScreen extends ConsumerStatefulWidget {
  const CarritoScreen({super.key});

  @override
  ConsumerState<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends ConsumerState<CarritoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !ref.read(carritoProvider).sincronizando) {
        ref.read(carritoProvider.notifier).actualizar();
      }
    });
  }

  Future<void> _accion(Future<bool> Function() ejecutar) async {
    final ok = await ejecutar();
    if (!mounted || ok) return;
    _aviso(
      ref.read(carritoProvider).error?.mensaje ??
          'No se pudo completar la operación.',
    );
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final carrito = ref.watch(carritoProvider);
    final acciones = ref.read(carritoProvider.notifier);
    final ancho = MediaQuery.sizeOf(context).width;
    final ancha = ancho >= 900;
    final margen = ancho < 600 ? 16.0 : 32.0;

    return PantallaBase(
      maxAncho: double.infinity,
      child: Column(
        children: [
          _Cabecera(margen: margen, total: carrito.total),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(margen, 20, margen, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: double.infinity,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TU COMPRA',
                              style: TextStyle(
                                color: AppColors.acento,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Revisa tus productos antes de continuar con el pago.',
                              style: TextStyle(
                                color: AppColors.textoSecundario,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 22),
                            const EstadoSincronizacionCarrito(),
                            if (carrito.vacio)
                              const _Vacio()
                            else if (ancha)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _Tabla(
                                      carrito: carrito,
                                      onCambiarCantidad: (clave, delta) =>
                                          _accion(
                                            () => acciones.cambiarCantidad(
                                              clave,
                                              delta,
                                            ),
                                          ),
                                      onQuitar: (clave) =>
                                          _accion(() => acciones.quitar(clave)),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  SizedBox(
                                    width: 400,
                                    child: _Resumen(
                                      carrito: carrito,
                                      onAviso: _aviso,
                                      onVaciar: () => _accion(acciones.vaciar),
                                      onContinuar: _continuar,
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              _Tabla(
                                carrito: carrito,
                                onCambiarCantidad: (clave, delta) => _accion(
                                  () => acciones.cambiarCantidad(clave, delta),
                                ),
                                onQuitar: (clave) =>
                                    _accion(() => acciones.quitar(clave)),
                              ),
                              const SizedBox(height: 16),
                              _Resumen(
                                carrito: carrito,
                                onAviso: _aviso,
                                onVaciar: () => _accion(acciones.vaciar),
                                onContinuar: _continuar,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!ancha) const PieTienda(),
                ],
              ),
            ),
          ),
          if (ancha) const PieTienda(),
        ],
      ),
    );
  }

  Future<void> _continuar() async {
    if (ref.read(carritoProvider).vacio) return;
    if (!await solicitarSesionParaComprar(context) || !mounted) return;
    if (!ref.read(carritoProvider).puedeSimular) {
      _aviso('Espera la sincronización y revisa los productos no disponibles.');
      return;
    }
    Navigator.of(context).push(RutaConCarga(destino: const PagoScreen()));
  }
}

class _Cabecera extends StatelessWidget {
  final double margen;
  final double total;

  const _Cabecera({required this.margen, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: margen - 8),
      decoration: const BoxDecoration(
        color: _fondoPanel,
        border: Border(bottom: BorderSide(color: AppColors.borde)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Volver',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          const LogoMarca(tamano: 36),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.superficie,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borde),
            ),
            child: Text(
              formatoPrecio(total),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _caja() => BoxDecoration(
  color: _fondoPanel,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: AppColors.borde),
);

class _Vacio extends StatelessWidget {
  const _Vacio();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      decoration: _caja(),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.acentoSuave,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.acento.withValues(alpha: 0.5),
              ),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: AppColors.acento,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'TU CARRITO',
            style: TextStyle(
              color: AppColors.acento,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'No agregaste productos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Explora la tienda y agrega los productos digitales que quieras comprar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textoSecundario, fontSize: 12),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ir a la tienda'),
          ),
        ],
      ),
    );
  }
}

class _Tabla extends StatelessWidget {
  final EstadoCarrito carrito;
  final void Function(String, int) onCambiarCantidad;
  final ValueChanged<String> onQuitar;

  const _Tabla({
    required this.carrito,
    required this.onCambiarCantidad,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    const estiloCabecera = TextStyle(
      color: AppColors.textoSecundario,
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
    );

    return Container(
      decoration: _caja(),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(child: Text('PRODUCTO', style: estiloCabecera)),
                Text('PRECIO', style: estiloCabecera),
              ],
            ),
          ),
          for (final item in carrito.items) ...[
            const Divider(height: 1, color: AppColors.borde),
            _FilaItem(
              item: item,
              onCambiarCantidad: onCambiarCantidad,
              onQuitar: onQuitar,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilaItem extends StatelessWidget {
  final ItemCarrito item;
  final void Function(String, int) onCambiarCantidad;
  final ValueChanged<String> onQuitar;

  const _FilaItem({
    required this.item,
    required this.onCambiarCantidad,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final p = item.producto;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImagenProducto.logo(p, width: 72, height: 72, radio: 12),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  !p.disponible
                      ? 'NO DISPONIBLE'
                      : item.persistente
                      ? 'GUARDADO EN TU CUENTA'
                      : p.sincronizable
                      ? 'SELECCIÓN DE VISITANTE'
                      : 'DEMOSTRACIÓN LOCAL',
                  style: const TextStyle(
                    color: AppColors.textoSecundario,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _BotonCantidad(
                      icono: Icons.remove,
                      tooltip: 'Disminuir',
                      onPressed: () => onCambiarCantidad(item.clave, -1),
                    ),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '${item.cantidad}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _BotonCantidad(
                      icono: Icons.add,
                      tooltip: 'Aumentar',
                      onPressed: () => onCambiarCantidad(item.clave, 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                p.disponible ? formatoPrecio(item.subtotal) : 'No disponible',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'x ${item.cantidad}',
                style: const TextStyle(
                  color: AppColors.textoSecundario,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 34,
                height: 34,
                child: IconButton(
                  tooltip: 'Quitar',
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: _rojo.withValues(alpha: 0.1),
                    side: BorderSide(color: _rojo.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => onQuitar(item.clave),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 17,
                    color: _rojo,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BotonCantidad extends StatelessWidget {
  final IconData icono;
  final String tooltip;
  final VoidCallback onPressed;

  const _BotonCantidad({
    required this.icono,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          side: const BorderSide(color: AppColors.borde),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        icon: Icon(icono, size: 15),
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  final EstadoCarrito carrito;
  final void Function(String) onAviso;
  final VoidCallback onContinuar;
  final VoidCallback onVaciar;

  const _Resumen({
    required this.carrito,
    required this.onAviso,
    required this.onContinuar,
    required this.onVaciar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _caja(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'RESUMEN (${carrito.cantidadTotal})',
            style: const TextStyle(
              color: AppColors.acento,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const Divider(height: 24, color: AppColors.borde),
          for (final i in carrito.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      i.cantidad > 1
                          ? '${i.producto.nombre} x${i.cantidad}'
                          : i.producto.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    formatoPrecio(i.subtotal),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 24, color: AppColors.borde),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
              Text(
                formatoPrecio(carrito.total),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => onAviso('Códigos pendientes de implementar'),
            icon: const Icon(Icons.confirmation_number_outlined, size: 16),
            label: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Código de descuento o regalo',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: carrito.puedeSimular ? onContinuar : null,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continuar'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Vaciar carrito',
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    onPressed: carrito.sincronizando ? null : onVaciar,
                    style: IconButton.styleFrom(
                      backgroundColor: _rojo.withValues(alpha: 0.1),
                      side: BorderSide(color: _rojo.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline, color: _rojo),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.acentoSuave,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borde),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_outlined, size: 14),
                SizedBox(width: 6),
                Text(
                  'Compra segura',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
