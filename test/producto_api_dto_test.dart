import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/models/dto/producto_api_dto.dart';
import 'package:prototipo_app/models/producto.dart';
import 'package:prototipo_app/services/producto_service.dart';

import 'support/dio_test_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  List<dynamic> datos() => jsonCatalogoApi()['data'] as List<dynamic>;
  Map<String, dynamic> canva() => Map<String, dynamic>.from(datos()[3] as Map);

  test(
    'Los 34 productos HTTP conservan todos los atributos del mock',
    () async {
      final locales = await ProductoService().obtenerProductos();
      final remotos = datos()
          .map((p) => ProductoApiDto.fromJson(p).toProducto())
          .toList();
      List<Object?> campos(Producto p) => [
        p.nombre,
        p.subtitulo,
        p.categoria,
        p.precio,
        p.precioAntes,
        p.top,
        p.nuevo,
        p.logo,
        p.banner,
        p.colores,
        p.entrega,
        p.tipo,
        p.disponible,
      ];
      expect(remotos, hasLength(34));
      for (var i = 0; i < locales.length; i++) {
        expect(
          campos(remotos[i]),
          campos(locales[i]),
          reason: 'Producto ${i + 1}',
        );
        final json = datos()[i] as Map;
        if (remotos[i].precio != null) {
          expect((remotos[i].precio! * 100).round(), json['price_cents']);
        }
        if (remotos[i].precioAntes != null) {
          expect(
            (remotos[i].precioAntes! * 100).round(),
            json['previous_price_cents'],
          );
        }
      }
      expect(remotos.where((p) => !p.disponible), hasLength(11));
      expect(remotos.where((p) => p.top), hasLength(6));
      expect(remotos.where((p) => p.nuevo), hasLength(6));
    },
  );

  test('790 y 1290 céntimos conservan los importes 7.90 y 12.90', () {
    final dto = ProductoApiDto.fromJson(canva());
    expect(dto.precioCentimos, 790);
    expect(dto.precioAnteriorCentimos, 1290);
    expect(dto.toProducto().precio, 7.90);
    expect(dto.toProducto().precioAntes, 12.90);
  });

  test('Los precios nulos se conservan y el precio cero sigue disponible', () {
    final netflix = datos().firstWhere((p) => p['name'] == 'NETFLIX');
    final producto = ProductoApiDto.fromJson(netflix).toProducto();
    expect(producto.precio, isNull);
    expect(producto.precioAntes, isNull);
    expect(producto.disponible, isFalse);
    expect(producto.top, isTrue);
    final gratis = canva()..['price_cents'] = 0;
    expect(ProductoApiDto.fromJson(gratis).toProducto().precio, 0.0);
    expect(ProductoApiDto.fromJson(gratis).toProducto().disponible, isTrue);
  });

  test('Los colores ARGB son exactos y no se pueden modificar', () {
    final json = canva();
    final dto = ProductoApiDto.fromJson(json);
    (json['colors'] as List)[0] = '#FFFFFFFF';
    expect(dto.colores, [const Color(0xFF14B8A6), const Color(0xFF7C3AED)]);
    expect(() => dto.colores.clear(), throwsUnsupportedError);
    expect(
      () => dto.toProducto().colores[0] = Colors.red,
      throwsUnsupportedError,
    );
  });

  test(
    'Todas las imágenes remotas se resuelven como assets empaquetados',
    () async {
      final rutas = <String>{};
      for (final json in datos()) {
        final producto = ProductoApiDto.fromJson(json).toProducto();
        expect(producto.logo, json['logo_asset']);
        expect(producto.banner, json['banner_asset']);
        rutas.addAll([producto.logo, producto.banner]);
      }
      for (final ruta in rutas) {
        expect(
          (await rootBundle.load(ruta)).lengthInBytes,
          greaterThan(0),
          reason: ruta,
        );
      }
    },
  );

  final invalidos = <String, Object?>{
    'name': null,
    'subtitle': '',
    'category': 1,
    'price_cents': 7.9,
    'previous_price_cents': -1,
    'currency': 'USD',
    'available': false,
    'is_on_sale': false,
    'is_featured': 'true',
    'is_new': 1,
    'logo_asset': 'https://example.com/logo.webp',
    'banner_asset': 'assets/images/../secreto',
    'colors': ['#FFFFFF', '#000000'],
    'delivery': null,
    'type': [],
  };
  for (final caso in invalidos.entries) {
    test('Rechaza el campo mal formado ${caso.key}', () {
      final json = canva()..[caso.key] = caso.value;
      expect(() => ProductoApiDto.fromJson(json), throwsFormatException);
    });
  }
  for (final precio in [-1, '790', 2147483648]) {
    test('Rechaza céntimos inválidos $precio', () {
      final json = canva()..['price_cents'] = precio;
      expect(() => ProductoApiDto.fromJson(json), throwsFormatException);
    });
  }
  test('Un campo de precio ausente no se interpreta como null', () {
    final json = canva()..remove('price_cents');
    expect(() => ProductoApiDto.fromJson(json), throwsFormatException);
  });
  test(
    'Rechaza una lista de colores insuficiente y un producto que no es objeto',
    () {
      expect(
        () => ProductoApiDto.fromJson(canva()..['colors'] = []),
        throwsFormatException,
      );
      expect(() => ProductoApiDto.fromJson(null), throwsFormatException);
    },
  );
}
