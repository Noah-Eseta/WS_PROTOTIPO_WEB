import 'package:dio/dio.dart';

enum TipoErrorApi {
  conexion,
  tiempoEspera,
  http,
  respuestaInvalida,
  seguridad,
  cancelado,
}

final class ErrorApi implements Exception {
  final TipoErrorApi tipo;
  final int? estadoHttp;

  const ErrorApi(this.tipo, {this.estadoHttp});

  factory ErrorApi.desdeDio(DioException error) => switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.transformTimeout => const ErrorApi(
      TipoErrorApi.tiempoEspera,
    ),
    DioExceptionType.badResponse => ErrorApi(
      TipoErrorApi.http,
      estadoHttp: error.response?.statusCode,
    ),
    DioExceptionType.badCertificate => const ErrorApi(TipoErrorApi.seguridad),
    DioExceptionType.cancel => const ErrorApi(TipoErrorApi.cancelado),
    _ => ErrorApi(
      error.error is FormatException
          ? TipoErrorApi.respuestaInvalida
          : TipoErrorApi.conexion,
    ),
  };

  String get mensaje => switch (tipo) {
    TipoErrorApi.conexion =>
      'No se pudo conectar con el servidor. Comprueba tu conexión.',
    TipoErrorApi.tiempoEspera => 'El servidor tardó demasiado en responder.',
    TipoErrorApi.http =>
      'El servidor no pudo entregar el catálogo'
          '${estadoHttp == null ? '.' : ' (HTTP $estadoHttp).'}',
    TipoErrorApi.respuestaInvalida =>
      'El servidor devolvió un catálogo con formato inesperado.',
    TipoErrorApi.seguridad =>
      'No se pudo establecer una conexión segura con el servidor.',
    TipoErrorApi.cancelado => 'La solicitud del catálogo fue cancelada.',
  };

  @override
  String toString() => mensaje;
}
