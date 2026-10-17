import 'package:flutter/material.dart';

class Producto {
  final String nombre;
  final String subtitulo;
  final String categoria;
  final List<Color> colores;
  final String entrega;
  final String tipo;
  final double? precio;
  final double? precioAntes;
  final bool top;
  final bool nuevo;
  final String logo;
  final String banner;

  const Producto({
    required this.nombre,
    required this.subtitulo,
    required this.categoria,
    required this.colores,
    required this.entrega,
    this.precio,
    this.tipo = 'Producto digital',
    this.precioAntes,
    this.top = false,
    this.nuevo = false,
    required this.logo,
    required this.banner,
  });

  /// Sin precio = sin disponibilidad.
  bool get disponible => precio != null;
}
