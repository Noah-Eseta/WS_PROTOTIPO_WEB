import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/core/http/error_api.dart';
import 'package:prototipo_app/repositories/api_catalogo_repository.dart';

import 'support/dio_test_adapter.dart';

void main() {
  late Dio cliente;
  setUp(() => cliente = Dio(BaseOptions(baseUrl: 'https://catalogo.example')));
  tearDown(() => cliente.close(force: true));
  TypeMatcher<ErrorApi> errorDe(TipoErrorApi tipo) =>
      isA<ErrorApi>().having((e) => e.tipo, 'tipo', tipo);

  test(
    'GET al endpoint público obtiene los 34 productos sin autenticación',
    () async {
      final adapter = DioTestAdapter((_) => respuestaJson(jsonCatalogoApi()));
      cliente.httpClientAdapter = adapter;
      final productos = await ApiCatalogoRepository(cliente).obtenerProductos();
      expect(productos, hasLength(34));
      expect(productos.where((p) => !p.disponible), hasLength(11));
      expect(adapter.peticiones, hasLength(1));
      expect(adapter.peticiones.single.method, 'GET');
      expect(
        adapter.peticiones.single.uri.toString(),
        'https://catalogo.example/api/v1/products',
      );
      expect(
        adapter.peticiones.single.headers.containsKey('Authorization'),
        isFalse,
      );
      expect(() => productos.clear(), throwsUnsupportedError);
    },
  );

  test(
    'Conserva el orden entregado por la API sin ordenar ni mezclar datos',
    () async {
      final json = jsonCatalogoApi();
      json['data'] = (json['data'] as List).reversed.toList();
      cliente.httpClientAdapter = DioTestAdapter((_) => respuestaJson(json));
      final productos = await ApiCatalogoRepository(cliente).obtenerProductos();
      expect(productos.first.nombre, 'YOUTUBE');
      expect(productos.last.nombre, 'FREE FIRE +10%');
      expect(
        productos.map((p) => p.nombre),
        (json['data'] as List).map((p) => p['name']),
      );
    },
  );

  test('Una respuesta vacía válida no activa el mock', () async {
    cliente.httpClientAdapter = DioTestAdapter(
      (_) => respuestaJson({'data': []}),
    );
    expect(await ApiCatalogoRepository(cliente).obtenerProductos(), isEmpty);
  });

  for (final estado in [401, 404, 500, 503, 204]) {
    test(
      'HTTP $estado genera un error sin exponer el cuerpo ni activar mock',
      () async {
        final adapter = DioTestAdapter(
          (_) => respuestaJson({'detalle': 'dato privado'}, estado: estado),
        );
        cliente.httpClientAdapter = adapter;
        await expectLater(
          ApiCatalogoRepository(cliente).obtenerProductos(),
          throwsA(
            errorDe(TipoErrorApi.http)
                .having((e) => e.estadoHttp, 'estado', estado),
          ),
        );
        expect(adapter.peticiones, hasLength(1));
        expect(
          ErrorApi(TipoErrorApi.http, estadoHttp: estado).toString(),
          isNot(contains('dato privado')),
        );
      },
    );
  }

  final fallos = {
    DioExceptionType.connectionTimeout: TipoErrorApi.tiempoEspera,
    DioExceptionType.receiveTimeout: TipoErrorApi.tiempoEspera,
    DioExceptionType.sendTimeout: TipoErrorApi.tiempoEspera,
    DioExceptionType.transformTimeout: TipoErrorApi.tiempoEspera,
    DioExceptionType.connectionError: TipoErrorApi.conexion,
    DioExceptionType.unknown: TipoErrorApi.conexion,
    DioExceptionType.badCertificate: TipoErrorApi.seguridad,
    DioExceptionType.cancel: TipoErrorApi.cancelado,
  };
  for (final caso in fallos.entries) {
    test(
      'Traduce el fallo ${caso.key} sin efectuar reintentos automáticos',
      () async {
        final adapter = DioTestAdapter(
          (opciones) =>
              throw DioException(requestOptions: opciones, type: caso.key),
        );
        cliente.httpClientAdapter = adapter;
        await expectLater(
          ApiCatalogoRepository(cliente).obtenerProductos(),
          throwsA(errorDe(caso.value)),
        );
        expect(adapter.peticiones, hasLength(1));
      },
    );
  }

  for (final contenido in [
    '{',
    '<html>Error</html>',
    jsonEncode([]),
    jsonEncode({'data': {}}),
    jsonEncode({'otro': []}),
    jsonEncode({
      'data': [null],
    }),
  ]) {
    test('Rechaza la respuesta JSON inesperada $contenido', () async {
      cliente.httpClientAdapter = DioTestAdapter(
        (_) => ResponseBody.fromString(contenido, 200),
      );
      await expectLater(
        ApiCatalogoRepository(cliente).obtenerProductos(),
        throwsA(errorDe(TipoErrorApi.respuestaInvalida)),
      );
    });
  }
}
