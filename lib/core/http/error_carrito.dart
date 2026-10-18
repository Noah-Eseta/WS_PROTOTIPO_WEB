import 'package:dio/dio.dart';

final class ErrorCarrito implements Exception {
  final String mensaje;
  final int? estadoHttp;
  final String? codigo;
  final bool resultadoIncierto;
  const ErrorCarrito(
    this.mensaje, {
    this.estadoHttp,
    this.codigo,
    this.resultadoIncierto = false,
  });
  factory ErrorCarrito.desdeDio(DioException error, {required bool modifica}) {
    final status = error.response?.statusCode;
    return ErrorCarrito(
      switch (status) {
        401 => 'Tu sesión ha caducado. Inicia sesión nuevamente.',
        404 => 'El producto ya no está disponible en el catálogo.',
        409 =>
          'El carrito cambió. Revisa el estado actualizado antes de continuar.',
        422 => 'No se pudo aplicar la selección. Revisa disponibilidad y el máximo de 99 unidades.',
        429 => 'Demasiadas solicitudes. Espera un momento antes de reintentar.',
        _ => 'No se pudo sincronizar. Comprueba tu conexión y vuelve a consultar el carrito.',
      },
      estadoHttp: status,
      resultadoIncierto: modifica && (status == null || status >= 500),
    );
  }
  @override
  String toString() => mensaje;
}
