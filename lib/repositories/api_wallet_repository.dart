import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/http/error_billetera.dart';
import '../models/billetera.dart';
import '../models/dto/wallet_api_dto.dart';
import 'wallet_repository.dart';

final class ApiWalletRepository implements WalletRepository {
  final Dio cliente;
  ApiWalletRepository(this.cliente);

  Future<T> _pedir<T>(
    String token,
    String ruta,
    T Function(Object?) convertir, {
    Map<String, dynamic>? consulta,
    Map<String, dynamic>? datos,
  }) async {
    final uri = Uri.tryParse(cliente.options.baseUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw ErrorBilletera('La billetera requiere una conexión HTTPS segura.');
    }
    final escritura = datos != null;
    try {
      final respuesta = await cliente.request<String>(
        '/api/v1$ruta',
        data: datos,
        queryParameters: consulta,
        options: Options(
          method: escritura ? 'POST' : 'GET',
          responseType: ResponseType.plain,
          contentType: Headers.jsonContentType,
          followRedirects: false,
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      if (respuesta.statusCode != 200) throw const FormatException();
      return convertir(jsonDecode(respuesta.data ?? ''));
    } on DioException catch (error) {
      final estado = error.response?.statusCode;
      String? codigo;
      final campos = <String, List<String>>{};
      try {
        final raw = error.response?.data;
        final json = raw is String ? jsonDecode(raw) : raw;
        if (json is Map) {
          if (json['code'] is String &&
              RegExp(r'^[A-Z_]{1,80}$').hasMatch(json['code'])) {
            codigo = json['code'] as String;
          }
          // Mensajes locales: nunca reflejar cuerpos arbitrarios del servidor.
          if (estado == 422 && json['errors'] is Map) {
            for (final campo in [
              'amount_cents',
              'reason',
              'operation_id',
              'payload',
            ]) {
              if ((json['errors'] as Map).containsKey(campo)) {
                campos[campo] = [
                  switch (campo) {
                    'amount_cents' => 'Ingresa entre S/ 0.01 y S/ 10,000.00.',
                    'reason' => 'La justificación es obligatoria y admite hasta 500 caracteres.',
                    _ => 'Revisa los datos de la operación.',
                  },
                ];
              }
            }
          }
        }
      } on FormatException {
        /* Se conserva el mensaje seguro. */
      }
      throw ErrorBilletera(
        switch (estado) {
          401 => 'Tu sesión ha caducado. Inicia sesión nuevamente.',
          403 => 'No tienes permiso para administrar billeteras.',
          404 => 'No se encontró la cuenta solicitada.',
          409 => 'El crédito no se pudo aplicar. Revisa el conflicto y vuelve a consultar el saldo.',
          422 => 'Revisa el importe y la justificación del crédito ficticio.',
          429 => 'Demasiadas solicitudes. Espera antes de reintentar.',
          _ => 'No se pudo consultar o confirmar la billetera. Comprueba tu conexión.',
        },
        estadoHttp: estado,
        codigo: codigo,
        campos: campos,
        resultadoIncierto:
            escritura && ![400, 401, 403, 404, 409, 422, 429].contains(estado),
      );
    } on FormatException {
      throw ErrorBilletera(
        'La respuesta de la billetera no es válida. Vuelve a consultar.',
        resultadoIncierto: escritura,
      );
    }
  }

  String _ruta(int? usuario) {
    if (usuario != null && usuario < 1) {
      throw ErrorBilletera('La cuenta no es válida.');
    }
    return usuario == null ? '/wallet' : '/admin/wallets/$usuario';
  }

  @override
  Future<Billetera> consultar(String token, {int? usuario}) => _pedir(
    token,
    _ruta(usuario),
    (json) => billeteraDesdeJson(objetoWallet(json)['data']),
  );
  @override
  Future<PaginaBilletera<MovimientoBilletera>> movimientos(
    String token, {
    int? usuario,
    String? cursor,
  }) => _pedir(
    token,
    '${_ruta(usuario)}/transactions',
    (json) => paginaWalletDesdeJson(json, movimientoDesdeJson),
    consulta: {'per_page': 20, 'cursor': ?cursor},
  );
  @override
  Future<PaginaBilletera<UsuarioBilletera>> usuarios(
    String token, {
    String? cursor,
    int porPagina = 20,
  }) => _pedir(
    token,
    '/admin/wallets',
    (json) => paginaWalletDesdeJson(json, usuarioBilleteraDesdeJson),
    consulta: {'per_page': porPagina, 'cursor': ?cursor},
  );
  @override
  Future<ReciboCredito> acreditar(String token, IntentoCredito intento) {
    try {
      uuidWallet(intento.operacion);
    } on FormatException {
      throw ErrorBilletera('El identificador de operación no es válido.');
    }
    if (intento.centimos < 1 ||
        intento.centimos > 1000000 ||
        intento.justificacion.trim().isEmpty ||
        intento.justificacion.runes.length > 500) {
      throw ErrorBilletera(
        'Revisa el importe y la justificación del crédito ficticio.',
      );
    }
    return _pedir(
      token,
      '${_ruta(intento.destinatario)}/credits',
      (json) => reciboCreditoDesdeJson(objetoWallet(json)['data']),
      datos: {
        'operation_id': intento.operacion,
        'amount_cents': intento.centimos,
        'reason': intento.justificacion,
      },
    );
  }
}
