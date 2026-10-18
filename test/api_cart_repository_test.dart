import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/core/http/error_carrito.dart';
import 'package:prototipo_app/models/dto/carrito_api_dto.dart';
import 'package:prototipo_app/repositories/api_cart_repository.dart';

import 'support/dio_test_adapter.dart';

void main() {
  late Dio dio;
  late DioTestAdapter adapter;
  late ApiCartRepository repo;
  const id = 'e753f48c-0b0c-4bbf-ae50-36194fd5fc05';
  const operation = '5bb5ad46-c803-4d79-83ac-10c241f54a06';
  Map<String, dynamic> cart() => {
    'data': <String, dynamic>{
      'version': 7,
      'currency': 'PEN',
      'items': [
        <String, dynamic>{
          'product_id': id,
          'name': 'CANVA PRO',
          'quantity': 2,
          'available': true,
          'unit_price_cents': 790,
          'subtotal_cents': 1580,
        },
      ],
      'quantity_total': 2,
      'total_cents': 1580,
      'has_unavailable_items': false,
    },
  };
  setUp(() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.example.test',
        headers: {'Accept': 'application/json'},
      ),
    );
    adapter = DioTestAdapter((_) => respuestaJson(cart()));
    dio.httpClientAdapter = adapter;
    repo = ApiCartRepository(dio);
  });
  tearDown(() => dio.close(force: true));

  test(
    'GET convierte céntimos exactos y no modifica el cliente compartido',
    () async {
      final result = await repo.consultar('fixture');
      expect(result.version, 7);
      expect(result.items.single.precioCentimos, 790);
      expect(result.items.single.cantidad, 2);
      expect(adapter.peticiones.single.method, 'GET');
      expect(adapter.peticiones.single.path, '/api/v1/cart');
      expect(
        adapter.peticiones.single.headers['Authorization'],
        'Bearer fixture',
      );
      expect(adapter.peticiones.single.followRedirects, isFalse);
      expect(dio.options.headers.containsKey('Authorization'), isFalse);
      expect(() => result.items.clear(), throwsUnsupportedError);
    },
  );
  test(
    'PUT usa UUID, cantidad absoluta, versión y ningún precio ni configuración',
    () async {
      await repo.establecer('fixture', id.toUpperCase(), 2, 6);
      final request = adapter.peticiones.single;
      expect(request.method, 'PUT');
      expect(request.path, '/api/v1/cart/items/$id');
      expect(request.headers['X-Cart-Version'], '6');
      expect(request.data, {'quantity': 2});
    },
  );
  test(
    'Eliminar y vaciar son DELETE explícitos con versión y sin cuerpo',
    () async {
      await repo.eliminar('fixture', id, 7);
      await repo.vaciar('fixture', 8);
      expect(adapter.peticiones.map((r) => r.method), ['DELETE', 'DELETE']);
      expect(adapter.peticiones.first.path, '/api/v1/cart/items/$id');
      expect(adapter.peticiones.last.path, '/api/v1/cart');
      expect(adapter.peticiones.last.headers['X-Cart-Version'], '8');
      expect(adapter.peticiones.every((r) => r.data == null), isTrue);
    },
  );
  test(
    'Merge envía únicamente el lote aprobado y reconoce su comprobante',
    () async {
      dio.httpClientAdapter = DioTestAdapter(
        (_) => respuestaJson({
          'data': {
            'operation_id': operation,
            'status': 'applied',
            'applied_version': 8,
            'merged_items_count': 1,
            'replayed': true,
          },
        }),
      );
      final result = await repo.fusionar('fixture', operation, [
        (id: id, cantidad: 2),
      ], 7);
      expect(result.repetida, isTrue);
      expect(result.versionAplicada, 8);
      final request =
          (dio.httpClientAdapter as DioTestAdapter).peticiones.single;
      expect(request.path, '/api/v1/cart/merge');
      expect(request.method, 'POST');
      expect(request.data, {
        'operation_id': operation,
        'items': [
          {'product_id': id, 'quantity': 2},
        ],
      });
      expect(request.headers['X-Cart-Version'], '7');
    },
  );
  test('Un carrito de 34 productos conserva orden, UUID, precios y 11 no disponibles', () async {
    final products = jsonCatalogoApi()['data'] as List;
    final lines = products
        .map(
          (p) => {
            'product_id': p['id'],
            'name': p['name'],
            'quantity': 1,
            'available': p['available'],
            'unit_price_cents': p['price_cents'],
            'subtotal_cents': p['price_cents'],
          },
        )
        .toList();
    final total = products.fold<int>(
      0,
      (s, p) => s + ((p['price_cents'] as int?) ?? 0),
    );
    dio.httpClientAdapter = DioTestAdapter(
      (_) => respuestaJson({
        'data': {
          'version': 34,
          'currency': 'PEN',
          'items': lines,
          'quantity_total': 34,
          'total_cents': total,
          'has_unavailable_items': true,
        },
      }),
    );
    final dto = await repo.consultar('fixture');
    expect(dto.items, hasLength(34));
    expect(dto.items.map((i) => i.id), products.map((p) => p['id']));
    expect(
      dto.items.map((i) => i.precioCentimos),
      products.map((p) => p['price_cents']),
    );
    expect(dto.items.where((i) => i.precioCentimos == null), hasLength(11));
  });
  for (final status in [401, 404, 409, 422, 429, 500]) {
    test(
      'HTTP $status produce error seguro y no confirma la modificación',
      () async {
        dio.httpClientAdapter = DioTestAdapter(
          (_) => respuestaJson({
            'message': 'DETALLE_INTERNO_NO_MOSTRAR',
            'code': 'CART_VERSION_CONFLICT',
          }, estado: status),
        );
        await expectLater(
          repo.establecer('fixture', id, 2, 7),
          throwsA(
            isA<ErrorCarrito>()
                .having((e) => e.estadoHttp, 'estado', status)
                .having((e) => e.resultadoIncierto, 'incierto', status >= 500)
                .having(
                  (e) => e.toString(),
                  'seguro',
                  isNot(contains('DETALLE_INTERNO')),
                ),
          ),
        );
      },
    );
  }
  for (final type in [
    DioExceptionType.connectionTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
    DioExceptionType.badCertificate,
  ]) {
    test(
      'Conexión o timeout $type no reintenta ni filtra excepciones',
      () async {
        dio.httpClientAdapter = adapter = DioTestAdapter(
          (r) => throw DioException(
            requestOptions: r,
            type: type,
            message: 'DETALLE_INTERNO',
          ),
        );
        await expectLater(
          repo.vaciar('fixture', 7),
          throwsA(
            isA<ErrorCarrito>()
                .having((e) => e.resultadoIncierto, 'resultado incierto', true)
                .having(
                  (e) => e.toString(),
                  'seguro',
                  isNot(contains('DETALLE_INTERNO')),
                ),
          ),
        );
        expect(adapter.peticiones, hasLength(1));
      },
    );
  }
  for (final invalid in <String, Object?>{
    'version': -1,
    'currency': 'USD',
    'items': null,
    'quantity_total': 5,
    'total_cents': 0,
    'has_unavailable_items': true,
  }.entries) {
    test('Rechaza respuesta inconsistente en ${invalid.key}', () async {
      final body = cart();
      (body['data'] as Map)[invalid.key] = invalid.value;
      dio.httpClientAdapter = DioTestAdapter((_) => respuestaJson(body));
      await expectLater(
        repo.establecer('fixture', id, 2, 7),
        throwsA(
          isA<ErrorCarrito>().having(
            (e) => e.resultadoIncierto,
            'no se confirma',
            true,
          ),
        ),
      );
    });
  }
  for (final raw in ['html', 'null', '[]', '{"data":null}']) {
    test('JSON inválido no se convierte en carrito vacío: $raw', () async {
      dio.httpClientAdapter = DioTestAdapter(
        (_) => ResponseBody.fromString(raw, 200),
      );
      await expectLater(
        repo.consultar('fixture'),
        throwsA(isA<ErrorCarrito>()),
      );
    });
  }
  test('Rechaza UUID o precios de línea inválidos y duplicados', () {
    for (final change in <Map<String, Object?>>[
      {'product_id': 'CANVA PRO'},
      {'quantity': 0},
      {'unit_price_cents': 7.9},
      {'unit_price_cents': -1},
      {'subtotal_cents': 1},
      {'available': false},
    ]) {
      final body = cart();
      ((body['data'] as Map)['items'] as List)[0].addAll(change);
      expect(() => CarritoApiDto.fromJson(body), throwsFormatException);
    }
    final body = cart();
    final lines = (body['data'] as Map)['items'] as List;
    lines.add(Map<String, dynamic>.from(lines.single));
    expect(() => CarritoApiDto.fromJson(body), throwsFormatException);
  });
  test('Rechaza HTTP antes de enviar el Bearer', () async {
    dio.options.baseUrl = 'http://localhost:8080';
    await expectLater(repo.consultar('fixture'), throwsA(isA<ErrorCarrito>()));
    expect(adapter.peticiones, isEmpty);
  });
  test('Un comprobante inválido conserva incertidumbre para reintentar la misma operación', () async {
    dio.httpClientAdapter = DioTestAdapter((_) => respuestaJson({'data': {}}));
    await expectLater(
      repo.fusionar('fixture', operation, [(id: id, cantidad: 2)], 7),
      throwsA(
        isA<ErrorCarrito>().having(
          (e) => e.resultadoIncierto,
          'incierto',
          true,
        ),
      ),
    );
  });
  test('Formato y comprobantes no publican credenciales', () async {
    dio.httpClientAdapter = DioTestAdapter(
      (_) => ResponseBody.fromString(jsonEncode({'data': {}}), 200),
    );
    await expectLater(
      repo.consultar('fixture'),
      throwsA(
        isA<ErrorCarrito>().having(
          (e) => e.toString(),
          'mensaje sin credenciales',
          isNot(contains('fixture')),
        ),
      ),
    );
  });
}
