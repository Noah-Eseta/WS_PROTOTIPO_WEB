import 'package:flutter/material.dart';

import '../../models/producto.dart';
import 'detalle_producto_base.dart';

/// Detalle de compra de productos de Streaming.
class DetalleStreamingScreen extends StatelessWidget {
  final Producto producto;

  const DetalleStreamingScreen({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    return DetalleProductoBase(
      producto: producto,
      ruta: 'Streaming',
      insignias: const [
        DetalleItem(Icons.desktop_windows_outlined, 'Servicio premium'),
        DetalleItem(Icons.verified_user_outlined, 'Compra segura'),
        DetalleItem(Icons.inventory_2_outlined, 'Entrega digital'),
        DetalleItem(Icons.headset_mic_outlined, 'Soporte WEIKANG'),
      ],
      descripcion:
          'Recibes un perfil asignado dentro de una cuenta compartida '
          'administrada por WEIKANG SHOP. El acceso queda vinculado a tu '
          'pedido, con seguimiento, indicaciones de uso y soporte durante '
          'todo el período contratado.',
      tarjetas: const [
        DetalleItem(
          Icons.person_outline,
          'Perfil personal asignado',
          'Obtienes un perfil preparado para uso personal. La cuenta continúa '
              'siendo administrada por WEIKANG SHOP.',
        ),
        DetalleItem(
          Icons.devices_other_outlined,
          'Compatible con tus dispositivos',
          'Úsalo en Smart TV, teléfono, tablet o computadora según las '
              'condiciones de la plataforma.',
        ),
        DetalleItem(
          Icons.headset_mic_outlined,
          'Soporte durante tu servicio',
          'Si aparece una incidencia, contacta con soporte antes de '
              'modificar perfiles, credenciales o PIN.',
        ),
      ],
      puntosImportantes: const [
        'La entrega se realiza una vez confirmado el pago.',
        'No cambies correo, contraseña ni PIN del acceso entregado.',
        'El servicio es válido únicamente durante el período contratado.',
        'Ante cualquier problema, contacta a soporte con tu número de pedido.',
      ],
    );
  }
}
