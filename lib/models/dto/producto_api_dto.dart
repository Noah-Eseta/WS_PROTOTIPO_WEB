import 'package:flutter/material.dart';

import '../producto.dart';

/// Traduce el contrato remoto sin acoplar el modelo visual a HTTP o JSON.
final class ProductoApiDto {
  final String nombre;
  final String subtitulo;
  final String categoria;
  final int? precioCentimos;
  final int? precioAnteriorCentimos;
  final bool destacado;
  final bool nuevo;
  final String logo;
  final String banner;
  final List<Color> colores;
  final String entrega;
  final String tipo;

  const ProductoApiDto._({
    required this.nombre,
    required this.subtitulo,
    required this.categoria,
    required this.precioCentimos,
    required this.precioAnteriorCentimos,
    required this.destacado,
    required this.nuevo,
    required this.logo,
    required this.banner,
    required this.colores,
    required this.entrega,
    required this.tipo,
  });

  factory ProductoApiDto.fromJson(Object? valor) {
    if (valor is! Map<String, dynamic>) {
      throw const FormatException('El producto debe ser un objeto JSON.');
    }
    final precio = _centimos(valor, 'price_cents');
    final anterior = _centimos(valor, 'previous_price_cents');
    final oferta = precio != null && anterior != null && anterior > precio;
    if (_texto(valor, 'currency') != 'PEN' ||
        _booleano(valor, 'available') != (precio != null) ||
        _booleano(valor, 'is_on_sale') != oferta) {
      throw const FormatException(
        'Moneda o indicadores de precio incoherentes.',
      );
    }
    return ProductoApiDto._(
      nombre: _texto(valor, 'name'),
      subtitulo: _texto(valor, 'subtitle'),
      categoria: _texto(valor, 'category'),
      precioCentimos: precio,
      precioAnteriorCentimos: anterior,
      destacado: _booleano(valor, 'is_featured'),
      nuevo: _booleano(valor, 'is_new'),
      logo: _asset(valor, 'logo_asset'),
      banner: _asset(valor, 'banner_asset'),
      colores: _colores(valor['colors']),
      entrega: _texto(valor, 'delivery'),
      tipo: _texto(valor, 'type'),
    );
  }

  Producto toProducto() => Producto(
    nombre: nombre,
    subtitulo: subtitulo,
    categoria: categoria,
    precio: precioCentimos == null ? null : precioCentimos! / 100,
    precioAntes: precioAnteriorCentimos == null
        ? null
        : precioAnteriorCentimos! / 100,
    top: destacado,
    nuevo: nuevo,
    logo: logo,
    banner: banner,
    colores: colores,
    entrega: entrega,
    tipo: tipo,
  );

  static String _texto(Map<String, dynamic> json, String campo) {
    final valor = json[campo];
    if (valor is! String || valor.trim().isEmpty) {
      throw FormatException('Campo de texto inválido: $campo.');
    }
    return valor;
  }

  static bool _booleano(Map<String, dynamic> json, String campo) {
    final valor = json[campo];
    if (valor is! bool) throw FormatException('Indicador inválido: $campo.');
    return valor;
  }

  static int? _centimos(Map<String, dynamic> json, String campo) {
    final valor = json[campo];
    // El backend usa INTEGER de PostgreSQL; el rango cabe exactamente en Web.
    if (!json.containsKey(campo) ||
        (valor != null && (valor is! int || valor < 0 || valor > 2147483647))) {
      throw FormatException('Importe en céntimos inválido: $campo.');
    }
    return valor as int?;
  }

  static String _asset(Map<String, dynamic> json, String campo) {
    final valor = _texto(json, campo);
    if (!valor.startsWith('assets/images/') ||
        valor.split('/').contains('..') ||
        valor.contains('\\')) {
      throw FormatException('Referencia de imagen inválida: $campo.');
    }
    return valor;
  }

  static List<Color> _colores(Object? valor) {
    if (valor is! List || valor.length < 2) {
      throw const FormatException('Se requieren al menos dos colores ARGB.');
    }
    return List.unmodifiable(
      valor.map((color) {
        if (color is! String || !RegExp(r'^#[0-9a-fA-F]{8}$').hasMatch(color)) {
          throw const FormatException('Color ARGB inválido.');
        }
        return Color(int.parse(color.substring(1), radix: 16));
      }),
    );
  }
}
