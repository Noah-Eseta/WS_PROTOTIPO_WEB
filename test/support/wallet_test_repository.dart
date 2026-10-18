import 'dart:async';

import 'package:prototipo_app/core/http/error_billetera.dart';
import 'package:prototipo_app/models/billetera.dart';
import 'package:prototipo_app/repositories/wallet_repository.dart';
export 'package:prototipo_app/providers/wallet_provider.dart';

const uuidWalletPrueba = '8cba287d-9be0-4731-8086-499348385af5';
MovimientoBilletera movimientoPrueba({
  int centimos = 2000,
  int version = 1,
  String operacion = uuidWalletPrueba,
}) => MovimientoBilletera(
  id: version == 1 ? uuidWalletPrueba : 'e84c9951-82f2-43db-bf68-499348385af5',
  operacion: operacion,
  tipo: 'admin_credit',
  descripcion: 'Presentación de demostración',
  centimos: centimos,
  saldoAnterior: 0,
  saldoPosterior: centimos,
  version: version,
  fecha: DateTime.utc(2026, 10, 18, 12),
);

class WalletTestRepository implements WalletRepository {
  bool admin = false, falloDespuesDeAplicar = false;
  Object? errorConsulta, errorMovimientos, errorUsuarios, errorCredito;
  Completer<Billetera>? saldoPendiente;
  Completer<ReciboCredito>? creditoPendiente;
  final saldos = <int, int>{};
  final consultas = <(String, int?)>[];
  final cursores = <String?>[];
  final intentos = <IntentoCredito>[];
  final recibos = <String, ReciboCredito>{};
  final paginas = <String?, PaginaBilletera<MovimientoBilletera>>{};
  final paginasUsuarios = <String?, PaginaBilletera<UsuarioBilletera>>{};
  int comprobaciones = 0;
  int _id(String token, int? usuario) =>
      usuario ?? int.parse(token.split('-').last);
  @override
  Future<Billetera> consultar(String token, {int? usuario}) async {
    consultas.add((token, usuario));
    if (errorConsulta case final error?) throw error;
    if (saldoPendiente != null) return saldoPendiente!.future;
    final saldo = saldos[_id(token, usuario)] ?? 0;
    return Billetera(
      id: saldo == 0 ? null : uuidWalletPrueba,
      centimos: saldo,
      version: saldo == 0 ? 0 : 1,
    );
  }

  @override
  Future<PaginaBilletera<MovimientoBilletera>> movimientos(
    String token, {
    int? usuario,
    String? cursor,
  }) async {
    cursores.add(cursor);
    if (errorMovimientos case final error?) throw error;
    return paginas[cursor] ?? PaginaBilletera([], null);
  }

  @override
  Future<PaginaBilletera<UsuarioBilletera>> usuarios(
    String token, {
    String? cursor,
    int porPagina = 20,
  }) async {
    if (porPagina == 1) comprobaciones++;
    if (errorUsuarios case final error?) throw error;
    if (!admin) throw ErrorBilletera('Sin permiso.', estadoHttp: 403);
    return paginasUsuarios[cursor] ??
        PaginaBilletera([
          UsuarioBilletera(
            id: 1,
            nombre: 'Persona de prueba',
            billetera: Billetera(
              id: saldos[1] == null ? null : uuidWalletPrueba,
              centimos: saldos[1] ?? 0,
              version: saldos[1] == null ? 0 : 1,
            ),
          ),
        ], null);
  }

  @override
  Future<ReciboCredito> acreditar(String token, IntentoCredito intento) async {
    intentos.add(intento);
    if (errorCredito case final error?) throw error;
    if (creditoPendiente != null) return creditoPendiente!.future;
    final existente = recibos[intento.operacion];
    if (existente != null) {
      return ReciboCredito(
        operacion: existente.operacion,
        repetido: true,
        movimiento: existente.movimiento,
      );
    }
    final antes = saldos[intento.destinatario] ?? 0;
    final movimiento = MovimientoBilletera(
      id: uuidWalletPrueba,
      operacion: intento.operacion,
      tipo: 'admin_credit',
      descripcion: intento.justificacion,
      centimos: intento.centimos,
      saldoAnterior: antes,
      saldoPosterior: antes + intento.centimos,
      version: recibos.length + 1,
      fecha: DateTime.utc(2026, 10, 18),
    );
    final recibo = ReciboCredito(
      operacion: intento.operacion,
      repetido: false,
      movimiento: movimiento,
    );
    saldos[intento.destinatario] = movimiento.saldoPosterior;
    recibos[intento.operacion] = recibo;
    if (falloDespuesDeAplicar) {
      falloDespuesDeAplicar = false;
      throw ErrorBilletera('Sin conexión.', resultadoIncierto: true);
    }
    return recibo;
  }
}

Map<String, dynamic> walletJson({int saldo = 0, int version = 0}) => {
  'id': saldo == 0 ? null : uuidWalletPrueba,
  'currency': 'PEN',
  'balance_cents': saldo,
  'version': version,
  'is_demo': true,
};
Map<String, dynamic> movimientoJson() => {
  'id': uuidWalletPrueba,
  'operation_id': uuidWalletPrueba,
  'type': 'admin_credit',
  'delta_cents': 2000,
  'balance_before_cents': 0,
  'balance_after_cents': 2000,
  'wallet_version': 1,
  'reason': 'Presentación de demostración',
  'created_at': '2026-10-18T12:00:00.000000Z',
  'is_demo': true,
};
Map<String, dynamic> paginaWalletJson(List<Object?> datos, {String? cursor}) =>
    {
      'data': datos,
      'links': {'next': null, 'prev': null},
      'meta': {'next_cursor': cursor, 'prev_cursor': null, 'per_page': 20},
    };
