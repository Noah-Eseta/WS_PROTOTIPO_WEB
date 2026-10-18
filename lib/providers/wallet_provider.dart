import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/http/error_billetera.dart';
import '../models/billetera.dart';
import '../repositories/wallet_repository.dart';
import '../repositories/api_wallet_repository.dart';
import 'auth_provider.dart';
import 'cliente_http_provider.dart';

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => ApiWalletRepository(ref.watch(clienteHttpProvider)),
);

// Distingue también dos sesiones de la misma cuenta con la misma caducidad.
final sesionWalletProvider = Provider<(int?, int)>((ref) {
  final sesion = ref.watch(authProvider);
  return (sesion.usuario?.id, ref.read(authProvider.notifier).revisionSesion);
});

final permisoAdminProvider = AsyncNotifierProvider<PermisoAdminNotifier, bool>(
  PermisoAdminNotifier.new,
  retry: (_, _) => null,
);

class PermisoAdminNotifier extends AsyncNotifier<bool> {
  int _revision = 0;
  @override
  Future<bool> build() async {
    final sesion = ref.watch(sesionWalletProvider);
    final revision = ++_revision;
    if (sesion.$1 == null) return false;
    try {
      await ref
          .read(authProvider.notifier)
          .conToken(
            (token) => ref
                .read(walletRepositoryProvider)
                .usuarios(token, porPagina: 1),
          );
      return revision == _revision;
    } on ErrorBilletera catch (error) {
      if (error.estadoHttp == 403) return false;
      rethrow;
    }
  }

  void denegar() {
    _revision++;
    state = const AsyncData(false);
  }
}

Future<T> solicitarWallet<T>(
  Ref ref,
  Future<T> Function(String) solicitud,
) async {
  final sesion = ref.read(sesionWalletProvider);
  try {
    return await ref.read(authProvider.notifier).conToken(solicitud);
  } on ErrorBilletera catch (error) {
    if (error.estadoHttp == 403 &&
        ref.mounted &&
        sesion == ref.read(sesionWalletProvider)) {
      ref.read(permisoAdminProvider.notifier).denegar();
    }
    rethrow;
  }
}

/// Una clave por cuenta: consultar el propio usuario desde administración reutiliza el saldo.
final walletProvider =
    AsyncNotifierProvider.family<WalletNotifier, Billetera?, int>(
      WalletNotifier.new,
      retry: (_, _) => null,
    );

class WalletNotifier extends AsyncNotifier<Billetera?> {
  final int usuario;
  WalletNotifier(this.usuario);
  @override
  Future<Billetera?> build() async {
    final sesion = ref.watch(sesionWalletProvider);
    if (sesion.$1 == null) return null;
    if (usuario != sesion.$1 && !await ref.watch(permisoAdminProvider.future)) {
      return null;
    }
    return solicitarWallet(
      ref,
      (token) => ref
          .read(walletRepositoryProvider)
          .consultar(token, usuario: usuario == sesion.$1 ? null : usuario),
    );
  }
}

final movimientosWalletProvider =
    AsyncNotifierProvider.family<
      MovimientosWalletNotifier,
      PaginaBilletera<MovimientoBilletera>,
      int
    >(MovimientosWalletNotifier.new, retry: (_, _) => null);

class MovimientosWalletNotifier
    extends AsyncNotifier<PaginaBilletera<MovimientoBilletera>> {
  final int usuario;
  int _revision = 0;
  bool _cargando = false;
  MovimientosWalletNotifier(this.usuario);
  @override
  Future<PaginaBilletera<MovimientoBilletera>> build() async {
    final sesion = ref.watch(sesionWalletProvider);
    _revision++;
    _cargando = false;
    if (sesion.$1 == null) return PaginaBilletera([], null);
    if (usuario != sesion.$1 && !await ref.watch(permisoAdminProvider.future)) {
      return PaginaBilletera([], null);
    }
    return solicitarWallet(
      ref,
      (token) => ref
          .read(walletRepositoryProvider)
          .movimientos(token, usuario: usuario == sesion.$1 ? null : usuario),
    );
  }

  Future<void> siguiente() async {
    final pagina = state.asData?.value;
    if (_cargando || pagina?.siguiente == null || state.isLoading) return;
    final sesion = ref.read(sesionWalletProvider);
    final revision = _revision;
    _cargando = true;
    try {
      final propia = ref.read(authProvider).usuario?.id == usuario;
      final nueva = await solicitarWallet(
        ref,
        (token) => ref
            .read(walletRepositoryProvider)
            .movimientos(
              token,
              usuario: propia ? null : usuario,
              cursor: pagina!.siguiente,
            ),
      );
      if (!ref.mounted ||
          revision != _revision ||
          sesion != ref.read(sesionWalletProvider)) {
        return;
      }
      final porId = {
        for (final item in pagina!.elementos) item.id: item,
        for (final item in nueva.elementos) item.id: item,
      };
      state = AsyncData(PaginaBilletera(porId.values, nueva.siguiente));
    } finally {
      if (ref.mounted && revision == _revision) _cargando = false;
    }
  }
}

/// No reutilizar valores anteriores mientras cambia la sesión o se actualizan datos privados.
T? datosWallet<T>(AsyncValue<T> valor) =>
    valor.isLoading ? null : valor.asData?.value;

String mensajeWallet(Object error) => error is ErrorBilletera
    ? error.mensaje
    : 'No se pudo consultar la billetera. Vuelve a intentarlo.';
