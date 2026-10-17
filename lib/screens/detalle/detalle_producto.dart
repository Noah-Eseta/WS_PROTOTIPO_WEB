import 'package:flutter/material.dart';

import '../../models/producto.dart';
import 'detalle_juegos_screen.dart';
import 'detalle_redes_screen.dart';
import 'detalle_software_screen.dart';
import 'detalle_streaming_screen.dart';

/// Devuelve la pantalla de detalle de la categoría, o null si el producto
/// se agrega directo al carrito.
Widget? detalleParaProducto(Producto p) => switch (p.categoria) {
  'Juegos' => DetalleJuegosScreen(producto: p),
  'Redes' => DetalleRedesScreen(producto: p),
  'Streaming' => DetalleStreamingScreen(producto: p),
  'Software' => DetalleSoftwareScreen(producto: p),
  _ => null,
};
