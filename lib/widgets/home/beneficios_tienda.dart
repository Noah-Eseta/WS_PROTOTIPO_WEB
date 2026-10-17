import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

class BeneficiosTienda extends StatelessWidget {
  const BeneficiosTienda({super.key});

  @override
  Widget build(BuildContext context) {
    const beneficios = [
      (
        Icons.bolt,
        'Entrega digital inmediata',
        'Recibe tus productos al instante',
      ),
      (
        Icons.verified_user_outlined,
        'Pagos seguros',
        'Múltiples métodos de pago',
      ),
      (Icons.groups, '5000+ clientes satisfechos', 'Confían en WEIKANG SHOP'),
      (
        Icons.headset_mic_outlined,
        'Soporte 24/7',
        'Te ayudamos en todo momento',
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borde),
          bottom: BorderSide(color: AppColors.borde),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 12,
        children: beneficios.map((beneficio) {
          return SizedBox(
            width: MediaQuery.sizeOf(context).width < 600 ? 230 : 270,
            child: Row(
              children: [
                Icon(beneficio.$1, color: AppColors.acento, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        beneficio.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        beneficio.$3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
