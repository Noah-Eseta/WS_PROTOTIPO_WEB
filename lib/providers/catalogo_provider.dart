import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/catalogo_producto.dart';
import '../core/configuracion_api.dart';
import '../models/categoria.dart';
import '../models/producto.dart';
import '../repositories/catalogo_repository.dart';
import '../repositories/api_catalogo_repository.dart';
import '../services/producto_service.dart';
import 'cliente_http_provider.dart';

final catalogoRepositoryProvider = Provider<CatalogoRepository>((ref) {
  return switch (ref.watch(configuracionApiProvider).origen) {
    OrigenCatalogo.mock => ProductoService(),
    OrigenCatalogo.api => ApiCatalogoRepository(ref.watch(clienteHttpProvider)),
  };
});

/// Única carga compartida; no se descarta al salir de Home.
final catalogoProvider = FutureProvider<List<Producto>>((ref) async {
  final productos = await ref
      .watch(catalogoRepositoryProvider)
      .obtenerProductos();
  return List.unmodifiable(productos.map((p) => p.copiaInmutable()));
}, retry: (intentos, error) => null);

/// Vistas derivadas, sin caché de datos ni solicitudes adicionales al repositorio.
final seccionesCatalogoProvider =
    Provider<AsyncValue<Map<Categoria, List<Producto>>>>((ref) {
      return ref
          .watch(catalogoProvider)
          .whenData(
            (productos) => Map.unmodifiable({
              for (final seccion in Categoria.lista.skip(1))
                seccion: productosDeSeccion(seccion, productos),
            }),
          );
    });

final categoriasCatalogoProvider =
    Provider<AsyncValue<Map<Categoria, List<Producto>>>>((ref) {
      return ref
          .watch(seccionesCatalogoProvider)
          .whenData(
            (secciones) => Map.unmodifiable({
              for (final categoria in Categoria.catalogo)
                if (secciones[categoria]!.isNotEmpty)
                  categoria: secciones[categoria]!,
            }),
          );
    });
