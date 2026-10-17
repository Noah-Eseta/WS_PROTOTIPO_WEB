import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/estado_carrito.dart';
import '../models/item_carrito.dart';
import '../models/producto.dart';

final carritoProvider = NotifierProvider<CarritoNotifier, EstadoCarrito>(
  CarritoNotifier.new,
);

/// Único propietario del carrito; se conserva durante toda la vida del scope.
class CarritoNotifier extends Notifier<EstadoCarrito> {
  static const maxPorProducto = 99;

  @override
  EstadoCarrito build() => EstadoCarrito();

  void agregar(Producto producto) {
    if (!producto.disponible) return;
    final indice = state.items.indexWhere(
      (item) => item.producto.nombre == producto.nombre,
    );
    if (indice == -1) {
      state = EstadoCarrito(items: [...state.items, ItemCarrito(producto)]);
    } else {
      cambiarCantidad(producto.nombre, 1);
    }
  }

  void cambiarCantidad(String nombre, int delta) {
    final indice = state.items.indexWhere(
      (item) => item.producto.nombre == nombre,
    );
    if (indice == -1) return;
    final item = state.items[indice];
    final nueva = item.cantidad + delta;
    if (nueva <= 0) {
      quitar(nombre);
    } else if (nueva <= maxPorProducto && nueva != item.cantidad) {
      final items = [...state.items];
      items[indice] = item.copyWith(cantidad: nueva);
      state = EstadoCarrito(items: items);
    }
  }

  void quitar(String nombre) {
    final items = state.items
        .where((item) => item.producto.nombre != nombre)
        .toList();
    if (items.length != state.items.length) state = EstadoCarrito(items: items);
  }

  void vaciar() {
    if (!state.vacio) state = EstadoCarrito();
  }
}
