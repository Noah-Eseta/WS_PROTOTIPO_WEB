import 'producto.dart';

/// Línea inmutable, incluida la copia del producto y de sus colores.
final class ItemCarrito {
  final Producto producto;
  final int cantidad;

  factory ItemCarrito(Producto producto, {int cantidad = 1}) => ItemCarrito._(
    Producto(
      nombre: producto.nombre,
      subtitulo: producto.subtitulo,
      categoria: producto.categoria,
      colores: List.unmodifiable(producto.colores),
      entrega: producto.entrega,
      tipo: producto.tipo,
      precio: producto.precio,
      precioAntes: producto.precioAntes,
      top: producto.top,
      nuevo: producto.nuevo,
      logo: producto.logo,
      banner: producto.banner,
    ),
    cantidad,
  );

  const ItemCarrito._(this.producto, this.cantidad);

  ItemCarrito copyWith({int? cantidad}) =>
      ItemCarrito._(producto, cantidad ?? this.cantidad);

  double get subtotal => (producto.precio ?? 0) * cantidad;
}
