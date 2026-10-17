import 'package:flutter/foundation.dart';

import '../models/item_carrito.dart';
import '../models/producto.dart';

/// Estado del carrito compartido por toda la app. Es local; cuando el
/// backend Laravel lo requiera, se sincroniza desde aquí.
class CarritoService extends ChangeNotifier {
  CarritoService._();
  static final instancia = CarritoService._();

  static const maxPorProducto = 99;

  final List<ItemCarrito> _items = [];

  List<ItemCarrito> get items => List.unmodifiable(_items);
  bool get vacio => _items.isEmpty;
  int get cantidadTotal => _items.fold(0, (s, i) => s + i.cantidad);
  double get total => _items.fold(0, (s, i) => s + i.subtotal);

  void agregar(Producto producto) {
    if (!producto.disponible) return;
    final i = _items.indexWhere((e) => e.producto.nombre == producto.nombre);
    if (i == -1) {
      _items.add(ItemCarrito(producto));
    } else if (_items[i].cantidad < maxPorProducto) {
      _items[i].cantidad++;
    }
    notifyListeners();
  }

  void cambiarCantidad(ItemCarrito item, int delta) {
    final nueva = item.cantidad + delta;
    if (nueva <= 0) {
      _items.remove(item);
    } else if (nueva <= maxPorProducto) {
      item.cantidad = nueva;
    }
    notifyListeners();
  }

  void quitar(ItemCarrito item) {
    _items.remove(item);
    notifyListeners();
  }

  void vaciar() {
    _items.clear();
    notifyListeners();
  }
}
