import 'package:dio/dio.dart';

final class ErrorAutenticacion implements Exception {
  final String mensaje;
  final int? estadoHttp;
  final Map<String, List<String>> campos;
  final int? reintentarEnSegundos;

  ErrorAutenticacion(
    this.mensaje, {
    this.estadoHttp,
    Map<String, List<String>> campos = const {},
    this.reintentarEnSegundos,
  }) : campos = Map.unmodifiable(
         campos.map(
           (key, value) => MapEntry(key, List<String>.unmodifiable(value)),
         ),
       );

  factory ErrorAutenticacion.desdeDio(DioException error) {
    final status = error.response?.statusCode;
    return ErrorAutenticacion(switch (status) {
      401 => 'Correo o contraseña incorrectos, o la sesión ha caducado.',
      422 => 'Revisa los datos del formulario.',
      429 => 'Demasiados intentos. Inténtalo de nuevo más tarde.',
      _ => switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.transformTimeout =>
          'El servidor tardó demasiado en responder.',
        DioExceptionType.badResponse => 'No se pudo completar la solicitud.',
        DioExceptionType.badCertificate =>
          'No se pudo establecer una conexión segura.',
        _ =>
          'No se pudo conectar. Comprueba tu conexión e inténtalo nuevamente.',
      },
    }, estadoHttp: status);
  }

  @override
  String toString() => mensaje;
}
