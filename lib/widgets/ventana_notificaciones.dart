import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formato.dart';
import '../services/pedido_service.dart';
import '../models/billetera.dart';

class VentanaNotificaciones extends StatelessWidget {
  final List<PedidoDemo> pedidos;
  final List<MovimientoBilletera> recargas;
  final VoidCallback onCerrar;

  const VentanaNotificaciones({
    super.key,
    required this.pedidos,
    required this.recargas,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    final avisos = <_Aviso>[
      for (final pedido in pedidos)
        _Aviso(
          fecha: pedido.fecha,
          titulo: '¡Gracias por tu pedido!',
          descripcion:
              'Tu pedido #${pedido.numero} por ${formatoPrecio(pedido.total)} es una simulación local, sin descuento de billetera.',
          detalle: pedido.productos.join(', '),
          etiqueta: 'COMPRA',
          icono: Icons.shopping_bag_outlined,
          color: AppColors.acento,
        ),
      for (final recarga in recargas)
        _Aviso(
          fecha: recarga.fecha,
          titulo: recarga.titulo,
          descripcion:
              '${formatoCentimos(recarga.centimos)} · ${recarga.descripcion}. Saldo ficticio.',
          etiqueta: 'BILLETERA FICTICIA',
          icono: Icons.account_balance_wallet_outlined,
          color: const Color(0xFF4CDAC2),
        ),
    ]..sort((a, b) => b.fecha.compareTo(a.fecha));

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF202124),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF35363A)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Notificaciones',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: onCerrar,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF45464A)),
          if (avisos.isEmpty)
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 44,
                        color: AppColors.textoSecundario,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No tienes notificaciones',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Aquí aparecerán los avisos de tus compras y recargas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textoSecundario),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: avisos.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0xFF35363A)),
                itemBuilder: (context, index) =>
                    _TarjetaAviso(aviso: avisos[index]),
              ),
            ),
        ],
      ),
    );
  }
}

class _Aviso {
  final DateTime fecha;
  final String titulo;
  final String descripcion;
  final String? detalle;
  final String etiqueta;
  final IconData icono;
  final Color color;

  const _Aviso({
    required this.fecha,
    required this.titulo,
    required this.descripcion,
    this.detalle,
    required this.etiqueta,
    required this.icono,
    required this.color,
  });
}

class _TarjetaAviso extends StatelessWidget {
  final _Aviso aviso;

  const _TarjetaAviso({required this.aviso});

  @override
  Widget build(BuildContext context) {
    final fecha = aviso.fecha.toLocal();
    final fechaTexto =
        '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year} · '
        '${fecha.hour.toString().padLeft(2, '0')}:'
        '${fecha.minute.toString().padLeft(2, '0')}';
    final detalle = aviso.detalle;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: aviso.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(aviso.icono, color: aviso.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      aviso.etiqueta,
                      style: TextStyle(
                        color: aviso.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      fechaTexto,
                      style: const TextStyle(
                        color: AppColors.textoSecundario,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  aviso.titulo,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  aviso.descripcion,
                  style: const TextStyle(
                    color: AppColors.textoSecundario,
                    height: 1.4,
                  ),
                ),
                if (detalle != null && detalle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    detalle,
                    style: const TextStyle(
                      color: AppColors.textoSecundario,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
