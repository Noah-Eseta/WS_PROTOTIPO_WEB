import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/core/http/error_autenticacion.dart';
import 'package:prototipo_app/repositories/api_auth_repository.dart';

import 'support/dio_test_adapter.dart';

void main() {
  late Dio dio;
  late DioTestAdapter adapter;
  late ApiAuthRepository repo;
  final user = {'id': 7, 'name': 'Persona', 'email': 'persona@example.test'};
  Map<String, dynamic> session() => {
    'data': {
      'user': user,
      'token': 'credencial-fixture-no-real',
      'token_type': 'Bearer',
      'expires_at': '2099-01-01T01:00:00.000000Z',
    },
  };
  setUp(() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.example.test',
        headers: {'Accept': 'application/json'},
      ),
    );
    adapter = DioTestAdapter((_) => respuestaJson(session()));
    dio.httpClientAdapter = adapter;
    repo = ApiAuthRepository(dio);
  });
  tearDown(() => dio.close(force: true));

  test('Login adapta JSON real, normaliza correo y no modifica cabeceras compartidas', () async {
    final result = await repo.iniciarSesion(
      correo: ' Persona@Example.Test ',
      password: 'entrada-fixture',
    );
    expect(result.usuario.id, 7);
    expect(result.usuario.nombre, 'Persona');
    expect(result.usuario.correo, 'persona@example.test');
    expect(result.expiraEn.isUtc, isTrue);
    expect(result.toString(), isNot(contains(result.token)));
    final request = adapter.peticiones.single;
    expect(request.path, '/api/v1/auth/login');
    expect(request.data, {
      'email': 'persona@example.test',
      'password': 'entrada-fixture',
    });
    expect(request.followRedirects, isFalse);
    expect(dio.options.headers.containsKey('Authorization'), isFalse);
  });

  test('Registro envía los cuatro campos y acepta 201', () async {
    dio.httpClientAdapter = DioTestAdapter(
      (_) => respuestaJson(session(), estado: 201),
    );
    final result = await repo.registrar(
      nombre: ' Persona ',
      correo: ' P@EXAMPLE.TEST ',
      password: 'entrada-fixture',
      confirmacion: 'entrada-fixture',
    );
    expect(result.usuario.nombre, 'Persona');
    final data =
        (dio.httpClientAdapter as DioTestAdapter).peticiones.single.data;
    expect(data, {
      'name': 'Persona',
      'email': 'p@example.test',
      'password': 'entrada-fixture',
      'password_confirmation': 'entrada-fixture',
    });
  });

  test('Me y logout envían Bearer solo en la petición privada', () async {
    dio.httpClientAdapter = DioTestAdapter(
      (r) => respuestaJson(
        r.path.endsWith('/me')
            ? {'data': user}
            : {'message': 'Sesión cerrada.'},
      ),
    );
    expect(
      (await repo.obtenerPerfil('fixture')).correo,
      'persona@example.test',
    );
    await repo.cerrarSesion('fixture');
    final requests = (dio.httpClientAdapter as DioTestAdapter).peticiones;
    expect(requests.map((r) => r.method), ['GET', 'POST']);
    for (final r in requests) {
      expect(r.headers['Authorization'], 'Bearer fixture');
    }
    expect(dio.options.headers.containsKey('Authorization'), isFalse);
  });

  for (final status in [401, 422, 429, 500]) {
    test(
      'HTTP $status devuelve error seguro sin información interna',
      () async {
        dio.httpClientAdapter = DioTestAdapter(
          (_) => respuestaJson({
            'message': 'EXCEPCION_INTERNA_NO_MOSTRAR',
            'errors': {
              'email': ['Correo no válido.'],
            },
          }, estado: status),
        );
        try {
          await repo.iniciarSesion(
            correo: 'p@example.test',
            password: 'entrada-fixture',
          );
          fail('Debe fallar');
        } on ErrorAutenticacion catch (error) {
          expect(error.estadoHttp, status);
          expect(error.toString(), isNot(contains('EXCEPCION_INTERNA')));
          if (status == 422) {
            expect(error.campos['email'], ['Correo no válido.']);
            expect(
              () => error.campos['email']!.clear(),
              throwsUnsupportedError,
            );
            expect(() => error.campos.clear(), throwsUnsupportedError);
          }
        }
      },
    );
  }
  for (final type in [
    DioExceptionType.connectionError,
    DioExceptionType.connectionTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.badCertificate,
  ]) {
    test(
      'Error de conexión $type no conserva credenciales ni excepción',
      () async {
        dio.httpClientAdapter = DioTestAdapter(
          (r) => throw DioException(
            requestOptions: r,
            type: type,
            message: 'INTERNO',
          ),
        );
        await expectLater(
          repo.iniciarSesion(
            correo: 'p@example.test',
            password: 'entrada-fixture',
          ),
          throwsA(
            isA<ErrorAutenticacion>().having(
              (e) => e.toString(),
              'seguro',
              isNot(contains('INTERNO')),
            ),
          ),
        );
      },
    );
  }
  for (final body in [
    'html',
    jsonEncode({'data': null}),
    jsonEncode({
      'data': {'user': null},
    }),
    jsonEncode({
      'data': {
        'user': {'id': 1},
        'token': null,
      },
    }),
    jsonEncode({
      'data': {
        'user': user,
        'token': 'fixture',
        'token_type': 'Bearer',
        'expires_at': 'sin fecha',
      },
    }),
  ]) {
    test('Rechaza respuesta inválida $body', () async {
      dio.httpClientAdapter = DioTestAdapter(
        (_) => ResponseBody.fromString(body, 200),
      );
      await expectLater(
        repo.iniciarSesion(
          correo: 'p@example.test',
          password: 'entrada-fixture',
        ),
        throwsA(isA<ErrorAutenticacion>()),
      );
    });
  }
  test('Auth no envía credenciales por HTTP', () async {
    dio.options.baseUrl = 'http://api.example.test';
    await expectLater(
      repo.iniciarSesion(correo: 'p@example.test', password: 'entrada-fixture'),
      throwsA(isA<ErrorAutenticacion>()),
    );
    expect(adapter.peticiones, isEmpty);
  });
}
