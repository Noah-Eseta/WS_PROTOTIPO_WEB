import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/http/error_autenticacion.dart';
import '../core/http/error_carrito.dart';
import '../core/http/error_billetera.dart';
import '../models/estado_autenticacion.dart';
import '../models/dto/autenticacion_api_dto.dart';
import '../repositories/auth_repository.dart';
import '../repositories/api_auth_repository.dart';
import '../services/pedido_service.dart';
import 'cliente_http_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ApiAuthRepository(ref.watch(clienteHttpProvider)),
);
final relojAuthProvider = Provider<DateTime Function()>((ref) => DateTime.now);
final authProvider = NotifierProvider<AuthNotifier, EstadoAutenticacion>(
  AuthNotifier.new,
);

/// Única sesión; la credencial opaca nunca forma parte del estado observable.
class AuthNotifier extends Notifier<EstadoAutenticacion> {
  String? _token;
  Timer? _caducidad;
  int _generacion = 0;

  /// Identidad efímera de sesión, sin exponer la credencial.
  int get revisionSesion => _generacion;

  @override
  EstadoAutenticacion build() {
    ref.onDispose(() {
      _generacion++;
      _caducidad?.cancel();
      _token = null;
    });
    return const EstadoAutenticacion();
  }

  void _limpiarDemo() {
    PedidoService.instancia.limpiar();
  }

  void _limpiar({bool caducada = false, bool enProceso = false}) {
    _generacion++;
    _caducidad?.cancel();
    _token = null;
    _limpiarDemo();
    state = EstadoAutenticacion(caducada: caducada, enProceso: enProceso);
  }

  bool verificarVigencia() {
    if (!state.iniciada) return false;
    if (state.expiraEn == null ||
        !state.expiraEn!.isAfter(ref.read(relojAuthProvider)().toUtc())) {
      _limpiar(caducada: true);
      return false;
    }
    return true;
  }

  void limpiarError() {
    if (state.error == null) return;
    state = EstadoAutenticacion(
      usuario: state.usuario,
      expiraEn: state.expiraEn,
      enProceso: state.enProceso,
      caducada: state.caducada,
    );
  }

  Future<bool> _autenticar(
    Future<AutenticacionApiDto> Function(AuthRepository) solicitar,
  ) async {
    if (state.enProceso || state.iniciada) return false;
    final generacion = ++_generacion;
    state = EstadoAutenticacion(
      usuario: state.usuario,
      expiraEn: state.expiraEn,
      enProceso: true,
    );
    try {
      final sesion = await solicitar(ref.read(authRepositoryProvider));
      if (!ref.mounted || generacion != _generacion) return false;
      final restante = sesion.expiraEn.difference(
        ref.read(relojAuthProvider)().toUtc(),
      );
      if (restante <= Duration.zero) {
        _limpiar(caducada: true);
        return false;
      }
      _caducidad?.cancel();
      _limpiarDemo();
      _token = sesion.token;
      state = EstadoAutenticacion(
        usuario: sesion.usuario,
        expiraEn: sesion.expiraEn,
      );
      _caducidad = Timer(restante, () {
        if (ref.mounted && generacion == _generacion) _limpiar(caducada: true);
      });
      return true;
    } catch (error) {
      if (ref.mounted && generacion == _generacion) {
        state = EstadoAutenticacion(
          usuario: state.usuario,
          expiraEn: state.expiraEn,
          error: error is ErrorAutenticacion
              ? error
              : ErrorAutenticacion(
                  'No se pudo iniciar sesión. Inténtalo nuevamente.',
                ),
        );
      }
      return false;
    }
  }

  Future<bool> iniciarSesion({
    required String correo,
    required String password,
  }) => _autenticar(
    (repo) => repo.iniciarSesion(correo: correo, password: password),
  );

  Future<bool> registrar({
    required String nombre,
    required String correo,
    required String password,
    required String confirmacion,
  }) => _autenticar(
    (repo) => repo.registrar(
      nombre: nombre,
      correo: correo,
      password: password,
      confirmacion: confirmacion,
    ),
  );

  Future<bool> obtenerPerfil() async {
    if (!verificarVigencia() || state.enProceso) return false;
    final token = _token!;
    final generacion = _generacion;
    state = EstadoAutenticacion(
      usuario: state.usuario,
      expiraEn: state.expiraEn,
      enProceso: true,
    );
    try {
      final usuario = await ref
          .read(authRepositoryProvider)
          .obtenerPerfil(token);
      if (!ref.mounted || generacion != _generacion) return false;
      if (usuario.id != state.usuario!.id) {
        _limpiar(caducada: true);
        return false;
      }
      state = EstadoAutenticacion(usuario: usuario, expiraEn: state.expiraEn);
      return true;
    } catch (error) {
      if (!ref.mounted || generacion != _generacion) return false;
      if (error is ErrorAutenticacion && error.estadoHttp == 401) {
        _limpiar(caducada: true);
      } else {
        state = EstadoAutenticacion(
          usuario: state.usuario,
          expiraEn: state.expiraEn,
          error: error is ErrorAutenticacion
              ? error
              : ErrorAutenticacion('No se pudo consultar el perfil.'),
        );
      }
      return false;
    }
  }

  Future<void> cerrarSesion() async {
    final token = _token;
    _limpiar(enProceso: token != null);
    final generacion = _generacion;
    ErrorAutenticacion? aviso;
    if (token != null) {
      try {
        await ref.read(authRepositoryProvider).cerrarSesion(token);
      } catch (error) {
        if (error is! ErrorAutenticacion || error.estadoHttp != 401) {
          aviso = ErrorAutenticacion(
            'Sesión cerrada en este dispositivo. No se pudo confirmar la revocación en el servidor.',
          );
        }
      }
    }
    if (ref.mounted && generacion == _generacion) {
      state = EstadoAutenticacion(error: aviso);
    }
  }

  /// La credencial solo se presta durante una petición HTTPS; no se publica.
  Future<T> conToken<T>(Future<T> Function(String token) solicitar) async {
    if (!verificarVigencia()) {
      throw ErrorAutenticacion('Inicia sesión nuevamente.', estadoHttp: 401);
    }
    final token = _token!;
    final generacion = _generacion;
    try {
      final resultado = await solicitar(token);
      if (!ref.mounted || generacion != _generacion || token != _token) {
        throw ErrorAutenticacion('La sesión cambió.', estadoHttp: 401);
      }
      return resultado;
    } catch (error) {
      if (ref.mounted &&
          generacion == _generacion &&
          ((error is ErrorCarrito && error.estadoHttp == 401) ||
              (error is ErrorBilletera && error.estadoHttp == 401))) {
        _limpiar(caducada: true);
      }
      rethrow;
    }
  }
}
