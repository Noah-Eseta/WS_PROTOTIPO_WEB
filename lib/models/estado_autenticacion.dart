import '../core/http/error_autenticacion.dart';
import 'usuario_autenticado.dart';

final class EstadoAutenticacion {
  final UsuarioAutenticado? usuario;
  final DateTime? expiraEn;
  final bool enProceso;
  final ErrorAutenticacion? error;
  final bool caducada;

  const EstadoAutenticacion({
    this.usuario,
    this.expiraEn,
    this.enProceso = false,
    this.error,
    this.caducada = false,
  });

  bool get iniciada => usuario != null;
  String get nombre => usuario?.nombre ?? '';
  String? get correo => usuario?.correo;
}
