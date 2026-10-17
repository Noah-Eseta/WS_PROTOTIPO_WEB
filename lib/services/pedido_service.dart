import 'package:flutter/foundation.dart';

import '../models/estado_carrito.dart';
import 'sesion_service.dart';

class PedidoDemo {
  final int numero;
  final DateTime fecha;
  final String metodoPago;
  final List<String> productos;
  final double total;

  const PedidoDemo({
    required this.numero,
    required this.fecha,
    required this.metodoPago,
    required this.productos,
    required this.total,
  });
}

/// Pedidos de demostración: se conservan mientras la aplicación siga abierta.
class PedidoService extends ChangeNotifier {
  PedidoService._();
  static final instancia = PedidoService._();

  final List<PedidoDemo> _pedidos = [];
  List<PedidoDemo> get pedidos => List.unmodifiable(_pedidos);

  PedidoDemo registrar(
    EstadoCarrito carrito,
    String metodoPago, {
    required VoidCallback vaciarCarrito,
  }) {
    if (!SesionService.instancia.iniciada) {
      throw StateError('Debes iniciar sesión para comprar');
    }
    if (carrito.vacio) throw StateError('El carrito está vacío');

    final pedido = PedidoDemo(
      numero: _pedidos.length + 1,
      fecha: DateTime.now(),
      metodoPago: metodoPago,
      productos: List.unmodifiable([
        for (final item in carrito.items)
          '${item.producto.nombre} x${item.cantidad}',
      ]),
      total: carrito.total,
    );
    _pedidos.insert(0, pedido);
    vaciarCarrito();
    notifyListeners();
    return pedido;
  }
}
