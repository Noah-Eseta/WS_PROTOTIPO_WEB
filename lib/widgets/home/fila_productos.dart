import 'package:flutter/material.dart';

/// Disposición horizontal compartida por las secciones de Home.
class FilaProductos extends StatelessWidget {
  static const espacioTarjeta = 18.0;

  final int cantidad;
  final int? cantidadParaAncho;
  final double alturaTarjeta;
  final double anchoTarjeta;
  final double margen;
  final double margenExterior;
  final Clip clipBehavior;
  final Key? claveLista;
  final IndexedWidgetBuilder itemBuilder;

  const FilaProductos({
    super.key,
    required this.cantidad,
    required this.alturaTarjeta,
    required this.anchoTarjeta,
    required this.margen,
    required this.itemBuilder,
    this.cantidadParaAncho,
    this.margenExterior = 0,
    this.clipBehavior = Clip.none,
    this.claveLista,
  });

  double _anchoFila(double ancho) {
    final visibles = cantidadParaAncho ?? cantidad;
    if (visibles != 6) return anchoTarjeta;
    final ajustado =
        (ancho - margen * 2 - espacioTarjeta * (visibles - 1)) / visibles;
    return ajustado >= 195 ? ajustado : anchoTarjeta;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: EdgeInsets.symmetric(horizontal: margenExterior),
        child: SizedBox(
          height: alturaTarjeta + espacioTarjeta * 2,
          child: ListView.separated(
            key: claveLista,
            clipBehavior: clipBehavior,
            padding: EdgeInsets.symmetric(
              horizontal: margen - margenExterior,
              vertical: espacioTarjeta,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: cantidad,
            separatorBuilder: (_, _) => const SizedBox(width: espacioTarjeta),
            itemBuilder: (context, i) => SizedBox(
              width: _anchoFila(constraints.maxWidth),
              child: itemBuilder(context, i),
            ),
          ),
        ),
      ),
    );
  }
}

/// Conserva el mismo centrado de los slivers en ambas vistas del catálogo.
Widget centrarSliverCatalogo(Widget sliver, double ancho) {
  final espacioLateral = ancho > 1400 ? (ancho - 1400) / 2 : 0.0;
  return SliverPadding(
    padding: EdgeInsets.symmetric(horizontal: espacioLateral),
    sliver: sliver,
  );
}
