import 'package:flutter/foundation.dart';

/// Sesión local para la presentación del prototipo.
class SesionService extends ChangeNotifier {
  SesionService._();
  static final instancia = SesionService._();

  String? _correo;
  String? get correo => _correo;
  bool get iniciada => _correo != null;
  String _nombre = 'Prueba';
  String get nombre => _nombre;
  String _telefono = '';
  String get telefono => _telefono;

  bool iniciarSesion(String correo, String password) {
    if (correo.trim().toLowerCase() != 'prueba@email.com' ||
        password != 'prueba_123') {
      return false;
    }
    _correo = 'Prueba@email.com';
    _nombre = 'Prueba';
    _telefono = '';
    notifyListeners();
    return true;
  }

  void actualizarPerfil({
    required String nombre,
    required String correo,
    required String telefono,
  }) {
    if (!iniciada) return;
    _nombre = nombre.trim();
    _correo = correo.trim();
    _telefono = telefono.trim();
    notifyListeners();
  }

  void cerrarSesion() {
    _correo = null;
    _nombre = 'Prueba';
    _telefono = '';
    notifyListeners();
  }
}
