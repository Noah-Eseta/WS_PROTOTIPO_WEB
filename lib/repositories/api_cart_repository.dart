import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/http/error_carrito.dart';
import '../models/dto/carrito_api_dto.dart';
import 'cart_repository.dart';

final class ApiCartRepository implements CartRepository {
  final Dio cliente;
  ApiCartRepository(this.cliente);
  Future<Map<String, dynamic>> _solicitar(
    String token,
    String ruta, {
    String metodo = 'GET',
    Object? datos,
    int? version,
  }) async {
    final base = Uri.tryParse(cliente.options.baseUrl);
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        (base.path.isNotEmpty && base.path != '/')) {
      throw const ErrorCarrito(
        'El carrito remoto requiere un origen HTTPS seguro.',
      );
    }
    final modifica = metodo != 'GET';
    try {
      final response = await cliente.request<String>(
        '/api/v1/cart$ruta',
        data: datos,
        options: Options(
          method: metodo,
          responseType: ResponseType.plain,
          followRedirects: false,
          contentType: Headers.jsonContentType,
          headers: {
            'Authorization': 'Bearer $token',
            if (version != null) 'X-Cart-Version': '$version',
          },
        ),
      );
      if (response.statusCode != 200) throw const FormatException();
      final decoded = jsonDecode(response.data ?? '');
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      return decoded;
    } on DioException catch (error) {
      final safe = ErrorCarrito.desdeDio(error, modifica: modifica);
      String? code;
      try {
        final raw = error.response?.data;
        final decoded = raw is String ? jsonDecode(raw) : raw;
        if (decoded is Map &&
            [
              'CART_VERSION_CONFLICT',
              'CART_MERGE_CONTENT_CONFLICT',
            ].contains(decoded['code'])) {
          code = decoded['code'] as String;
        }
      } on FormatException {
        /* Se conserva el mensaje HTTP seguro. */
      }
      throw ErrorCarrito(
        safe.mensaje,
        estadoHttp: safe.estadoHttp,
        codigo: code,
        resultadoIncierto: safe.resultadoIncierto,
      );
    } on FormatException {
      throw ErrorCarrito(
        'El servidor devolvió un carrito inesperado. Vuelve a consultarlo.',
        resultadoIncierto: modifica,
      );
    }
  }

  Future<CarritoApiDto> _carrito(
    String token,
    String ruta, {
    String metodo = 'GET',
    Object? datos,
    int? version,
  }) async {
    final json = await _solicitar(
      token,
      ruta,
      metodo: metodo,
      datos: datos,
      version: version,
    );
    try {
      return CarritoApiDto.fromJson(json);
    } on FormatException {
      throw ErrorCarrito(
        'La respuesta del carrito no es válida. Vuelve a consultarlo.',
        resultadoIncierto: metodo != 'GET',
      );
    }
  }

  void _validarId(String id) {
    if (!uuidValido(id)) {
      throw const ErrorCarrito('El producto no tiene un UUID válido.');
    }
  }

  @override
  Future<CarritoApiDto> consultar(String token) => _carrito(token, '');
  @override
  Future<CarritoApiDto> establecer(
    String token,
    String productoId,
    int cantidad,
    int version,
  ) {
    _validarId(productoId);
    return _carrito(
      token,
      '/items/${productoId.toLowerCase()}',
      metodo: 'PUT',
      datos: {'quantity': cantidad},
      version: version,
    );
  }

  @override
  Future<CarritoApiDto> eliminar(String token, String productoId, int version) {
    _validarId(productoId);
    return _carrito(
      token,
      '/items/${productoId.toLowerCase()}',
      metodo: 'DELETE',
      version: version,
    );
  }

  @override
  Future<CarritoApiDto> vaciar(String token, int version) =>
      _carrito(token, '', metodo: 'DELETE', version: version);
  @override
  Future<ComprobanteFusion> fusionar(
    String token,
    String operacion,
    List<({String id, int cantidad})> items,
    int version,
  ) async {
    try {
      return ComprobanteFusion.fromJson(
        await _solicitar(
          token,
          '/merge',
          metodo: 'POST',
          datos: {
            'operation_id': operacion,
            'items': [
              for (final item in items)
                {'product_id': item.id, 'quantity': item.cantidad},
            ],
          },
          version: version,
        ),
      );
    } on FormatException {
      throw const ErrorCarrito(
        'No se pudo verificar la fusión. Reintenta con el mismo lote.',
        resultadoIncierto: true,
      );
    }
  }
}
