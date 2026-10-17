import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formato.dart';
import '../../models/producto.dart';
import '../imagen_producto.dart';
import '../tarjeta_interactiva.dart';

class OfertaCard extends StatelessWidget {
  final Producto producto;
  final String descuento;
  final VoidCallback onComprar;

  const OfertaCard({
    super.key,
    required this.producto,
    required this.descuento,
    required this.onComprar,
  });

  @override
  Widget build(BuildContext context) {
    return TarjetaInteractiva(
      onTap: producto.disponible ? onComprar : null,
      radio: 12,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.superficie,
          border: Border.all(color: AppColors.borde),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: ImagenProducto.banner(producto)),
                  Positioned(
                    left: 8,
                    top: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E4D),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        descuento,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          producto.disponible
                              ? formatoPrecio(producto.precio!)
                              : 'Sin disponibilidad',
                          style: TextStyle(
                            fontSize: producto.disponible ? 16 : 12,
                            fontWeight: FontWeight.w800,
                            color: producto.disponible
                                ? null
                                : AppColors.textoSecundario,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 34,
                        child: FilledButton(
                          onPressed: producto.disponible ? onComprar : null,
                          style: FilledButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          child: const Text('Comprar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MasVendido extends StatelessWidget {
  final Producto producto;
  final int puesto;
  final VoidCallback onComprar;

  const MasVendido({
    super.key,
    required this.producto,
    required this.puesto,
    required this.onComprar,
  });

  @override
  Widget build(BuildContext context) {
    return TarjetaInteractiva(
      onTap: producto.disponible ? onComprar : null,
      radio: 11,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          border: Border.all(color: AppColors.borde),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            ImagenProducto.logo(producto, width: 48, height: 48),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    producto.subtitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                  Text(
                    producto.disponible
                        ? formatoPrecio(producto.precio!)
                        : 'Sin disponibilidad',
                    style: TextStyle(
                      fontSize: producto.disponible ? 15 : 12,
                      fontWeight: FontWeight.w800,
                      color: producto.disponible
                          ? null
                          : AppColors.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '#$puesto',
              style: TextStyle(
                color: puesto < 4
                    ? const Color(0xFFFF9D21)
                    : AppColors.textoSecundario,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
