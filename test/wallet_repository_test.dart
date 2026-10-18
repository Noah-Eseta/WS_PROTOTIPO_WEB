import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/core/http/error_billetera.dart';
import 'package:prototipo_app/models/billetera.dart';
import 'package:prototipo_app/models/dto/wallet_api_dto.dart';
import 'package:prototipo_app/repositories/api_wallet_repository.dart';

import 'support/dio_test_adapter.dart';
import 'support/wallet_test_repository.dart';

void main() {
  late Dio dio;
  late ApiWalletRepository repo;
  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
    repo = ApiWalletRepository(dio);
  });
  tearDown(() => dio.close(force: true));
  test('Billetera inicial nula y saldo exacto en céntimos', () async {
    dio.httpClientAdapter = DioTestAdapter(
      (_) => respuestaJson({'data': walletJson()}),
    );
    expect((await repo.consultar('fixture')).id, isNull);
    dio.httpClientAdapter = DioTestAdapter(
      (_) => respuestaJson({'data': walletJson(saldo: 100001, version: 2)}),
    );
    expect((await repo.consultar('fixture')).centimos, 100001);
    expect(formatoCentimos(100001), 'S/ 1000.01');
  });
  test(
    'Bearer por solicitud, sin redirecciones ni credencial global',
    () async {
      final adapter = DioTestAdapter(
        (_) => respuestaJson({'data': walletJson()}),
      );
      dio.httpClientAdapter = adapter;
      await repo.consultar('fixture');
      await repo.consultar('fixture', usuario: 8);
      expect(adapter.peticiones.map((p) => p.path), [
        '/api/v1/wallet',
        '/api/v1/admin/wallets/8',
      ]);
      expect(
        adapter.peticiones.every(
          (p) =>
              p.headers['Authorization'] == 'Bearer fixture' &&
              !p.followRedirects,
        ),
        isTrue,
      );
      expect(dio.options.headers.containsKey('Authorization'), isFalse);
    },
  );
  test('Rechaza HTTP antes de transmitir el token', () async {
    dio.options.baseUrl = 'http://localhost';
    final adapter = DioTestAdapter((_) => respuestaJson({}));
    dio.httpClientAdapter = adapter;
    await expectLater(
      repo.consultar('fixture'),
      throwsA(isA<ErrorBilletera>()),
    );
    expect(adapter.peticiones, isEmpty);
  });
  for (final valor in ['0.01', '0,01', '1.2', '10000.00', '9999.99', ' 20 ']) {
    test('Conversión decimal exacta $valor', () {
      expect(
        centimosCredito(valor),
        {
          '0.01': 1,
          '0,01': 1,
          '1.2': 120,
          '10000.00': 1000000,
          '9999.99': 999999,
          ' 20 ': 2000,
        }[valor],
      );
    });
  }
  for (final valor in [
    '0',
    '-1',
    '10000.01',
    '1e3',
    '1.001',
    'NaN',
    '1,000.00',
    '',
  ]) {
    test(
      'Rechaza importe inválido $valor',
      () => expect(centimosCredito(valor), isNull),
    );
  }
  test(
    'Movimientos: fechas, campos opcionales, cursor y colección inmutable',
    () async {
      final adapter = DioTestAdapter(
        (_) => respuestaJson(
          paginaWalletJson([movimientoJson()], cursor: 'cursor-opaco'),
        ),
      );
      dio.httpClientAdapter = adapter;
      final pagina = await repo.movimientos('fixture', cursor: 'anterior');
      expect(pagina.siguiente, 'cursor-opaco');
      expect(pagina.elementos.single.administradorId, isNull);
      expect(pagina.elementos.single.fecha.isUtc, isTrue);
      expect(() => pagina.elementos.clear(), throwsUnsupportedError);
      expect(adapter.peticiones.single.queryParameters['cursor'], 'anterior');
      expect(
        movimientoDesdeJson({...movimientoJson(), 'authorized_by_user_id': 12})
            .administradorId,
        12,
      );
    },
  );
  test('Lista administrativa confirma contrato y per_page=1', () async {
    final adapter = DioTestAdapter(
      (_) => respuestaJson(
        paginaWalletJson([
          {
            'user': {'id': 7, 'name': 'Persona'},
            'wallet': walletJson(),
          },
        ]),
      ),
    );
    dio.httpClientAdapter = adapter;
    expect(
      (await repo.usuarios('fixture', porPagina: 1)).elementos.single.id,
      7,
    );
    expect(adapter.peticiones.single.queryParameters, {'per_page': 1});
  });
  test(
    'Crédito envía solo UUID, céntimos y justificación; interpreta replay',
    () async {
      final adapter = DioTestAdapter(
        (_) => respuestaJson({
          'data': {
            'operation_id': uuidWalletPrueba,
            'status': 'applied',
            'replayed': true,
            'transaction': movimientoJson(),
          },
        }),
      );
      dio.httpClientAdapter = adapter;
      final recibo = await repo.acreditar(
        'fixture',
        const IntentoCredito(
          operacion: uuidWalletPrueba,
          destinatario: 7,
          centimos: 2000,
          justificacion: 'Presentación de demostración',
        ),
      );
      expect(recibo.repetido, isTrue);
      expect(adapter.peticiones.single.method, 'POST');
      expect(adapter.peticiones.single.data, {
        'operation_id': uuidWalletPrueba,
        'amount_cents': 2000,
        'reason': 'Presentación de demostración',
      });
    },
  );
  for (final status in [401, 403, 404, 409, 422, 429, 500]) {
    test('Error HTTP $status seguro, sin reintentos POST', () async {
      final adapter = DioTestAdapter(
        (_) => respuestaJson({
          'message': 'Authorization secreto',
          'code': 'VALIDATION_ERROR',
          'errors': {
            'reason': ['secreto'],
          },
        }, estado: status),
      );
      dio.httpClientAdapter = adapter;
      await expectLater(
        repo.acreditar(
          'fixture',
          const IntentoCredito(
            operacion: uuidWalletPrueba,
            destinatario: 7,
            centimos: 2000,
            justificacion: 'Prueba',
          ),
        ),
        throwsA(
          isA<ErrorBilletera>()
              .having((e) => e.estadoHttp, 'HTTP', status)
              .having((e) => e.resultadoIncierto, 'incierto', status >= 500)
              .having(
                (e) => e.toString().contains('secreto'),
                'sin secretos',
                false,
              ),
        ),
      );
      expect(adapter.peticiones, hasLength(1));
    });
  }
  for (final tipo in [
    DioExceptionType.connectionTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  ]) {
    test('Fallo $tipo conserva incertidumbre de escritura', () async {
      final adapter = DioTestAdapter(
        (r) => throw DioException(requestOptions: r, type: tipo),
      );
      dio.httpClientAdapter = adapter;
      await expectLater(
        repo.acreditar(
          'fixture',
          const IntentoCredito(
            operacion: uuidWalletPrueba,
            destinatario: 7,
            centimos: 1,
            justificacion: 'Prueba',
          ),
        ),
        throwsA(
          isA<ErrorBilletera>().having(
            (e) => e.resultadoIncierto,
            'incierto',
            true,
          ),
        ),
      );
      expect(adapter.peticiones, hasLength(1));
    });
  }
  for (final datos in [
    null,
    [],
    {'data': {}},
    {
      'data': {...walletJson(), 'currency': 'USD'},
    },
    {
      'data': {...walletJson(), 'balance_cents': '0'},
    },
    {
      'data': {...walletJson(), 'balance_cents': -1},
    },
    {
      'data': {...walletJson(), 'version': 1},
    },
    {
      'data': {...walletJson(), 'is_demo': false},
    },
  ]) {
    test('Rechaza billetera inesperada $datos', () async {
      dio.httpClientAdapter = DioTestAdapter((_) => respuestaJson(datos));
      await expectLater(
        repo.consultar('fixture'),
        throwsA(isA<ErrorBilletera>()),
      );
    });
  }
  test(
    'JSON mal formado y comprobante inválido son inciertos en POST',
    () async {
      dio.httpClientAdapter = DioTestAdapter(
        (_) => ResponseBody.fromString('{', 200),
      );
      await expectLater(
        repo.consultar('fixture'),
        throwsA(isA<ErrorBilletera>()),
      );
      dio.httpClientAdapter = DioTestAdapter(
        (_) => respuestaJson({'data': {}}),
      );
      await expectLater(
        repo.acreditar(
          'fixture',
          const IntentoCredito(
            operacion: uuidWalletPrueba,
            destinatario: 7,
            centimos: 1,
            justificacion: 'Prueba',
          ),
        ),
        throwsA(
          isA<ErrorBilletera>().having(
            (e) => e.resultadoIncierto,
            'incierto',
            true,
          ),
        ),
      );
    },
  );
}
