import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/http/error_autenticacion.dart';
import '../models/dto/autenticacion_api_dto.dart';
import '../models/usuario_autenticado.dart';
import 'auth_repository.dart';

final class ApiAuthRepository implements AuthRepository {
  final Dio _cliente;
  ApiAuthRepository(this._cliente);

  Future<Map<String, dynamic>> _solicitar(
    String accion, {
    String metodo = 'POST',
    Map<String, String>? datos,
    String? token,
    required int estado,
  }) async {
    final base = Uri.tryParse(_cliente.options.baseUrl);
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        (base.path.isNotEmpty && base.path != '/')) {
      throw ErrorAutenticacion(
        'La autenticación requiere un origen HTTPS seguro.',
      );
    }
    try {
      final respuesta = await _cliente.request<String>(
        '/api/v1/auth/$accion',
        data: datos,
        options: Options(
          method: metodo,
          responseType: ResponseType.plain,
          contentType: Headers.jsonContentType,
          followRedirects: false,
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );
      if (respuesta.statusCode != estado) throw const FormatException();
      final decoded = jsonDecode(respuesta.data ?? '');
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      return decoded;
    } on DioException catch (error) {
      final seguro = ErrorAutenticacion.desdeDio(error);
      if (error.response?.statusCode == 422) {
        try {
          final raw = error.response?.data;
          final body = raw is String ? jsonDecode(raw) : raw;
          final fields = <String, List<String>>{};
          if (body is Map && body['errors'] is Map) {
            final errors = body['errors'] as Map;
            for (final key in [
              'name',
              'email',
              'password',
              'password_confirmation',
            ]) {
              final messages = errors[key];
              if (messages is List && messages.every((v) => v is String)) {
                fields[key] = messages.cast<String>();
              }
            }
          }
          throw ErrorAutenticacion(
            seguro.mensaje,
            estadoHttp: 422,
            campos: fields,
          );
        } on FormatException {
          throw seguro;
        }
      }
      throw ErrorAutenticacion(
        seguro.mensaje,
        estadoHttp: seguro.estadoHttp,
        reintentarEnSegundos: int.tryParse(
          error.response?.headers.value('retry-after') ?? '',
        ),
      );
    } on FormatException {
      throw ErrorAutenticacion(
        'El servidor devolvió una respuesta de autenticación inesperada.',
      );
    }
  }

  Future<AutenticacionApiDto> _sesion(
    String accion,
    Map<String, String> datos,
    int estado,
  ) async {
    final body = await _solicitar(accion, datos: datos, estado: estado);
    try {
      return AutenticacionApiDto.fromJson(body);
    } on FormatException {
      throw ErrorAutenticacion('El servidor devolvió una sesión no válida.');
    }
  }

  @override
  Future<AutenticacionApiDto> registrar({
    required String nombre,
    required String correo,
    required String password,
    required String confirmacion,
  }) => _sesion('register', {
    'name': nombre.trim(),
    'email': correo.trim().toLowerCase(),
    'password': password,
    'password_confirmation': confirmacion,
  }, 201);

  @override
  Future<AutenticacionApiDto> iniciarSesion({
    required String correo,
    required String password,
  }) => _sesion('login', {
    'email': correo.trim().toLowerCase(),
    'password': password,
  }, 200);

  @override
  Future<UsuarioAutenticado> obtenerPerfil(String token) async {
    final body = await _solicitar(
      'me',
      metodo: 'GET',
      token: token,
      estado: 200,
    );
    try {
      return UsuarioAutenticado.fromJson(body['data']);
    } on FormatException {
      throw ErrorAutenticacion('El servidor devolvió un perfil no válido.');
    }
  }

  @override
  Future<void> cerrarSesion(String token) async {
    final body = await _solicitar('logout', token: token, estado: 200);
    if (body['message'] is! String) {
      throw ErrorAutenticacion('No se pudo confirmar la revocación del token.');
    }
  }
}
