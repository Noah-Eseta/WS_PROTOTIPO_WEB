final class UsuarioAutenticado {
  final int id;
  final String nombre;
  final String correo;

  const UsuarioAutenticado({
    required this.id,
    required this.nombre,
    required this.correo,
  });

  factory UsuarioAutenticado.fromJson(Object? json) {
    if (json is! Map<String, dynamic> ||
        json['id'] is! int ||
        (json['id'] as int) <= 0 ||
        json['name'] is! String ||
        json['email'] is! String ||
        (json['name'] as String).trim().isEmpty ||
        (json['email'] as String).trim().isEmpty) {
      throw const FormatException('Usuario no válido.');
    }
    return UsuarioAutenticado(
      id: json['id'] as int,
      nombre: json['name'] as String,
      correo: json['email'] as String,
    );
  }
}
