import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/configuracion_api.dart';

final configuracionApiProvider = Provider<ConfiguracionApi>(
  (ref) => ConfiguracionApi.desdeEntorno(),
);

/// Compartido durante la vida del scope; los reintentos no crean otro cliente.
final clienteHttpProvider = Provider<Dio>((ref) {
  final configuracion = ref.watch(configuracionApiProvider);
  final cliente = Dio(
    BaseOptions(
      baseUrl: configuracion.urlBase,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );
  ref.onDispose(() => cliente.close(force: true));
  return cliente;
});
