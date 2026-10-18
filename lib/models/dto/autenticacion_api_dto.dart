import '../usuario_autenticado.dart';

/// Respuesta de transporte: nunca se publica como estado ni se serializa.
final class AutenticacionApiDto {
  final UsuarioAutenticado usuario;
  final String token;
  final DateTime expiraEn;

  const AutenticacionApiDto({
    required this.usuario,
    required this.token,
    required this.expiraEn,
  });

  factory AutenticacionApiDto.fromJson(Object? json) {
    if (json is! Map<String, dynamic> ||
        json['data'] is! Map<String, dynamic>) {
      throw const FormatException('Sesión no válida.');
    }
    final data = json['data'] as Map<String, dynamic>;
    final token = data['token'];
    final expiry = data['expires_at'];
    final date = expiry is String ? DateTime.tryParse(expiry) : null;
    if (token is! String ||
        token.isEmpty ||
        RegExp(r'\s').hasMatch(token) ||
        data['token_type'] != 'Bearer' ||
        date == null ||
        !date.isUtc) {
      throw const FormatException('Credencial no válida.');
    }
    return AutenticacionApiDto(
      usuario: UsuarioAutenticado.fromJson(data['user']),
      token: token,
      expiraEn: date,
    );
  }

  @override
  String toString() => 'Respuesta de autenticación';
}
