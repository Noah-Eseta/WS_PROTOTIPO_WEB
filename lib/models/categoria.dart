import 'package:flutter/material.dart';

class Categoria {
  final String nombre;
  final IconData icono;

  const Categoria(this.nombre, this.icono);

  static const todos = 'Todos';

  static const inicio = Categoria(todos, Icons.grid_view_rounded);
  static const streaming = Categoria('Streaming', Icons.play_circle_outline);
  static const software = Categoria('Software', Icons.apps_rounded);
  static const juegos = Categoria('Juegos', Icons.sports_esports_outlined);
  static const redes = Categoria('Redes', Icons.share_outlined);
  static const ofertas = Categoria(
    'Ofertas del día',
    Icons.local_fire_department_outlined,
  );
  static const masVendidos = Categoria('Más vendidos', Icons.star_outline);
  static const novedades = Categoria('Novedades', Icons.auto_awesome_outlined);

  static const catalogo = <Categoria>[streaming, software, juegos, redes];

  static const lista = <Categoria>[
    inicio,
    ...catalogo,
    ofertas,
    masVendidos,
    novedades,
  ];
}
