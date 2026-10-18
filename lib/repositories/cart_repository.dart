import '../models/dto/carrito_api_dto.dart';

abstract interface class CartRepository {
  Future<CarritoApiDto> consultar(String token);
  Future<CarritoApiDto> establecer(
    String token,
    String productoId,
    int cantidad,
    int version,
  );
  Future<CarritoApiDto> eliminar(String token, String productoId, int version);
  Future<CarritoApiDto> vaciar(String token, int version);
  Future<ComprobanteFusion> fusionar(
    String token,
    String operacion,
    List<({String id, int cantidad})> items,
    int version,
  );
}
