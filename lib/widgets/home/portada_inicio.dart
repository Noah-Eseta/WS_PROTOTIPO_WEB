import 'package:flutter/material.dart';

import '../banner_bienvenida.dart';
import 'promociones_laterales.dart';

class PortadaInicio extends StatelessWidget {
  final bool compacto;
  final double margen;
  final double ancho;
  final VoidCallback onOfertas;
  final VoidCallback onBeneficios;
  final VoidCallback onColaboradores;
  final VoidCallback onApp;

  const PortadaInicio({
    super.key,
    required this.compacto,
    required this.margen,
    required this.ancho,
    required this.onOfertas,
    required this.onBeneficios,
    required this.onColaboradores,
    required this.onApp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(margen, 14, margen, 0),
      child: ancho >= 950
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: BannerBienvenida(
                    compacto: false,
                    onExplorar: onOfertas,
                    onBeneficios: onBeneficios,
                    onColaboradores: onColaboradores,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 270,
                  height: 340,
                  child: PromocionesLaterales(
                    horizontal: false,
                    onApp: onApp,
                    onOfertas: onOfertas,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BannerBienvenida(
                  compacto: compacto,
                  onExplorar: onOfertas,
                  onBeneficios: onBeneficios,
                  onColaboradores: onColaboradores,
                ),
                if (ancho >= 600) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 104,
                    child: PromocionesLaterales(
                      horizontal: true,
                      onApp: onApp,
                      onOfertas: onOfertas,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
