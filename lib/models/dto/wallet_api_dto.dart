import '../billetera.dart';

Map<String, dynamic> objetoWallet(Object? valor) {
  if (valor is! Map<String, dynamic>) throw const FormatException();
  return valor;
}

int _entero(Object? valor, int minimo, int maximo) {
  if (valor is! int || valor < minimo || valor > maximo) {
    throw const FormatException();
  }
  return valor;
}

String _texto(Object? valor, {int maximo = 500}) {
  if (valor is! String || valor.trim().isEmpty || valor.runes.length > maximo) {
    throw const FormatException();
  }
  return valor;
}

String uuidWallet(Object? valor) {
  final texto = _texto(valor);
  if (!RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(texto)) {
    throw const FormatException();
  }
  return texto.toLowerCase();
}

Billetera billeteraDesdeJson(Object? valor) {
  final json = objetoWallet(valor);
  if (json['currency'] != 'PEN' || json['is_demo'] != true) {
    throw const FormatException();
  }
  final saldo = _entero(json['balance_cents'], 0, 100000000);
  final version = _entero(json['version'], 0, 9007199254740991);
  final id = json['id'] == null ? null : uuidWallet(json['id']);
  if (id == null && (saldo != 0 || version != 0)) throw const FormatException();
  return Billetera(id: id, centimos: saldo, version: version);
}

MovimientoBilletera movimientoDesdeJson(Object? valor) {
  final json = objetoWallet(valor);
  final tipo = json['type'];
  final delta = _entero(json['delta_cents'], -1000000, 1000000);
  final antes = _entero(json['balance_before_cents'], 0, 100000000);
  final despues = _entero(json['balance_after_cents'], 0, 100000000);
  if (json['is_demo'] != true ||
      !['admin_credit', 'admin_adjustment'].contains(tipo) ||
      delta == 0 ||
      antes + delta != despues ||
      (tipo == 'admin_credit' && delta < 0)) {
    throw const FormatException();
  }
  final fecha = DateTime.tryParse(_texto(json['created_at']));
  if (fecha == null || !fecha.isUtc) throw const FormatException();
  return MovimientoBilletera(
    id: uuidWallet(json['id']),
    operacion: uuidWallet(json['operation_id']),
    tipo: tipo as String,
    descripcion: _texto(json['reason']),
    centimos: delta,
    saldoAnterior: antes,
    saldoPosterior: despues,
    version: _entero(json['wallet_version'], 1, 9007199254740991),
    fecha: fecha,
    administradorId: json['authorized_by_user_id'] == null
        ? null
        : _entero(json['authorized_by_user_id'], 1, 9007199254740991),
  );
}

UsuarioBilletera usuarioBilleteraDesdeJson(Object? valor) {
  final json = objetoWallet(valor), user = objetoWallet(json['user']);
  return UsuarioBilletera(
    id: _entero(user['id'], 1, 9007199254740991),
    nombre: _texto(user['name']),
    billetera: billeteraDesdeJson(json['wallet']),
  );
}

PaginaBilletera<T> paginaWalletDesdeJson<T>(
  Object? valor,
  T Function(Object?) convertir,
) {
  final json = objetoWallet(valor), meta = objetoWallet(json['meta']);
  final datos = json['data'];
  if (datos is! List || datos.length > 50 || !meta.containsKey('next_cursor')) {
    throw const FormatException();
  }
  final cursor = meta['next_cursor'];
  if (cursor != null &&
      (cursor is! String || cursor.isEmpty || cursor.length > 2048)) {
    throw const FormatException();
  }
  return PaginaBilletera(datos.map(convertir), cursor as String?);
}

ReciboCredito reciboCreditoDesdeJson(Object? valor) {
  final json = objetoWallet(valor);
  final movimiento = movimientoDesdeJson(json['transaction']);
  final operacion = uuidWallet(json['operation_id']);
  if (json['status'] != 'applied' ||
      json['replayed'] is! bool ||
      movimiento.operacion != operacion ||
      movimiento.tipo != 'admin_credit') {
    throw const FormatException();
  }
  return ReciboCredito(
    operacion: operacion,
    repetido: json['replayed'] as bool,
    movimiento: movimiento,
  );
}
