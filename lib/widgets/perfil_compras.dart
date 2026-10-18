import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formato.dart';
import '../services/pedido_service.dart';
import 'perfil_componentes.dart';

class PerfilCompras extends StatefulWidget {
  final List<PedidoDemo> pedidos;
  final VoidCallback onTienda;

  const PerfilCompras({
    super.key,
    required this.pedidos,
    required this.onTienda,
  });

  @override
  State<PerfilCompras> createState() => _PerfilComprasState();
}

class _PerfilComprasState extends State<PerfilCompras> {
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final consulta = _busqueda.text.trim().toLowerCase();
    final pedidos =
        widget.pedidos
            .where(
              (pedido) =>
                  'pedido #${pedido.numero} ${pedido.metodoPago} ${pedido.productos.join(' ')}'
                      .toLowerCase()
                      .contains(consulta),
            )
            .toList()
          ..sort((a, b) => b.fecha.compareTo(a.fecha));
    final total = widget.pedidos.fold<double>(
      0,
      (suma, pedido) => suma + pedido.total,
    );
    final puntos = widget.pedidos.fold<int>(
      0,
      (suma, pedido) => suma + (pedido.total * 10).floor(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PerfilEncabezado(
          titulo: 'Mis compras',
          descripcion: 'Pedidos de demostración de esta sesión; no son compras reales de tu cuenta.',
          icono: Icons.shopping_bag_outlined,
          etiqueta: 'GESTIÓN',
        ),
        PerfilMetricas(
          children: [
            PerfilMetrica(
              titulo: 'Pedidos realizados',
              valor: '${widget.pedidos.length}',
              detalle: 'Tu historial de compras',
              icono: Icons.shopping_bag_outlined,
            ),
            PerfilMetrica(
              titulo: 'Total en compras',
              valor: formatoPrecio(total),
              detalle: 'Pagos de demostración',
              icono: Icons.payments_outlined,
            ),
            PerfilMetrica(
              titulo: 'Puntos acumulados',
              valor: '$puntos',
              detalle: 'Tus compras suman recompensas',
              icono: Icons.card_giftcard_outlined,
              color: const Color(0xFFAF83FF),
            ),
          ],
        ),
        const SizedBox(height: 24),
        PerfilPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final titulo = Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.acento,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Historial de pedidos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      PerfilEtiqueta(texto: '${widget.pedidos.length}'),
                    ],
                  );
                  final buscar = TextField(
                    controller: _busqueda,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Buscar pedido o producto',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: PerfilEstilo.textoSuave,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: consulta.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpiar búsqueda',
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(_busqueda.clear),
                            ),
                    ),
                  );
                  if (widget.pedidos.isEmpty) return titulo;
                  if (constraints.maxWidth < 720) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [titulo, const SizedBox(height: 18), buscar],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: titulo),
                      const SizedBox(width: 24),
                      SizedBox(width: 290, child: buscar),
                    ],
                  );
                },
              ),
              const Divider(height: 36, color: PerfilEstilo.borde),
              if (widget.pedidos.isEmpty)
                PerfilVacio(
                  icono: Icons.shopping_bag_outlined,
                  imagen: 'assets/images/Banners/perfil_caja_vacia.png',
                  titulo: 'Tu próxima compra empieza aquí',
                  descripcion: 'Explora el catálogo y encuentra tu favorito. Tus pedidos aparecerán en este espacio.',
                  accion: FilledButton.icon(
                    onPressed: widget.onTienda,
                    icon: const Icon(Icons.shopping_cart_outlined, size: 19),
                    label: const Text('Ir a la tienda'),
                  ),
                )
              else if (pedidos.isEmpty)
                PerfilVacio(
                  icono: Icons.search_off_outlined,
                  titulo: 'Sin resultados',
                  descripcion: 'Prueba con otro producto, número de pedido o método de pago.',
                  accion: TextButton(
                    onPressed: () => setState(_busqueda.clear),
                    child: const Text('Ver todos los pedidos'),
                  ),
                )
              else ...[
                for (final pedido in pedidos) ...[
                  _PedidoCard(key: ValueKey(pedido.numero), pedido: pedido),
                  if (pedido != pedidos.last) const SizedBox(height: 12),
                ],
                const SizedBox(height: 16),
                Text(
                  '${pedidos.length} de ${widget.pedidos.length} pedidos · Más recientes primero',
                  style: const TextStyle(
                    color: PerfilEstilo.textoSuave,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PedidoCard extends StatelessWidget {
  final PedidoDemo pedido;

  const _PedidoCard({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF0A182B),
      border: Border.all(color: PerfilEstilo.borde),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: AppColors.acento,
        collapsedIconColor: PerfilEstilo.textoSuave,
        shape: const RoundedRectangleBorder(),
        collapsedShape: const RoundedRectangleBorder(),
        title: LayoutBuilder(
          builder: (context, constraints) {
            final detalle = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedido #${pedido.numero.toString().padLeft(4, '0')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_fecha(pedido.fecha)} · ${pedido.metodoPago}',
                  style: const TextStyle(
                    color: PerfilEstilo.textoSuave,
                    fontSize: 12,
                  ),
                ),
              ],
            );
            final importe = Column(
              crossAxisAlignment: constraints.maxWidth >= 480
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  formatoPrecio(pedido.total),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const PerfilEtiqueta(
                  texto: 'Pago simulado',
                  color: Color(0xFF52D9B0),
                ),
              ],
            );
            if (constraints.maxWidth < 480) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [detalle, const SizedBox(height: 12), importe],
              );
            }
            return Row(
              children: [
                const PerfilIcono(icono: Icons.shopping_bag_outlined),
                const SizedBox(width: 16),
                Expanded(child: detalle),
                const SizedBox(width: 12),
                importe,
              ],
            );
          },
        ),
        children: [
          const Divider(color: PerfilEstilo.borde, height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'PRODUCTOS DEL PEDIDO',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1,
                color: PerfilEstilo.textoSuave,
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final producto in pedido.productos)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 18,
                    color: AppColors.acento,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(producto)),
                ],
              ),
            ),
        ],
      ),
    ),
  );

  String _fecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
}
