import '../models/categoria.dart';
import '../models/producto.dart';

/// Conserva el orden del origen y las reglas de las secciones de la tienda.
List<Producto> productosDeSeccion(Categoria seccion, List<Producto> todos) {
  final productos = switch (seccion.nombre) {
    'Ofertas del día' => todos.where(
      (p) =>
          p.precio != null &&
          p.precioAntes != null &&
          p.precioAntes! > p.precio!,
    ),
    'Más vendidos' => todos.where((p) => p.top),
    'Novedades' => todos.where((p) => p.nuevo),
    _ => todos.where((p) => p.categoria == seccion.nombre),
  };
  return List.unmodifiable(productos);
}
