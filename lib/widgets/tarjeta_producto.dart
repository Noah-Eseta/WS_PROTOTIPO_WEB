import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formato.dart';
import '../models/producto.dart';
import 'imagen_producto.dart';
import 'tarjeta_interactiva.dart';

class TarjetaProducto extends StatelessWidget {
  final Producto producto;
  final VoidCallback onComprar;

  const TarjetaProducto({
    super.key,
    required this.producto,
    required this.onComprar,
  });

  @override
  Widget build(BuildContext context) {
    final p = producto;
    return TarjetaInteractiva(
      onTap: p.disponible ? onComprar : null,
      radio: 14,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borde),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 100,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(child: ImagenProducto.banner(p)),
                  if (p.top)
                    const Positioned(
                      left: 8,
                      top: 8,
                      child: _Etiqueta('★ TOP', color: AppColors.acento),
                    ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: _Etiqueta(p.categoria, color: Colors.black87),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    p.subtitulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  _Dato('Entrega', p.entrega),
                  const SizedBox(height: 6),
                  _Dato('Tipo', p.tipo),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              // Conserva la fila cuando ambos elementos caben a su ancho natural.
              // Si no caben, apila el contenido sin encoger ni recortar precios.
              child: OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                overflowAlignment: OverflowBarAlignment.start,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!p.disponible)
                        const Text(
                          'Sin disponibilidad',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textoSecundario,
                          ),
                        )
                      else ...[
                        if (p.precioAntes != null)
                          Text(
                            formatoPrecio(p.precioAntes!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textoSecundario,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          formatoPrecio(p.precio!),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      side: BorderSide(
                        color: p.disponible
                            ? AppColors.acento
                            : AppColors.borde,
                      ),
                    ),
                    onPressed: p.disponible ? onComprar : null,
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text(
                      'Agregar',
                      style: TextStyle(fontSize: 13),
                    ),
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

class _Etiqueta extends StatelessWidget {
  final String texto;
  final Color color;

  const _Etiqueta(this.texto, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Dato(this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borde),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            etiqueta.toUpperCase(),
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Flexible(
            child: Text(
              valor.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
