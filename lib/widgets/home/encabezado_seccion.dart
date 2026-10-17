import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

class EncabezadoSeccion extends StatelessWidget {
  final double margen;
  final IconData icono;
  final Color? color;
  final String titulo;
  final String subtitulo;
  final Widget trailing;

  const EncabezadoSeccion({
    super.key,
    required this.margen,
    required this.icono,
    this.color,
    required this.titulo,
    required this.subtitulo,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(margen, 18, margen, 10),
      child: Row(
        children: [
          Icon(
            icono,
            color:
                color ??
                (icono == Icons.star
                    ? const Color(0xFFFFC928)
                    : const Color(0xFFFF613D)),
            size: 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    color: AppColors.textoSecundario,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class BotonVerTodo extends StatelessWidget {
  final VoidCallback onTap;

  const BotonVerTodo({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.arrow_forward, size: 16),
      label: const Text('Ver todas', style: TextStyle(fontSize: 14)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        side: const BorderSide(color: AppColors.acento),
        foregroundColor: AppColors.acento,
      ),
    );
  }
}
