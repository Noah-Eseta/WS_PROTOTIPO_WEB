import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formato.dart';
import '../services/pedido_service.dart';

const _fondoPanel = Color(0xFF101D30);
const _bordePanel = Color(0xFF214463);
const _textoSuave = Color(0xFFACC0DA);

/// Resumen visual de la cuenta. Los datos y las acciones llegan desde PerfilScreen.
class PerfilResumen extends StatelessWidget {
  final String nombre;
  final double saldo;
  final int puntos;
  final List<PedidoDemo> pedidos;
  final VoidCallback onAgregarSaldo;
  final VoidCallback onTransacciones;
  final VoidCallback onCompras;
  final VoidCallback onSaldo;
  final VoidCallback onRewards;
  final VoidCallback onCuenta;
  final VoidCallback onTienda;

  const PerfilResumen({
    super.key,
    required this.nombre,
    required this.saldo,
    required this.puntos,
    required this.pedidos,
    required this.onAgregarSaldo,
    required this.onTransacciones,
    required this.onCompras,
    required this.onSaldo,
    required this.onRewards,
    required this.onCuenta,
    required this.onTienda,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen',
                      style: TextStyle(
                        fontSize: 40,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gestiona tu cuenta y accede rápidamente a todo en WEIKANG SHOP.',
                      style: TextStyle(color: _textoSuave, fontSize: 15),
                    ),
                  ],
                ),
              ),
              if (constraints.maxWidth >= 930) ...[
                const SizedBox(width: 24),
                InkWell(
                  onTap: onRewards,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tu experiencia\nempieza aquí',
                          style: TextStyle(color: _textoSuave, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 112,
                          child: LinearProgressIndicator(
                            value: (puntos / 3000).clamp(0.0, 1.0),
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 28),
        _hero(),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final lateral = Column(
              children: [
                _estadistica(
                  titulo: 'Compras',
                  valor: '${pedidos.length}',
                  detalle: 'Pedidos realizados',
                  icono: Icons.shopping_bag_outlined,
                  onTap: onCompras,
                ),
                const SizedBox(height: 14),
                _estadistica(
                  titulo: 'Billetera',
                  valor: formatoPrecio(saldo),
                  detalle: 'Saldo disponible',
                  icono: Icons.account_balance_wallet_outlined,
                  onTap: onSaldo,
                ),
                const SizedBox(height: 14),
                _estadistica(
                  titulo: 'WEIKANG REWARDS',
                  valor: '$puntos / 3000 puntos',
                  detalle: 'Sigue comprando y gana más',
                  icono: Icons.card_giftcard_outlined,
                  onTap: onRewards,
                  morado: true,
                ),
              ],
            );
            if (constraints.maxWidth < 900) {
              return Column(
                children: [_reciente(), const SizedBox(height: 14), lateral],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: _reciente()),
                const SizedBox(width: 18),
                Expanded(flex: 3, child: lateral),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final accesos = [
              _acceso(
                titulo: 'Transacciones',
                detalle: 'Ver movimientos de pago y detalles de tu historial.',
                icono: Icons.credit_card_outlined,
                onTap: onTransacciones,
              ),
              _acceso(
                titulo: 'Mi cuenta',
                detalle: 'Editar datos del perfil, seguridad y preferencias.',
                icono: Icons.settings_outlined,
                onTap: onCuenta,
                morado: true,
              ),
            ];
            return constraints.maxWidth >= 700
                ? Row(
                    children: [
                      Expanded(child: accesos[0]),
                      const SizedBox(width: 16),
                      Expanded(child: accesos[1]),
                    ],
                  )
                : Column(
                    children: [
                      accesos[0],
                      const SizedBox(height: 12),
                      accesos[1],
                    ],
                  );
          },
        ),
      ],
    );
  }

  Widget _hero() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 950;
        return Container(
          constraints: BoxConstraints(minHeight: compacto ? 0 : 266),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1465A0)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/Banners/perfil_billetera.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: compacto
                          ? const [Color(0xED08182C), Color(0xA608182C)]
                          : const [
                              Color(0xF008182C),
                              Color(0xD908182C),
                              Color(0x3308182C),
                            ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(compacto ? 22 : 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'PANEL DE CUENTA',
                      style: TextStyle(
                        color: Color(0xFF28B9FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'Hola, $nombre 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compacto ? 28 : 36,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Aquí tienes un resumen de tu actividad en WEIKANG SHOP.',
                      style: TextStyle(fontSize: 14, color: Color(0xFFE0ECFA)),
                    ),
                    const SizedBox(height: 24),
                    if (compacto) ...[
                      _balance(),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _accionesHero(),
                      ),
                    ] else
                      Row(
                        children: [
                          SizedBox(width: 390, child: _balance()),
                          const SizedBox(width: 18),
                          Wrap(spacing: 10, children: _accionesHero()),
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

  Widget _balance() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
    decoration: BoxDecoration(
      color: const Color(0xCC112742),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF24537C)),
    ),
    child: Row(
      children: [
        const Icon(Icons.toll_outlined, color: AppColors.acento, size: 32),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SALDO DISPONIBLE',
              style: TextStyle(
                color: _textoSuave,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatoPrecio(saldo),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ],
    ),
  );

  List<Widget> _accionesHero() => [
    FilledButton.icon(
      onPressed: onAgregarSaldo,
      icon: const Icon(Icons.add),
      label: const Text('Agregar saldo'),
    ),
    OutlinedButton.icon(
      onPressed: onTransacciones,
      icon: const Icon(Icons.credit_card_outlined),
      label: const Text('Ver transacciones'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        backgroundColor: const Color(0x990C2039),
        side: const BorderSide(color: Color(0xFF32618C)),
      ),
    ),
  ];

  Widget _reciente() {
    return Container(
      constraints: const BoxConstraints(minHeight: 360),
      decoration: _decoracionPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 16, 14),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.acento,
                  size: 25,
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Comprado recientemente',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton.icon(
                  onPressed: onCompras,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Ver todos'),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: _bordePanel,
          ),
          if (pedidos.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/Banners/perfil_caja_vacia.png',
                    width: 116,
                    height: 116,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tu próxima compra empieza aquí',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Explora el catálogo y encuentra tu favorito.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _textoSuave, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onTienda,
                    icon: const Icon(Icons.shopping_cart_outlined, size: 17),
                    label: const Text('Ir a la tienda'),
                  ),
                ],
              ),
            )
          else
            for (final pedido in pedidos.take(3))
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 22),
                leading: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.acento,
                ),
                title: Text('Pedido #${pedido.numero}'),
                subtitle: Text(
                  pedido.productos.join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  formatoPrecio(pedido.total),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                onTap: onCompras,
              ),
        ],
      ),
    );
  }

  Widget _estadistica({
    required String titulo,
    required String valor,
    required String detalle,
    required IconData icono,
    required VoidCallback onTap,
    bool morado = false,
  }) {
    final color = morado ? const Color(0xFFAB6BFF) : AppColors.acento;
    return Material(
      color: _fondoPanel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _bordePanel),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 110,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icono, color: color, size: 27),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        valor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        detalle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textoSuave,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: _textoSuave, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _acceso({
    required String titulo,
    required String detalle,
    required IconData icono,
    required VoidCallback onTap,
    bool morado = false,
  }) {
    final color = morado ? const Color(0xFFAD6DFF) : AppColors.acento;
    return Material(
      color: morado ? const Color(0xFF171B42) : const Color(0xFF0B2B4D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.45)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 102,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Icon(icono, color: color, size: 26),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detalle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textoSuave,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _decoracionPanel() => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF101D30), Color(0xFF10243D)],
    ),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: _bordePanel),
  );
}
