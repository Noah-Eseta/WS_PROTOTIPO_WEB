import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/models/categoria.dart';
import 'package:prototipo_app/models/producto.dart';
import 'package:prototipo_app/providers/carrito_provider.dart';
import 'package:prototipo_app/providers/catalogo_provider.dart';
import 'package:prototipo_app/services/producto_service.dart';

import 'support/catalogo_test_repository.dart';

void main() {
  late CatalogoTestRepository repositorio;
  late ProviderContainer container;
  setUp(() {
    repositorio = CatalogoTestRepository();
    container = ProviderContainer(
      overrides: [catalogoRepositoryProvider.overrideWithValue(repositorio)],
    );
  });
  tearDown(() => container.dispose());

  test(
    'Comparte una carga y conserva el catálogo al perder observadores',
    () async {
      final listener = container.listen(catalogoProvider, (_, _) {});
      expect(container.read(catalogoProvider).isLoading, isTrue);
      final datos = await container.read(catalogoProvider.future);
      final secciones = container.read(seccionesCatalogoProvider).requireValue;
      final categorias = container
          .read(categoriasCatalogoProvider)
          .requireValue;
      expect(secciones[Categoria.ofertas], hasLength(16));
      expect(categorias.keys, Categoria.catalogo);
      expect(categorias[Categoria.software]!.first, same(datos[3]));
      expect(repositorio.llamadas, 1);
      listener.close();
      await container.pump();
      expect(await container.read(catalogoProvider.future), same(datos));
      expect(repositorio.llamadas, 1);
    },
  );

  test('Las copias conservan todos los campos de los productos demo', () async {
    final originales = await ProductoService().obtenerProductos();
    final datos = await container.read(catalogoProvider.future);
    List<Object?> campos(Producto p) => [
      p.nombre,
      p.subtitulo,
      p.categoria,
      p.colores,
      p.entrega,
      p.tipo,
      p.precio,
      p.precioAntes,
      p.top,
      p.nuevo,
      p.logo,
      p.banner,
      p.disponible,
    ];
    for (var i = 0; i < originales.length; i++) {
      final copia = datos[i];
      final original = originales[i];
      expect(copia.colores, original.colores);
      expect(campos(copia), campos(original));
    }
    expect(datos, hasLength(34));
  });

  test(
    'La carga y sus derivados propagan el mismo error sin nuevos intentos',
    () async {
      final error = Exception('Origen no disponible');
      repositorio = CatalogoTestRepository(cargar: () => Future.error(error));
      container.dispose();
      container = ProviderContainer(
        overrides: [catalogoRepositoryProvider.overrideWithValue(repositorio)],
      );
      final listener = container.listen(categoriasCatalogoProvider, (_, _) {});
      expect(container.read(categoriasCatalogoProvider).isLoading, isTrue);
      await expectLater(
        container.read(catalogoProvider.future),
        throwsA(same(error)),
      );
      await container.pump();
      expect(container.read(catalogoProvider).error, same(error));
      expect(container.read(seccionesCatalogoProvider).error, same(error));
      expect(container.read(categoriasCatalogoProvider).error, same(error));
      expect(repositorio.llamadas, 1);
      listener.close();
    },
  );

  test(
    'Las listas y objetos compartidos están aislados del origen mutable',
    () async {
      final colores = [Colors.blue];
      final original = Producto(
        nombre: 'Prueba',
        subtitulo: '',
        categoria: 'Software',
        colores: colores,
        entrega: '',
        precio: 5,
        precioAntes: 10,
        top: true,
        nuevo: true,
        logo: '',
        banner: '',
      );
      final origen = [original];
      repositorio = CatalogoTestRepository(cargar: () async => origen);
      container.dispose();
      container = ProviderContainer(
        overrides: [catalogoRepositoryProvider.overrideWithValue(repositorio)],
      );
      final datos = await container.read(catalogoProvider.future);
      final secciones = container.read(seccionesCatalogoProvider).requireValue;
      final categorias = container
          .read(categoriasCatalogoProvider)
          .requireValue;
      colores[0] = Colors.red;
      origen.clear();
      expect(datos.single.colores, [Colors.blue]);
      expect(datos.single, isNot(same(original)));
      expect(() => datos.clear(), throwsUnsupportedError);
      expect(() => datos[0] = original, throwsUnsupportedError);
      expect(
        () => datos.single.colores[0] = Colors.red,
        throwsUnsupportedError,
      );
      expect(() => secciones.clear(), throwsUnsupportedError);
      expect(() => categorias.clear(), throwsUnsupportedError);
      for (final lista in secciones.values) {
        expect(() => lista.clear(), throwsUnsupportedError);
        for (final producto in lista) {
          expect(producto, same(datos.single));
          expect(() => producto.colores.clear(), throwsUnsupportedError);
        }
      }
      expect(
        () => categorias[Categoria.software]!.clear(),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'Un catálogo vacío produce secciones vacías y ninguna categoría visible',
    () async {
      repositorio = CatalogoTestRepository(cargar: () async => []);
      container.dispose();
      container = ProviderContainer(
        overrides: [catalogoRepositoryProvider.overrideWithValue(repositorio)],
      );
      expect(await container.read(catalogoProvider.future), isEmpty);
      expect(container.read(categoriasCatalogoProvider).requireValue, isEmpty);
      expect(
        container.read(seccionesCatalogoProvider).requireValue.values,
        everyElement(isEmpty),
      );
    },
  );

  test(
    'Recargar el catálogo no modifica las instantáneas del carrito',
    () async {
      final catalogo = await container.read(catalogoProvider.future);
      container.read(carritoProvider.notifier).agregar(catalogo[3]);
      final carrito = container.read(carritoProvider);
      container.invalidate(catalogoProvider);
      await container.read(catalogoProvider.future);
      expect(container.read(carritoProvider), same(carrito));
      expect(carrito.total, 7.90);
      expect(repositorio.llamadas, 2);
    },
  );
}
