import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../tarjeta_interactiva.dart';

class PromocionesLaterales extends StatelessWidget {
  final bool horizontal;
  final VoidCallback onApp;
  final VoidCallback onOfertas;

  const PromocionesLaterales({
    super.key,
    required this.horizontal,
    required this.onApp,
    required this.onOfertas,
  });

  @override
  Widget build(BuildContext context) {
    return horizontal
        ? Row(
            children: [
              Expanded(
                child: _PromoCard(
                  imagen: 'assets/images/Banners/promo_app.png',
                  titulo: 'DESCARGA LA APP',
                  texto: 'Compra más rápido desde tu celular',
                  onTap: onApp,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PromoCard(
                  imagen: 'assets/images/Banners/promo_ofertas.png',
                  titulo: 'OFERTAS DIARIAS',
                  texto: 'Hasta 50% OFF',
                  onTap: onOfertas,
                ),
              ),
            ],
          )
        : Column(
            children: [
              Expanded(
                child: _PromoCard(
                  imagen: 'assets/images/Banners/promo_app.png',
                  titulo: 'DESCARGA LA APP',
                  texto: 'Compra más rápido desde tu celular',
                  onTap: onApp,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _PromoCard(
                  imagen: 'assets/images/Banners/promo_ofertas.png',
                  titulo: 'OFERTAS DIARIAS',
                  texto: 'Hasta 50% OFF',
                  onTap: onOfertas,
                ),
              ),
            ],
          );
  }
}

class _PromoCard extends StatelessWidget {
  final String imagen;
  final String titulo;
  final String texto;
  final VoidCallback onTap;

  const _PromoCard({
    required this.imagen,
    required this.titulo,
    required this.texto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TarjetaInteractiva(
      onTap: onTap,
      radio: 12,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.acento.withValues(alpha: 0.55)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(imagen, fit: BoxFit.cover, alignment: Alignment.center),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xED07172B),
                    Color(0xA607172B),
                    Color(0x0007172B),
                  ],
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: constraints.maxWidth * 0.64,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            color: AppColors.acento,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          texto,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
