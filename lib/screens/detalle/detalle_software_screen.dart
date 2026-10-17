import 'package:flutter/material.dart';

import '../../models/producto.dart';
import 'detalle_producto_base.dart';

/// Detalle de compra de productos de Software.
class DetalleSoftwareScreen extends StatelessWidget {
  final Producto producto;

  const DetalleSoftwareScreen({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    return DetalleProductoBase(
      producto: producto,
      ruta: 'Software',
      insignias: const [
        DetalleItem(Icons.workspace_premium_outlined, 'Licencia original'),
        DetalleItem(Icons.verified_user_outlined, 'Compra segura'),
        DetalleItem(Icons.download_outlined, 'Entrega digital'),
        DetalleItem(Icons.headset_mic_outlined, 'Soporte WEIKANG'),
      ],
      descripcion:
          'Recibes el acceso o la licencia del software, gestionado por '
          'WEIKANG SHOP. La activación queda vinculada a tu pedido, con '
          'indicaciones de instalación y soporte durante el período contratado.',
      tarjetas: const [
        DetalleItem(
          Icons.key_outlined,
          'Activación asignada',
          'Obtienes los datos necesarios para activar el software en tu '
              'cuenta o dispositivo.',
        ),
        DetalleItem(
          Icons.devices_other_outlined,
          'Compatible con tus equipos',
          'Funciona en los sistemas y dispositivos indicados por el '
              'proveedor del software.',
        ),
        DetalleItem(
          Icons.headset_mic_outlined,
          'Soporte de activación',
          'Si tienes problemas al instalar o activar, contacta con soporte '
              'con tu número de pedido.',
        ),
      ],
      puntosImportantes: const [
        'La entrega se realiza una vez confirmado el pago.',
        'Sigue las indicaciones de activación enviadas con tu pedido.',
        'La licencia es válida únicamente durante el período contratado.',
        'Ante cualquier problema, contacta a soporte con tu número de pedido.',
      ],
    );
  }
}
