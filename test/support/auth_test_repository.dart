export 'wallet_test_repository.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prototipo_app/models/dto/autenticacion_api_dto.dart';
import 'package:prototipo_app/models/usuario_autenticado.dart';
import 'package:prototipo_app/providers/auth_provider.dart';
import 'package:prototipo_app/repositories/auth_repository.dart';
import 'package:prototipo_app/providers/carrito_provider.dart';
export 'package:prototipo_app/providers/auth_provider.dart';
export 'package:prototipo_app/providers/carrito_provider.dart'
    show cartRepositoryProvider;

export 'cart_test_repository.dart';

/// Repositorio exclusivo de pruebas; no verifica ni envía credenciales reales.
class AuthTestRepository implements AuthRepository {
  UsuarioAutenticado usuario = const UsuarioAutenticado(
    id: 1,
    nombre: 'Prueba',
    correo: 'Prueba@email.com',
  );
  DateTime Function() reloj = () => DateTime.now().toUtc();
  Duration vigencia = const Duration(hours: 1);
  Object? errorLogin, errorPerfil, errorLogout;
  Completer<AutenticacionApiDto>? pendiente;
  Completer<UsuarioAutenticado>? perfilPendiente;
  int logins = 0, registros = 0, perfiles = 0, salidas = 0;

  AutenticacionApiDto sesion() => AutenticacionApiDto(
    usuario: usuario,
    token: 'credencial-fixture-${usuario.id}',
    expiraEn: reloj().add(vigencia),
  );

  @override
  Future<AutenticacionApiDto> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    logins++;
    if (errorLogin case final error?) throw error;
    return pendiente != null ? pendiente!.future : sesion();
  }

  @override
  Future<AutenticacionApiDto> registrar({
    required String nombre,
    required String correo,
    required String password,
    required String confirmacion,
  }) async {
    registros++;
    if (errorLogin case final error?) throw error;
    return pendiente != null ? pendiente!.future : sesion();
  }

  @override
  Future<UsuarioAutenticado> obtenerPerfil(String token) async {
    perfiles++;
    if (errorPerfil case final error?) throw error;
    return perfilPendiente != null ? perfilPendiente!.future : usuario;
  }

  @override
  Future<void> cerrarSesion(String token) async {
    salidas++;
    if (errorLogout case final error?) throw error;
  }
}

Future<bool> iniciarSesionPrueba(ProviderContainer container) async {
  final ok = await container
      .read(authProvider.notifier)
      .iniciarSesion(
        correo: 'fixture@example.test',
        password: 'entrada-no-real',
      );
  if (ok) await container.read(carritoProvider.notifier).actualizar();
  return ok;
}
