import '../models/producto.dart';

/// Origen del catálogo, independiente del transporte y de la presentación.
abstract interface class CatalogoRepository {
  Future<List<Producto>> obtenerProductos();
}
