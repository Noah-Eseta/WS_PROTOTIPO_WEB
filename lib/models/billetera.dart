/// Importes de demostración en céntimos de PEN. No contienen credenciales.
final class Billetera {
  final String? id;
  final int centimos;
  final int version;
  const Billetera({
    required this.id,
    required this.centimos,
    required this.version,
  });
}

final class MovimientoBilletera {
  final String id, operacion, tipo, descripcion;
  final int centimos, saldoAnterior, saldoPosterior, version;
  final int? administradorId;
  final DateTime fecha;
  const MovimientoBilletera({
    required this.id,
    required this.operacion,
    required this.tipo,
    required this.descripcion,
    required this.centimos,
    required this.saldoAnterior,
    required this.saldoPosterior,
    required this.version,
    required this.fecha,
    this.administradorId,
  });
  String get titulo =>
      tipo == 'admin_credit' ? 'Crédito ficticio' : 'Ajuste ficticio';
}

final class PaginaBilletera<T> {
  final List<T> elementos;
  final String? siguiente;
  PaginaBilletera(Iterable<T> elementos, this.siguiente)
    : elementos = List.unmodifiable(elementos);
}

final class UsuarioBilletera {
  final int id;
  final String nombre;
  final Billetera billetera;
  const UsuarioBilletera({
    required this.id,
    required this.nombre,
    required this.billetera,
  });
}

final class ReciboCredito {
  final String operacion;
  final bool repetido;
  final MovimientoBilletera movimiento;
  const ReciboCredito({
    required this.operacion,
    required this.repetido,
    required this.movimiento,
  });
}

final class IntentoCredito {
  final String operacion, justificacion;
  final int destinatario, centimos;
  const IntentoCredito({
    required this.operacion,
    required this.destinatario,
    required this.centimos,
    required this.justificacion,
  });
}

/// Admite coma decimal, sin separadores de miles ni notación exponencial.
int? centimosCredito(String entrada) {
  final texto = entrada.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d{1,5}(\.\d{1,2})?$').hasMatch(texto)) return null;
  final partes = texto.split('.');
  final valor =
      int.parse(partes[0]) * 100 +
      int.parse(partes.length == 1 ? '0' : partes[1].padRight(2, '0'));
  return valor >= 1 && valor <= 1000000 ? valor : null;
}

String formatoCentimos(int valor) {
  final absoluto = valor.abs();
  return '${valor < 0 ? '-' : ''}S/ ${absoluto ~/ 100}.${(absoluto % 100).toString().padLeft(2, '0')}';
}
