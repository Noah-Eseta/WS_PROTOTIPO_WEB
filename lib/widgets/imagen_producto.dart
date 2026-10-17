import 'package:flutter/material.dart';

import '../models/producto.dart';

/// Muestra el banner (formato tarjeta) o el logo (formato cuadrado) del
/// producto. Si el archivo no existe, muestra "not image".
class ImagenProducto extends StatelessWidget {
  final Producto producto;
  final bool esLogo;
  final double? width;
  final double? height;
  final double radio;
  final BoxFit fit;
  final Alignment alignment;

  const ImagenProducto.banner(
    this.producto, {
    super.key,
    this.width,
    this.height,
    this.radio = 0,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  }) : esLogo = false;

  const ImagenProducto.logo(
    this.producto, {
    super.key,
    this.width,
    this.height,
    this.radio = 8,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  }) : esLogo = true;

  @override
  Widget build(BuildContext context) {
    final sinImagen = Container(
      color: Colors.black26,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(4),
      child: const Text(
        'not image',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white54, fontSize: 11),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: SizedBox(
        width: width,
        height: height,
        child: Image.asset(
          esLogo ? producto.logo : producto.banner,
          fit: fit,
          alignment: alignment,
          errorBuilder: (_, _, _) => sinImagen,
        ),
      ),
    );
  }
}
