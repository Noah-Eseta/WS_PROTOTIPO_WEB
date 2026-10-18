import 'package:flutter/material.dart';

class Producto {
  final String? id;
  final bool especial;
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
    this.id,
    this.especial = false,
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

  bool get sincronizable => id != null && !especial;

  /// Instantánea que no comparte colecciones mutables con el origen.
  Producto copiaInmutable() => Producto(
    id: id,
    especial: especial,
    nombre: nombre,
    subtitulo: subtitulo,
    categoria: categoria,
    colores: List.unmodifiable(colores),
    entrega: entrega,
    tipo: tipo,
    precio: precio,
    precioAntes: precioAntes,
    top: top,
    nuevo: nuevo,
    logo: logo,
    banner: banner,
  );

  Producto conPrecio(double? precioActual, {String? nombreActual}) => Producto(
    id: id,
    especial: especial,
    nombre: nombreActual ?? nombre,
    subtitulo: subtitulo,
    categoria: categoria,
    colores: List.unmodifiable(colores),
    entrega: entrega,
    tipo: tipo,
    precio: precioActual,
    precioAntes: precioAntes,
    top: top,
    nuevo: nuevo,
    logo: logo,
    banner: banner,
  );
}
