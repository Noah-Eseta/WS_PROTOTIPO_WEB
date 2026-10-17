import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/categoria.dart';
import '../../models/producto.dart';
import '../pie_tienda.dart';
import '../tarjeta_producto.dart';
import 'beneficios_tienda.dart';
import 'encabezado_seccion.dart';
import 'fila_productos.dart';
import 'portada_inicio.dart';
import 'tarjetas_destacadas.dart';

class CatalogoInicio extends StatelessWidget {
  final List<Producto> ofertas;
  final List<Producto> masVendidos;
  final List<Producto> novedades;
  final Map<Categoria, List<Producto>> productosPorCategoria;
  final bool compacto;
  final double margen;
  final double ancho;
  final ValueChanged<Categoria> onSeleccionarCategoria;
  final ValueChanged<Producto> onComprar;
  final VoidCallback onBeneficios;
  final VoidCallback onColaboradores;
  final VoidCallback onApp;

  const CatalogoInicio({
    super.key,
    required this.ofertas,
    required this.masVendidos,
    required this.novedades,
    required this.productosPorCategoria,
    required this.compacto,
    required this.margen,
    required this.ancho,
    required this.onSeleccionarCategoria,
    required this.onComprar,
    required this.onBeneficios,
    required this.onColaboradores,
    required this.onApp,
  });

  @override
  Widget build(BuildContext context) {
    final contenido = <Widget>[
      SliverToBoxAdapter(
        child: PortadaInicio(
          compacto: compacto,
          margen: margen,
          ancho: ancho,
          onOfertas: () => onSeleccionarCategoria(Categoria.ofertas),
          onBeneficios: onBeneficios,
          onColaboradores: onColaboradores,
          onApp: onApp,
        ),
      ),
      SliverToBoxAdapter(
        child: EncabezadoSeccion(
          margen: margen,
          icono: Icons.local_fire_department,
          titulo: 'Ofertas del día',
          subtitulo: 'Grandes descuentos por tiempo limitado',
          trailing: BotonVerTodo(
            onTap: () => onSeleccionarCategoria(Categoria.ofertas),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: FilaProductos(
          cantidad: ofertas.length,
          alturaTarjeta: 240,
          anchoTarjeta: compacto ? 210 : 230,
          margen: margen,
          itemBuilder: (_, i) => OfertaCard(
            producto: ofertas[i],
            descuento:
                '-${((1 - ofertas[i].precio! / ofertas[i].precioAntes!) * 100).round()}%',
            onComprar: () => onComprar(ofertas[i]),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: EncabezadoSeccion(
          margen: margen,
          icono: Icons.star,
          titulo: 'Más vendidos',
          subtitulo: 'Lo que nuestros clientes más compran',
          trailing: BotonVerTodo(
            onTap: () => onSeleccionarCategoria(Categoria.masVendidos),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: FilaProductos(
          cantidad: masVendidos.length,
          alturaTarjeta: 100,
          anchoTarjeta: compacto ? 260 : 250,
          margen: margen,
          itemBuilder: (_, i) => MasVendido(
            producto: masVendidos[i],
            puesto: i + 1,
            onComprar: () => onComprar(masVendidos[i]),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: EncabezadoSeccion(
          margen: margen,
          icono: Icons.auto_awesome,
          titulo: 'Novedades',
          subtitulo: 'Descubre lo nuevo en la tienda',
          trailing: BotonVerTodo(
            onTap: () => onSeleccionarCategoria(Categoria.novedades),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: FilaProductos(
          cantidad: novedades.length,
          alturaTarjeta: 370,
          anchoTarjeta: compacto ? 210 : 230,
          margen: margen,
          itemBuilder: (_, i) => TarjetaProducto(
            producto: novedades[i],
            onComprar: () => onComprar(novedades[i]),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(margen, 22, margen, 0),
          child: const BeneficiosTienda(),
        ),
      ),
      ..._seccionesCategoria(),
    ];

    return CustomScrollView(
      slivers: [
        for (final sliver in contenido) centrarSliverCatalogo(sliver, ancho),
        const SliverToBoxAdapter(child: PieTienda()),
      ],
    );
  }

  List<Widget> _seccionesCategoria() {
    if (productosPorCategoria.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No hay productos en esta categoría')),
          ),
        ),
      ];
    }

    final margenExterior = (margen - FilaProductos.espacioTarjeta).clamp(
      0.0,
      margen,
    );
    return [
      for (final seccion in productosPorCategoria.entries) ...[
        SliverToBoxAdapter(
          child: EncabezadoSeccion(
            margen: margen,
            icono: seccion.key.icono,
            color: AppColors.acento,
            titulo: seccion.key.nombre,
            subtitulo: '${seccion.value.length} productos',
            trailing: BotonVerTodo(
              onTap: () => onSeleccionarCategoria(seccion.key),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: FilaProductos(
            claveLista: ValueKey('catalogo-${seccion.key.nombre}'),
            cantidad: seccion.value.length,
            cantidadParaAncho: seccion.value.length >= 6
                ? 6
                : seccion.value.length,
            alturaTarjeta: 370,
            anchoTarjeta: compacto ? 210 : 230,
            margen: margen,
            margenExterior: margenExterior,
            clipBehavior: Clip.hardEdge,
            itemBuilder: (_, i) => TarjetaProducto(
              producto: seccion.value[i],
              onComprar: () => onComprar(seccion.value[i]),
            ),
          ),
        ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ];
  }
}
