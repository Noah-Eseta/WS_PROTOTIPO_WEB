import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class LogoMarca extends StatelessWidget {
  final double tamano;
  final bool mostrarNombre;
  final bool compacto;

  const LogoMarca({
    super.key,
    this.tamano = 38,
    this.mostrarNombre = true,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: tamano,
          height: tamano,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tamano * 0.25),
            color: const Color(0xFF06172B),
            border: Border.all(color: AppColors.acento.withValues(alpha: 0.8)),
            boxShadow: [
              BoxShadow(
                color: AppColors.acento.withValues(alpha: 0.18),
                blurRadius: 12,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/Logotipos/logo.webp',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Center(
              child: Text(
                'W3',
                style: TextStyle(
                  color: AppColors.acento,
                  fontWeight: FontWeight.w900,
                  fontSize: tamano * 0.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ),
        if (mostrarNombre) ...[
          SizedBox(width: compacto ? 6 : 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (compacto)
                const SizedBox(
                  width: 108,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'WEIKANG SHOP',
                      maxLines: 1,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                )
              else
                const Text(
                  'WEIKANG SHOP',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              if (!compacto) ...[
                const SizedBox(height: 2),
                const Text(
                  'PLATAFORMA DIGITAL',
                  style: TextStyle(
                    color: AppColors.textoSecundario,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
