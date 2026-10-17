import 'item_carrito.dart';

/// Instantánea del carrito. Sus totales se derivan de las líneas inmutables.
final class EstadoCarrito {
  final List<ItemCarrito> items;

  EstadoCarrito({Iterable<ItemCarrito> items = const []})
    : items = List.unmodifiable(items);

  bool get vacio => items.isEmpty;
  int get cantidadTotal => items.fold(0, (s, item) => s + item.cantidad);
  double get total => items.fold(0, (s, item) => s + item.subtotal);
}
