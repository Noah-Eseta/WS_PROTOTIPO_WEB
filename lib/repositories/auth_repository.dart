import '../models/dto/autenticacion_api_dto.dart';
import '../models/usuario_autenticado.dart';

abstract interface class AuthRepository {
  Future<AutenticacionApiDto> registrar({
    required String nombre,
    required String correo,
    required String password,
    required String confirmacion,
  });
  Future<AutenticacionApiDto> iniciarSesion({
    required String correo,
    required String password,
  });
  Future<UsuarioAutenticado> obtenerPerfil(String token);
  Future<void> cerrarSesion(String token);
}
