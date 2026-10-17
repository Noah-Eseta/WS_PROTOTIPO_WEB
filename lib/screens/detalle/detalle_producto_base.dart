import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/acceso_compra.dart';
import '../../core/formato.dart';
import '../../models/producto.dart';
import '../../services/carrito_service.dart';
import '../../widgets/cabecera_tienda.dart';
import '../../widgets/imagen_producto.dart';
import '../../widgets/pantalla_base.dart';
import '../../widgets/pantalla_carga.dart';
import '../../widgets/pie_tienda.dart';
import '../carrito_screen.dart';
import '../login_screen.dart';

/// Icono + texto corto, usado en insignias y tarjetas informativas.
class DetalleItem {
  final IconData icono;
  final String titulo;
  final String texto;

  const DetalleItem(this.icono, this.titulo, [this.texto = '']);
}

/// Estructura común del detalle de compra; cada categoría aporta su contenido.
class DetalleProductoBase extends StatefulWidget {
  final Producto producto;
  final String ruta;
  final List<DetalleItem> insignias;
  final String descripcion;
  final List<DetalleItem> tarjetas;
  final List<String> puntosImportantes;

  const DetalleProductoBase({
    super.key,
    required this.producto,
    required this.ruta,
    required this.insignias,
    required this.descripcion,
    required this.tarjetas,
    required this.puntosImportantes,
  });

  @override
  State<DetalleProductoBase> createState() => _DetalleProductoBaseState();
}

class _DetalleProductoBaseState extends State<DetalleProductoBase> {
  final _codigo = TextEditingController();
  bool _codigoAbierto = false;
  int _pestana = 0;

  Producto get p => widget.producto;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _agregar() async {
    if (!await solicitarSesionParaComprar(context) || !mounted) return;
    CarritoService.instancia.agregar(p);
    _aviso('${p.nombre} añadido al carrito');
  }

  Future<void> _comprarAhora() async {
    if (!await solicitarSesionParaComprar(context) || !mounted) return;
    CarritoService.instancia.agregar(p);
    Navigator.of(context).push(RutaConCarga(destino: const CarritoScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final ancha = ancho >= 900;
    final margen = ancho < 600 ? 16.0 : 24.0;

    final contenido = _contenido();
    final panel = _panelCompra();

    return PantallaBase(
      maxAncho: double.infinity,
      child: Column(
        children: [
          CabeceraTienda(
            compacto: ancho < 700,
            margen: ancho < 700 ? 16.0 : 32.0,
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
                  Padding(
                    padding: EdgeInsets.fromLTRB(margen, 12, margen, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1340),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _migas(),
                            const SizedBox(height: 18),
                            if (ancha)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: contenido),
                                  const SizedBox(width: 18),
                                  SizedBox(width: 310, child: panel),
                                ],
                              )
                            else ...[
                              panel,
                              const SizedBox(height: 16),
                              contenido,
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

  Widget _migas() {
    const estilo = TextStyle(fontSize: 13, color: AppColors.textoSecundario);
    final compacto = MediaQuery.sizeOf(context).width < 400;
    return Row(
      children: [
        IconButton(
          tooltip: 'Volver',
          visualDensity: VisualDensity.compact,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, size: 20),
        ),
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          child: const Row(
            children: [
              Icon(Icons.home_outlined, size: 14, color: AppColors.acento),
              SizedBox(width: 4),
              Text('Inicio', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.chevron_right, size: 16),
        ),
        Text(widget.ruta, style: estilo),
        if (!compacto) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.chevron_right, size: 16),
          ),
          Flexible(
            child: Text(
              p.nombre,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }

  Widget _contenido() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _portada(),
        const SizedBox(height: 10),
        _ventajas(),
        const SizedBox(height: 14),
        _pestanas(),
        const SizedBox(height: 14),
        if (_pestana == 0) _descripcion() else _informacionImportante(),
      ],
    );
  }

  Widget _portada() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final altura = ancho < 450
            ? 420.0
            : ancho < 700
            ? 360.0
            : 300.0;
        return Container(
          width: double.infinity,
          height: altura,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borde),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ImagenProducto.banner(p, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xF208101A),
                      Color(0xC808101A),
                      Color(0x2208101A),
                    ],
                    stops: [0, .55, 1],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(ancho < 450 ? 22 : 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WEIKANG SHOP  ·  ${widget.ruta.toUpperCase()}',
                      style: const TextStyle(
                        color: AppColors.acento,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      p.nombre,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: ancho < 450 ? 30 : 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 470),
                      child: Text(
                        p.subtitulo,
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
                      children: [
                        for (final i in widget.insignias)
                          _Insignia(i.icono, i.titulo),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ventajas() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _caja(),

      child: LayoutBuilder(
        builder: (context, constraints) {
          final ancho = constraints.maxWidth;

          // Determinar cuántas columnas mostrar
          final columnas = ancho >= 700
              ? 3
              : ancho >= 440
              ? 2
              : 1;

          const espacio = 12.0;

          // Calcular el ancho de cada ventaja
          final anchoTarjeta = (ancho - espacio * (columnas - 1)) / columnas;

          return Wrap(
            spacing: espacio,
            runSpacing: 14,
            children: [
              SizedBox(
                width: anchoTarjeta,
                child: _Ventaja(
                  Icons.bolt,
                  'Entrega digital',
                  'Tu acceso queda asociado a tu pedido WEIKANG.',
                ),
              ),

              SizedBox(
                width: anchoTarjeta,
                child: _Ventaja(
                  Icons.rocket_launch_outlined,
                  'Entrega ${p.entrega.toLowerCase()}',
                  'Disponible después de confirmar la compra.',
                ),
              ),

              SizedBox(
                width: anchoTarjeta,
                child: const _Ventaja(
                  Icons.layers_outlined,
                  'En stock',
                  'Accesos disponibles.',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _pestanas() {
    Widget boton(int i, String texto) {
      final activa = _pestana == i;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _pestana = i),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: activa ? AppColors.superficie : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: activa ? AppColors.acento : AppColors.borde,
                  width: activa ? 2 : 1,
                ),
              ),
            ),
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: activa ? Colors.white : AppColors.textoSecundario,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [boton(0, 'Descripción'), boton(1, 'Información importante')],
    );
  }

  Widget _descripcion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'INFORMACIÓN DEL SERVICIO',
          style: TextStyle(
            color: AppColors.acento,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          '${p.nombre} · ${p.tipo}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: 8),

        Text(
          widget.descripcion,
          style: const TextStyle(color: AppColors.textoSecundario, height: 1.4),
        ),

        const SizedBox(height: 16),

        // TARJETAS ADAPTABLES
        LayoutBuilder(
          builder: (context, constraints) {
            final ancho = constraints.maxWidth;

            final columnas = ancho >= 700
                ? 3
                : ancho >= 440
                ? 2
                : 1;

            const espacio = 12.0;

            final anchoTarjeta = (ancho - espacio * (columnas - 1)) / columnas;

            return Wrap(
              spacing: espacio,
              runSpacing: espacio,
              children: [
                for (final t in widget.tarjetas)
                  SizedBox(
                    width: anchoTarjeta,
                    child: _TarjetaInfo(t.icono, t.titulo, t.texto),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _informacionImportante() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _caja(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final texto in widget.puntosImportantes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: AppColors.acento,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      texto,
                      style: const TextStyle(
                        color: AppColors.textoSecundario,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _panelCompra() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _caja(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borde),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                ImagenProducto.logo(p, width: 46, height: 46, radio: 10),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        p.tipo.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Duración',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.acentoSuave,
              border: Border.all(
                color: AppColors.acento.withValues(alpha: 0.6),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PERÍODO ELEGIDO',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.acento,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        p.tipo.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _codigoAbierto = !_codigoAbierto),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borde),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined, size: 16),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Código de descuento o regalo',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textoSecundario,
                      ),
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
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codigo,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Ingresa tu código',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _aviso('Códigos pendientes de implementar'),
                  child: const Text('Aplicar'),
                ),
              ],
            ),
          ],
          const Divider(height: 28, color: AppColors.borde),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total del producto',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ),
              Text(
                p.disponible ? formatoPrecio(p.precio!) : 'Sin disponibilidad',
                style: TextStyle(
                  fontSize: p.disponible ? 24 : 16,
                  fontWeight: FontWeight.w900,
                  color: p.disponible ? null : AppColors.textoSecundario,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: p.disponible ? _comprarAhora : null,
                  icon: const Icon(Icons.bolt, size: 18),
                  label: Text(
                    p.disponible ? 'Comprar ahora' : 'Sin disponibilidad',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: p.disponible ? _agregar : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: EdgeInsets.zero,
                  side: const BorderSide(color: AppColors.acento),
                ),
                child: const Tooltip(
                  message: 'Agregar al carrito',
                  child: Icon(Icons.add_shopping_cart, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _caja() => BoxDecoration(
    color: AppColors.superficie,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppColors.borde),
  );
}

class _Insignia extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Insignia(this.icono, this.texto);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 18, color: AppColors.acento),
        const SizedBox(width: 5),
        Text(
          texto,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _Ventaja extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;

  const _Ventaja(this.icono, this.titulo, this.detalle);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 230),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.acentoSuave,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.acento.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(icono, size: 18, color: AppColors.acento),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  detalle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaInfo extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String texto;

  const _TarjetaInfo(this.icono, this.titulo, this.texto);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: AppColors.acento),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
