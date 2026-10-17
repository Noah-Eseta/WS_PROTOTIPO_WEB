import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/http/error_api.dart';
import '../models/dto/producto_api_dto.dart';
import '../models/producto.dart';
import 'catalogo_repository.dart';

final class ApiCatalogoRepository implements CatalogoRepository {
  final Dio _cliente;

  ApiCatalogoRepository(this._cliente);

  @override
  Future<List<Producto>> obtenerProductos() async {
    try {
      final respuesta = await _cliente.get<String>(
        '/api/v1/products',
        options: Options(responseType: ResponseType.plain),
      );
      if (respuesta.statusCode != 200) {
        throw ErrorApi(TipoErrorApi.http, estadoHttp: respuesta.statusCode);
      }
      final json = jsonDecode(respuesta.data ?? '');
      if (json is! Map<String, dynamic> || json['data'] is! List) {
        throw const FormatException('Se esperaba un catálogo en data.');
      }
      // El orden de la respuesta es el orden de presentación del backend.
      return List.unmodifiable(
        (json['data'] as List).map(
          (producto) => ProductoApiDto.fromJson(producto).toProducto(),
        ),
      );
    } on DioException catch (error) {
      throw ErrorApi.desdeDio(error);
    } on FormatException {
      throw const ErrorApi(TipoErrorApi.respuestaInvalida);
    }
  }
}
