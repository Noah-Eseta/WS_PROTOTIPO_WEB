import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/acceso_compra.dart';
import '../core/app_theme.dart';
import '../core/formato.dart';
import '../providers/carrito_provider.dart';
import '../models/estado_carrito.dart';
import '../services/pedido_service.dart';
import '../widgets/pantalla_carga.dart';
import '../widgets/pie_tienda.dart';
import 'perfil_screen.dart';

const _fondoPanel = Color(0xFF101D30);
const _bordePanel = Color(0xFF214463);

class PagoScreen extends ConsumerStatefulWidget {
  const PagoScreen({super.key});

  @override
  ConsumerState<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends ConsumerState<PagoScreen> {
  String? _metodo;

  Future<void> _pagar() async {
    if (_metodo == null || ref.read(carritoProvider).vacio) return;
    if (!await solicitarSesionParaComprar(context) || !mounted) return;
    final pedido = PedidoService.instancia.registrar(
      ref.read(carritoProvider),
      _metodo!,
      vaciarCarrito: ref.read(carritoProvider.notifier).vaciar,
    );
    Navigator.of(context).pushReplacement(
      RutaConCarga(destino: ConfirmacionPedidoScreen(pedido: pedido)),
    );
  }

  IconData _icono(String metodo) => switch (metodo) {
    'Binance' => Icons.currency_exchange_rounded,
    'VISA' || 'Mastercard' => Icons.credit_card_rounded,
    'Yape' || 'Plin' => Icons.phone_iphone_rounded,
    _ => Icons.account_balance_wallet_outlined,
  };

  String _detalle(String metodo) => switch (metodo) {
    'Binance' => 'Billetera digital',
    'VISA' || 'Mastercard' => 'Tarjeta de crédito o débito',
    'Yape' || 'Plin' => 'Pago con tu celular',
    _ => 'Billetera del dispositivo',
  };

  Widget _opcion(String metodo) {
    final seleccionada = _metodo == metodo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        selected: seleccionada,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: seleccionada ? const Color(0xFF102D4D) : _fondoPanel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: seleccionada ? AppColors.acento : _bordePanel,
              width: seleccionada ? 1.5 : 1,
            ),
            boxShadow: seleccionada
                ? [
                    BoxShadow(
                      color: AppColors.acento.withValues(alpha: .12),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _metodo = metodo),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.acento.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(_icono(metodo), color: AppColors.acento),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metodo,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _detalle(metodo),
                            style: const TextStyle(
                              color: AppColors.textoSecundario,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      seleccionada
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: seleccionada
                          ? AppColors.acento
                          : AppColors.textoSecundario,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _resumen(EstadoCarrito carrito) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF102540), Color(0xFF0B1728)],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _bordePanel),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: AppColors.acento,
              size: 22,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Resumen de compra',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _fila('Productos', '${carrito.cantidadTotal}'),
        const SizedBox(height: 14),
        _fila('Subtotal', formatoPrecio(carrito.total)),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Divider(color: _bordePanel, height: 1),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Total a pagar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatoPrecio(carrito.total),
              style: const TextStyle(
                color: AppColors.acento,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _metodo == null || carrito.vacio ? null : _pagar,
          icon: const Icon(Icons.lock_outline_rounded, size: 19),
          label: const Text('Confirmar pedido'),
        ),
        const SizedBox(height: 14),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppColors.textoSecundario,
              size: 17,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Esta es una simulación. No se realizará ningún cobro.',
                style: TextStyle(
                  color: AppColors.textoSecundario,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _fila(String etiqueta, String valor) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(etiqueta, style: const TextStyle(color: AppColors.textoSecundario)),
      Text(valor),
    ],
  );

  Widget _listaMetodos() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined, color: AppColors.acento),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Métodos de pago',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      for (final metodo in PieTienda.metodos) _opcion(metodo),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final carrito = ref.watch(carritoProvider);
    return Scaffold(
      appBar: _barra('Finalizar compra'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 850;
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth < 600 ? 16 : 32,
                    vertical: constraints.maxWidth < 600 ? 24 : 42,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WEIKANG SHOP  /  PAGO',
                        style: TextStyle(
                          color: AppColors.acento,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Elige cómo pagar',
                        style: TextStyle(
                          fontSize: constraints.maxWidth < 600 ? 30 : 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Selecciona el método que prefieras para completar tu pedido.',
                        style: TextStyle(
                          color: AppColors.textoSecundario,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (horizontal)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _listaMetodos()),
                            const SizedBox(width: 24),
                            SizedBox(width: 340, child: _resumen(carrito)),
                          ],
                        )
                      else ...[
                        _listaMetodos(),
                        const SizedBox(height: 18),
                        _resumen(carrito),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ConfirmacionPedidoScreen extends StatelessWidget {
  final PedidoDemo pedido;

  const ConfirmacionPedidoScreen({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _barra('Pedido confirmado'),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 38,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF102540), Color(0xFF0B1728)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _bordePanel),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.acento.withValues(alpha: .13),
                          border: Border.all(
                            color: AppColors.acento.withValues(alpha: .6),
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 48,
                          color: AppColors.acento,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      '¡Gracias por tu pedido!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tu compra fue registrada. Puedes seguirla en Compras de tu perfil.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textoSecundario,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF091827),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _bordePanel),
                      ),
                      child: Column(
                        children: [
                          _dato('Número de pedido', '#${pedido.numero}'),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 13),
                            child: Divider(height: 1, color: _bordePanel),
                          ),
                          _dato('Método de pago', pedido.metodoPago),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 13),
                            child: Divider(height: 1, color: _bordePanel),
                          ),
                          _dato(
                            'Total',
                            formatoPrecio(pedido.total),
                            destacar: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        RutaConCarga(
                          destino: const PerfilScreen(mostrarCompras: true),
                        ),
                      ),
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('Ver mis compras'),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst),
                      child: const Text('Volver a la tienda'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dato(String etiqueta, String valor, {bool destacar = false}) => Row(
    children: [
      Expanded(
        child: Text(
          etiqueta,
          style: const TextStyle(color: AppColors.textoSecundario),
        ),
      ),
      Text(
        valor,
        style: TextStyle(
          color: destacar ? AppColors.acento : Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: destacar ? 20 : 14,
        ),
      ),
    ],
  );
}

AppBar _barra(String titulo) => AppBar(
  title: Text(titulo),
  backgroundColor: const Color(0xFF0B1728),
  surfaceTintColor: Colors.transparent,
  bottom: const PreferredSize(
    preferredSize: Size.fromHeight(1),
    child: Divider(height: 1, color: _bordePanel),
  ),
);
