import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class BarraSuperior extends StatelessWidget {
  const BarraSuperior({super.key});

  @override
  Widget build(BuildContext context) {
    const estilo = TextStyle(color: AppColors.textoSecundario, fontSize: 11);
    Widget item(IconData i, String t) => Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Row(
        children: [
          Icon(i, size: 13, color: AppColors.acento),
          const SizedBox(width: 5),
          Text(t, style: estilo),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borde)),
      ),
      child: Row(
        children: [
          item(Icons.local_fire_department_outlined, 'Ofertas diarias'),
          item(Icons.headset_mic_outlined, 'Soporte al cliente'),
          item(Icons.verified_user_outlined, 'Compra segura'),
          item(Icons.bolt, 'Entrega digital'),
          const Spacer(),
          const Text('ES / PEN', style: estilo),
        ],
      ),
    );
  }
}
