import 'package:prototipo_app/models/producto.dart';
import 'package:prototipo_app/repositories/catalogo_repository.dart';
import 'package:prototipo_app/services/producto_service.dart';

class CatalogoTestRepository implements CatalogoRepository {
  final Future<List<Producto>> Function() cargar;
  int llamadas = 0;

  CatalogoTestRepository({Future<List<Producto>> Function()? cargar})
    : cargar = cargar ?? ProductoService().obtenerProductos;

  @override
  Future<List<Producto>> obtenerProductos() {
    llamadas++;
    return cargar();
  }
}
