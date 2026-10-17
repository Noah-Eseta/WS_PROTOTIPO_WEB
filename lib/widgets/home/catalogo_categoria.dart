import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/categoria.dart';
import '../../models/producto.dart';
import '../pie_tienda.dart';
import '../tarjeta_producto.dart';
import 'encabezado_seccion.dart';
import 'fila_productos.dart';

class CatalogoCategoria extends StatelessWidget {
  final Categoria categoria;
  final List<Producto> productos;
  final double margen;
  final double ancho;
  final ValueChanged<Producto> onComprar;

  const CatalogoCategoria({
    super.key,
    required this.categoria,
    required this.productos,
    required this.margen,
    required this.ancho,
    required this.onComprar,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        centrarSliverCatalogo(
          SliverToBoxAdapter(
            child: EncabezadoSeccion(
              margen: margen,
              icono: categoria.icono,
              color: AppColors.acento,
              titulo: categoria.nombre,
              subtitulo: '${productos.length} productos',
              trailing: const SizedBox.shrink(),
            ),
          ),
          ancho,
        ),
        if (productos.isEmpty)
          centrarSliverCatalogo(
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('No hay productos en esta categoría'),
                ),
              ),
            ),
            ancho,
          )
        else
          centrarSliverCatalogo(
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                margen,
                FilaProductos.espacioTarjeta,
                margen,
                96,
              ),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 230,
                  mainAxisExtent: 370,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                ),
                itemCount: productos.length,
                itemBuilder: (_, i) => TarjetaProducto(
                  producto: productos[i],
                  onComprar: () => onComprar(productos[i]),
                ),
              ),
            ),
            ancho,
          ),
        const SliverToBoxAdapter(child: PieTienda()),
      ],
    );
  }
}
