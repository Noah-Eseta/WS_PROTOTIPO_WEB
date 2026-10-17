import 'package:flutter/foundation.dart';

class RecargaDemo {
  final int centimos;
  final String metodoPago;
  final DateTime fecha;

  const RecargaDemo({
    required this.centimos,
    required this.metodoPago,
    required this.fecha,
  });
}

/// Billetera local para la presentación; no procesa pagos reales.
class SaldoService extends ChangeNotifier {
  SaldoService._();
  static final instancia = SaldoService._();

  int _centimos = 0;
  int get centimos => _centimos;
  double get saldo => _centimos / 100;

  final List<RecargaDemo> _recargas = [];
  List<RecargaDemo> get recargas => List.unmodifiable(_recargas);

  RecargaDemo recargar({required int centimos, required String metodoPago}) {
    if (centimos <= 0 || centimos > 100000) {
      throw ArgumentError.value(
        centimos,
        'centimos',
        'Debe estar entre S/ 0.01 y S/ 1,000.00',
      );
    }
    final recarga = RecargaDemo(
      centimos: centimos,
      metodoPago: metodoPago,
      fecha: DateTime.now(),
    );
    _centimos += centimos;
    _recargas.insert(0, recarga);
    notifyListeners();
    return recarga;
  }
}
