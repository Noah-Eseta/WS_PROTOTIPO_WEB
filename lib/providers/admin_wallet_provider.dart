import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/http/error_billetera.dart';
import '../models/billetera.dart';
import 'wallet_provider.dart';

final usuariosAdminProvider =
    AsyncNotifierProvider<
      UsuariosAdminNotifier,
      PaginaBilletera<UsuarioBilletera>
    >(UsuariosAdminNotifier.new, retry: (_, _) => null);

class UsuariosAdminNotifier
    extends AsyncNotifier<PaginaBilletera<UsuarioBilletera>> {
  int _revision = 0;
  bool _cargando = false;
  @override
  Future<PaginaBilletera<UsuarioBilletera>> build() async {
    final sesion = ref.watch(sesionWalletProvider);
    _revision++;
    _cargando = false;
    if (sesion.$1 == null) return PaginaBilletera([], null);
    final permiso = await ref.watch(permisoAdminProvider.future);
    if (!permiso) return PaginaBilletera([], null);
    return solicitarWallet(
      ref,
      (token) => ref.read(walletRepositoryProvider).usuarios(token),
    );
  }

  Future<void> siguiente() async {
    final anterior = state.asData?.value;
    if (_cargando || state.isLoading || anterior?.siguiente == null) return;
    _cargando = true;
    final sesion = ref.read(sesionWalletProvider);
    final revision = _revision;
    try {
      final pagina = await solicitarWallet(
        ref,
        (token) => ref
            .read(walletRepositoryProvider)
            .usuarios(token, cursor: anterior!.siguiente),
      );
      if (!ref.mounted ||
          revision != _revision ||
          sesion != ref.read(sesionWalletProvider)) {
        return;
      }
      state = AsyncData(
        PaginaBilletera(
          {
            for (final u in anterior!.elementos) u.id: u,
            for (final u in pagina.elementos) u.id: u,
          }.values,
          pagina.siguiente,
        ),
      );
    } finally {
      if (ref.mounted && revision == _revision) _cargando = false;
    }
  }
}

final generarOperacionWalletProvider = Provider<String Function()>(
  (ref) => () {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  },
);

final class EstadoCredito {
  final IntentoCredito? intento;
  final ReciboCredito? recibo;
  final bool enviando;
  final ErrorBilletera? error;
  final String? aviso;
  const EstadoCredito({
    this.intento,
    this.recibo,
    this.enviando = false,
    this.error,
    this.aviso,
  });
  bool get incierto => error?.resultadoIncierto ?? false;
}

final creditoWalletProvider =
    NotifierProvider<CreditoWalletNotifier, EstadoCredito>(
      CreditoWalletNotifier.new,
    );

class CreditoWalletNotifier extends Notifier<EstadoCredito> {
  int _revision = 0;
  @override
  EstadoCredito build() {
    ref.watch(sesionWalletProvider);
    _revision++;
    return const EstadoCredito();
  }

  void nuevaOperacion() {
    if (!state.enviando && !state.incierto) {
      _revision++;
      state = const EstadoCredito();
    }
  }

  Future<void> acreditar({
    required int destinatario,
    required int centimos,
    required String justificacion,
  }) async {
    if (state.enviando || state.recibo != null) return;
    final texto = justificacion.trim();
    final pendiente = state.intento;
    if (pendiente != null &&
        (pendiente.destinatario != destinatario ||
            pendiente.centimos != centimos ||
            pendiente.justificacion != texto)) {
      state = EstadoCredito(
        intento: pendiente,
        error: ErrorBilletera(
          'Reintenta la misma operación pendiente antes de cambiar sus datos.',
          resultadoIncierto: true,
        ),
      );
      return;
    }

    if (centimos < 1 ||
        centimos > 1000000 ||
        texto.isEmpty ||
        texto.runes.length > 500 ||
        destinatario < 1) {
      state = EstadoCredito(
        error: ErrorBilletera(
          'Revisa el importe y la justificación del crédito ficticio.',
        ),
      );
      return;
    }
    if (datosWallet(ref.read(permisoAdminProvider)) != true) {
      state = EstadoCredito(
        intento: pendiente,
        error: ErrorBilletera(
          'Primero confirma el permiso administrativo.',
          estadoHttp: 403,
          resultadoIncierto: pendiente != null,
        ),
      );
      return;
    }
    final intento =
        pendiente ??
        IntentoCredito(
          operacion: ref.read(generarOperacionWalletProvider)(),
          destinatario: destinatario,
          centimos: centimos,
          justificacion: texto,
        );
    final sesion = ref.read(sesionWalletProvider);
    final revision = _revision;
    state = EstadoCredito(intento: intento, enviando: true);
    try {
      final recibo = await solicitarWallet(
        ref,
        (token) => ref.read(walletRepositoryProvider).acreditar(token, intento),
      );
      if (!ref.mounted ||
          revision != _revision ||
          sesion != ref.read(sesionWalletProvider)) {
        return;
      }
      if (recibo.operacion != intento.operacion ||
          recibo.movimiento.centimos != intento.centimos ||
          recibo.movimiento.descripcion != texto) {
        throw ErrorBilletera(
          'El comprobante no coincide. Reintenta con la misma operación.',
          resultadoIncierto: true,
        );
      }
      state = EstadoCredito(intento: intento, recibo: recibo);
      ref.invalidate(walletProvider(destinatario));
      ref.invalidate(movimientosWalletProvider(destinatario));
      ref.invalidate(usuariosAdminProvider);
      try {
        // El saldo del recibo es histórico: consultar siempre la instantánea actual.
        await ref.read(walletProvider(destinatario).future);
      } catch (_) {
        if (ref.mounted &&
            revision == _revision &&
            sesion == ref.read(sesionWalletProvider)) {
          state = EstadoCredito(
            intento: intento,
            recibo: recibo,
            aviso: 'Crédito confirmado. No se pudo actualizar el saldo; reintenta la consulta.',
          );
        }
      }
    } catch (error) {
      if (!ref.mounted ||
          revision != _revision ||
          sesion != ref.read(sesionWalletProvider)) {
        return;
      }
      final seguro = error is ErrorBilletera
          ? error
          : ErrorBilletera(
              'No se pudo confirmar el crédito. Reintenta la misma operación.',
              resultadoIncierto: true,
            );
      state = EstadoCredito(
        intento: seguro.resultadoIncierto ? intento : null,
        error: seguro,
      );
      if (seguro.estadoHttp == 409) {
        ref.invalidate(walletProvider(destinatario));
        ref.invalidate(movimientosWalletProvider(destinatario));
        ref.invalidate(usuariosAdminProvider);
      }
    }
  }
}
