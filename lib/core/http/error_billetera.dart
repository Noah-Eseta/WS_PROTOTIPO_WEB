final class ErrorBilletera implements Exception {
  final String mensaje;
  final int? estadoHttp;
  final String? codigo;
  final bool resultadoIncierto;
  final Map<String, List<String>> campos;
  ErrorBilletera(
    this.mensaje, {
    this.estadoHttp,
    this.codigo,
    this.resultadoIncierto = false,
    Map<String, List<String>> campos = const {},
  }) : campos = Map.unmodifiable(
         campos.map((k, v) => MapEntry(k, List<String>.unmodifiable(v))),
       );
  @override
  String toString() => mensaje;
}
