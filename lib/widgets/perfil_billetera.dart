import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formato.dart';
import '../services/pedido_service.dart';
import '../services/saldo_service.dart';
import 'perfil_componentes.dart';

const _verdeMovimiento = Color(0xFF53D9B0);

class PerfilSaldo extends StatelessWidget {
  final double saldo;
  final List<RecargaDemo> recargas;
  final VoidCallback onAgregarSaldo;
  final VoidCallback onTransacciones;

  const PerfilSaldo({
    super.key,
    required this.saldo,
    required this.recargas,
    required this.onAgregarSaldo,
    required this.onTransacciones,
  });

  @override
  Widget build(BuildContext context) {
    final ordenadas = [...recargas]..sort((a, b) => b.fecha.compareTo(a.fecha));
    final total = recargas.fold<int>(
      0,
      (suma, recarga) => suma + recarga.centimos,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PerfilEncabezado(
          titulo: 'Mi saldo',
          descripcion: 'Tu billetera y todas tus recargas en un solo lugar.',
          icono: Icons.account_balance_wallet_outlined,
          etiqueta: 'BILLETERA',
        ),
        _cabeceraSaldo(),
        const SizedBox(height: 20),
        PerfilMetricas(
          children: [
            PerfilMetrica(
              titulo: 'Total recargado',
              valor: formatoPrecio(total / 100),
              detalle: 'Importe de todas tus recargas',
              icono: Icons.savings_outlined,
              color: _verdeMovimiento,
            ),
            PerfilMetrica(
              titulo: 'Recargas realizadas',
              valor: '${recargas.length}',
              detalle: 'Movimientos de tu billetera',
              icono: Icons.add_card_outlined,
            ),
            PerfilMetrica(
              titulo: 'Última recarga',
              valor: ordenadas.isEmpty
                  ? 'Sin recargas'
                  : _fecha(ordenadas.first.fecha),
              detalle: ordenadas.isEmpty
                  ? 'Empieza agregando saldo'
                  : 'Con ${ordenadas.first.metodoPago}',
              icono: Icons.schedule_outlined,
              color: const Color(0xFFA78BFA),
            ),
          ],
        ),
        const SizedBox(height: 24),
        PerfilPanel(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TituloHistorial(
                titulo: 'Historial de recargas',
                descripcion: 'Consulta los ingresos de tu billetera.',
                cantidad: recargas.length,
                icono: Icons.history_rounded,
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: PerfilEstilo.borde),
              if (ordenadas.isEmpty)
                PerfilVacio(
                  icono: Icons.account_balance_wallet_outlined,
                  titulo: 'Dale vida a tu billetera',
                  descripcion: 'Agrega saldo y consulta aquí el detalle de tus recargas.',
                  accion: FilledButton.icon(
                    onPressed: onAgregarSaldo,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Agregar saldo'),
                  ),
                )
              else
                for (var i = 0; i < ordenadas.length; i++) ...[
                  _FilaMovimiento(
                    movimiento: _Movimiento.recarga(ordenadas[i]),
                  ),
                  if (i < ordenadas.length - 1)
                    const Divider(height: 1, color: PerfilEstilo.borde),
                ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _cabeceraSaldo() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 680;
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1465A0)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/Banners/perfil_billetera.png',
                  alignment: Alignment.centerRight,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xF508182C),
                        compacto
                            ? const Color(0xCE08182C)
                            : const Color(0x5008182C),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(compacto ? 24 : 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 20,
                          color: AppColors.acento,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'SALDO DISPONIBLE',
                            style: TextStyle(
                              color: PerfilEstilo.textoSuave,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatoPrecio(saldo),
                        style: TextStyle(
                          fontSize: compacto ? 44 : 52,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Gestiona tus recargas de forma sencilla.',
                      style: TextStyle(
                        color: PerfilEstilo.textoSuave,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: onAgregarSaldo,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Agregar saldo'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onTransacciones,
                          icon: const Icon(
                            Icons.receipt_long_outlined,
                            size: 19,
                          ),
                          label: const Text('Ver transacciones'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            backgroundColor: const Color(0xB308182C),
                            side: const BorderSide(color: Color(0xFF32618C)),
                          ),
                        ),
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
}

enum _FiltroMovimiento { todos, compras, recargas }

class PerfilTransacciones extends StatefulWidget {
  final List<PedidoDemo> pedidos;
  final List<RecargaDemo> recargas;
  final VoidCallback onAgregarSaldo;
  final VoidCallback onTienda;

  const PerfilTransacciones({
    super.key,
    required this.pedidos,
    required this.recargas,
    required this.onAgregarSaldo,
    required this.onTienda,
  });

  @override
  State<PerfilTransacciones> createState() => _PerfilTransaccionesState();
}

class _PerfilTransaccionesState extends State<PerfilTransacciones> {
  _FiltroMovimiento _filtro = _FiltroMovimiento.todos;

  @override
  Widget build(BuildContext context) {
    final movimientos = [
      if (_filtro != _FiltroMovimiento.recargas)
        ...widget.pedidos.map(_Movimiento.compra),
      if (_filtro != _FiltroMovimiento.compras)
        ...widget.recargas.map(_Movimiento.recarga),
    ]..sort((a, b) => b.fecha.compareTo(a.fecha));
    final totalCompras = widget.pedidos.fold<double>(
      0,
      (suma, pedido) => suma + pedido.total,
    );
    final totalRecargas = widget.recargas.fold<int>(
      0,
      (suma, recarga) => suma + recarga.centimos,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PerfilEncabezado(
          titulo: 'Transacciones',
          descripcion: 'Sigue el detalle de tus compras y recargas.',
          icono: Icons.receipt_long_outlined,
          etiqueta: 'BILLETERA',
        ),
        PerfilMetricas(
          children: [
            PerfilMetrica(
              titulo: 'Total en compras',
              valor: formatoPrecio(totalCompras),
              detalle: '${widget.pedidos.length} pedido(s) realizados',
              icono: Icons.shopping_bag_outlined,
            ),
            PerfilMetrica(
              titulo: 'Total en recargas',
              valor: formatoPrecio(totalRecargas / 100),
              detalle: '${widget.recargas.length} recarga(s) realizadas',
              icono: Icons.account_balance_wallet_outlined,
              color: _verdeMovimiento,
            ),
            PerfilMetrica(
              titulo: 'Movimientos',
              valor: '${widget.pedidos.length + widget.recargas.length}',
              detalle: 'Toda la actividad de tu cuenta',
              icono: Icons.swap_horiz_rounded,
              color: const Color(0xFFA78BFA),
            ),
          ],
        ),
        const SizedBox(height: 24),
        PerfilPanel(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TituloHistorial(
                titulo: 'Tus movimientos',
                descripcion: 'Los más recientes aparecen primero.',
                cantidad: movimientos.length,
                icono: Icons.history_rounded,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(
                    _FiltroMovimiento.todos,
                    'Todos',
                    widget.pedidos.length + widget.recargas.length,
                  ),
                  _chip(
                    _FiltroMovimiento.compras,
                    'Compras',
                    widget.pedidos.length,
                  ),
                  _chip(
                    _FiltroMovimiento.recargas,
                    'Recargas',
                    widget.recargas.length,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: PerfilEstilo.borde),
              if (movimientos.isEmpty)
                _vacio()
              else
                for (var i = 0; i < movimientos.length; i++) ...[
                  if (i == 0 ||
                      !_mismoDia(
                        movimientos[i - 1].fecha,
                        movimientos[i].fecha,
                      ))
                    Padding(
                      padding: const EdgeInsets.only(top: 22, bottom: 4),
                      child: Text(
                        _fechaGrupo(movimientos[i].fecha),
                        style: const TextStyle(
                          color: PerfilEstilo.textoSuave,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  _FilaMovimiento(movimiento: movimientos[i]),
                  if (i < movimientos.length - 1)
                    const Divider(height: 1, color: PerfilEstilo.borde),
                ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(_FiltroMovimiento filtro, String titulo, int cantidad) {
    final seleccionado = _filtro == filtro;
    return ChoiceChip(
      label: Text('$titulo  $cantidad'),
      selected: seleccionado,
      showCheckmark: false,
      onSelected: (_) => setState(() => _filtro = filtro),
      selectedColor: const Color(0xFF103C61),
      backgroundColor: const Color(0xFF0B192B),
      labelStyle: TextStyle(
        color: seleccionado ? const Color(0xFF4CC6FF) : PerfilEstilo.textoSuave,
        fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: seleccionado ? AppColors.acento : PerfilEstilo.borde,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }

  Widget _vacio() {
    final compras = _filtro == _FiltroMovimiento.compras;
    final recargas = _filtro == _FiltroMovimiento.recargas;
    return PerfilVacio(
      icono: compras
          ? Icons.shopping_bag_outlined
          : recargas
          ? Icons.account_balance_wallet_outlined
          : Icons.receipt_long_outlined,
      titulo: compras
          ? 'Aún no tienes compras'
          : recargas
          ? 'Aún no tienes recargas'
          : 'Tu historial empieza aquí',
      descripcion: compras
          ? 'Explora la tienda y encuentra tu próximo producto digital.'
          : recargas
          ? 'Agrega saldo para ver tu primera recarga en el historial.'
          : 'Cuando realices una compra o recarga, podrás consultar su detalle aquí.',
      accion: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          if (!compras)
            FilledButton.icon(
              onPressed: widget.onAgregarSaldo,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar saldo'),
            ),
          if (!recargas)
            OutlinedButton.icon(
              onPressed: widget.onTienda,
              icon: const Icon(Icons.storefront_outlined, size: 19),
              label: const Text('Ir a la tienda'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            ),
        ],
      ),
    );
  }
}

class _TituloHistorial extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final int cantidad;
  final IconData icono;

  const _TituloHistorial({
    required this.titulo,
    required this.descripcion,
    required this.cantidad,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icono, size: 24, color: AppColors.acento),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              descripcion,
              style: const TextStyle(
                color: PerfilEstilo.textoSuave,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 10),
      PerfilEtiqueta(texto: '$cantidad'),
    ],
  );
}

class _Movimiento {
  final String titulo;
  final String detalle;
  final String metodoPago;
  final DateTime fecha;
  final double importe;
  final bool esRecarga;

  _Movimiento.compra(PedidoDemo pedido)
    : titulo = 'Pedido #${pedido.numero.toString().padLeft(4, '0')}',
      detalle = pedido.productos.join(' · '),
      metodoPago = pedido.metodoPago,
      fecha = pedido.fecha,
      importe = pedido.total,
      esRecarga = false;

  _Movimiento.recarga(RecargaDemo recarga)
    : titulo = 'Recarga de saldo',
      detalle = 'Ingreso a tu billetera',
      metodoPago = recarga.metodoPago,
      fecha = recarga.fecha,
      importe = recarga.centimos / 100,
      esRecarga = true;
}

class _FilaMovimiento extends StatelessWidget {
  final _Movimiento movimiento;

  const _FilaMovimiento({required this.movimiento});

  @override
  Widget build(BuildContext context) {
    final color = movimiento.esRecarga ? _verdeMovimiento : AppColors.acento;
    final importe = Text(
      '${movimiento.esRecarga ? '+ ' : ''}${formatoPrecio(movimiento.importe)}',
      style: TextStyle(
        color: movimiento.esRecarga ? _verdeMovimiento : Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compacto = constraints.maxWidth < 620;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PerfilIcono(
                icono: movimiento.esRecarga
                    ? Icons.south_west_rounded
                    : Icons.shopping_bag_outlined,
                color: color,
                tamano: compacto ? 40 : 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movimiento.titulo,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      movimiento.detalle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PerfilEstilo.textoSuave,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_fecha(movimiento.fecha)} · ${_hora(movimiento.fecha)} · ${movimiento.metodoPago}',
                      style: const TextStyle(
                        color: PerfilEstilo.textoSuave,
                        fontSize: 12,
                      ),
                    ),
                    if (compacto) ...[
                      const SizedBox(height: 12),
                      importe,
                      const SizedBox(height: 8),
                      PerfilEtiqueta(
                        texto: movimiento.esRecarga
                            ? 'Recargado'
                            : 'Compra realizada',
                        color: color,
                      ),
                    ],
                  ],
                ),
              ),
              if (!compacto) ...[
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    importe,
                    const SizedBox(height: 8),
                    PerfilEtiqueta(
                      texto: movimiento.esRecarga
                          ? 'Recargado'
                          : 'Compra realizada',
                      color: color,
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

String _fecha(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

String _hora(DateTime fecha) =>
    '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

bool _mismoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _fechaGrupo(DateTime fecha) {
  final ahora = DateTime.now();
  if (_mismoDia(fecha, ahora)) return 'HOY';
  final ayer = DateTime(ahora.year, ahora.month, ahora.day - 1);
  if (_mismoDia(fecha, ayer)) return 'AYER';
  return _fecha(fecha);
}
