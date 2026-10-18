import 'producto.dart';

/// Línea inmutable. La clave local nunca se utiliza como identificador remoto.
final class ItemCarrito {
  final Producto producto;
  final int cantidad;
  final bool persistente;
  final int? precioCentimos;
  factory ItemCarrito(
    Producto producto, {
    int cantidad = 1,
    bool persistente = false,
    int? precioCentimos,
  }) => ItemCarrito._(
    producto.copiaInmutable(),
    cantidad,
    persistente,
    precioCentimos ??
        (producto.precio == null ? null : (producto.precio! * 100).round()),
  );
  const ItemCarrito._(
    this.producto,
    this.cantidad,
    this.persistente,
    this.precioCentimos,
  );
  String get clave => persistente
      ? 'remoto:${producto.id!}'
      : producto.sincronizable
      ? 'local:${producto.id!}'
      : producto.nombre;
  ItemCarrito copyWith({int? cantidad}) => ItemCarrito._(
    producto,
    cantidad ?? this.cantidad,
    persistente,
    precioCentimos,
  );
  int? get subtotalCentimos =>
      precioCentimos == null ? null : precioCentimos! * cantidad;
  double get subtotal => (subtotalCentimos ?? 0) / 100;
}
