import '../models/billetera.dart';

abstract interface class WalletRepository {
  Future<Billetera> consultar(String token, {int? usuario});
  Future<PaginaBilletera<MovimientoBilletera>> movimientos(
    String token, {
    int? usuario,
    String? cursor,
  });
  Future<PaginaBilletera<UsuarioBilletera>> usuarios(
    String token, {
    String? cursor,
    int porPagina = 20,
  });
  Future<ReciboCredito> acreditar(String token, IntentoCredito intento);
}
