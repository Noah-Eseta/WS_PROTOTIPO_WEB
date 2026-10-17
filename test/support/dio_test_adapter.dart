import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

String leerCatalogoApi() =>
    File('test/fixtures/catalogo_api.json').readAsStringSync();

Map<String, dynamic> jsonCatalogoApi() =>
    jsonDecode(leerCatalogoApi()) as Map<String, dynamic>;

ResponseBody respuestaJson(Object? datos, {int estado = 200}) =>
    ResponseBody.fromString(
      jsonEncode(datos),
      estado,
      headers: {
        Headers.contentTypeHeader: ['application/json; charset=utf-8'],
      },
    );

class DioTestAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions) responder;
  final peticiones = <RequestOptions>[];
  bool cerrado = false;
  bool? cierreForzado;

  DioTestAdapter(this.responder);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (cerrado) throw StateError('El cliente de pruebas está cerrado.');
    peticiones.add(options);
    return responder(options);
  }

  @override
  void close({bool force = false}) {
    cerrado = true;
    cierreForzado = force;
  }
}
