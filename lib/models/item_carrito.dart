import 'producto.dart';

class ItemCarrito {
  final Producto producto;
  int cantidad;

  ItemCarrito(this.producto, {this.cantidad = 1});

  double get subtotal => (producto.precio ?? 0) * cantidad;
}
