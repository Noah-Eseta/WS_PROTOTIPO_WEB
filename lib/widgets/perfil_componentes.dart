import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Elementos visuales compartidos por las secciones del panel de cuenta.
class PerfilEstilo {
  static const textoSuave = Color(0xFFACC0DA);
  static const borde = Color(0xFF214463);
  static const fondo = Color(0xFF101D30);
}

class PerfilEncabezado extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final String etiqueta;

  const PerfilEncabezado({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.icono,
    this.etiqueta = 'MI CUENTA',
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: LayoutBuilder(
      builder: (context, constraints) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WEIKANG SHOP  /  $etiqueta',
                  style: const TextStyle(
                    color: AppColors.acento,
                    fontSize: 11,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: constraints.maxWidth < 500 ? 32 : 40,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  descripcion,
                  style: const TextStyle(
                    color: PerfilEstilo.textoSuave,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (constraints.maxWidth >= 600) ...[
            const SizedBox(width: 24),
            PerfilIcono(icono: icono, tamano: 68),
          ],
        ],
      ),
    ),
  );
}

class PerfilPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const PerfilPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: PerfilEstilo.borde),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF101D30), Color(0xFF0B1728)],
      ),
    ),
    child: child,
  );
}

class PerfilIcono extends StatelessWidget {
  final IconData icono;
  final Color color;
  final double tamano;

  const PerfilIcono({
    super.key,
    required this.icono,
    this.color = AppColors.acento,
    this.tamano = 48,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: tamano,
    height: tamano,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(tamano * .26),
      border: Border.all(color: color.withValues(alpha: .25)),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: .22), color.withValues(alpha: .04)],
      ),
    ),
    child: Icon(icono, color: color, size: tamano * .5),
  );
}

class PerfilMetrica extends StatelessWidget {
  final String titulo;
  final String valor;
  final String detalle;
  final IconData icono;
  final Color color;

  const PerfilMetrica({
    super.key,
    required this.titulo,
    required this.valor,
    required this.detalle,
    required this.icono,
    this.color = AppColors.acento,
  });

  @override
  Widget build(BuildContext context) => PerfilPanel(
    padding: const EdgeInsets.all(20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PerfilIcono(icono: icono, color: color),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(color: PerfilEstilo.textoSuave),
              ),
              const SizedBox(height: 6),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detalle,
                style: const TextStyle(
                  color: PerfilEstilo.textoSuave,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class PerfilMetricas extends StatelessWidget {
  final List<Widget> children;

  const PerfilMetricas({super.key, required this.children});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columnas = (constraints.maxWidth / 280).floor().clamp(
        1,
        children.length,
      );
      final ancho = (constraints.maxWidth - 16 * (columnas - 1)) / columnas;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final child in children) SizedBox(width: ancho, child: child),
        ],
      );
    },
  );
}

class PerfilVacio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final String? imagen;
  final Widget? accion;

  const PerfilVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    this.imagen,
    this.accion,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 8),
    child: Column(
      children: [
        if (imagen != null)
          Image.asset(imagen!, width: 132, height: 122, fit: BoxFit.contain)
        else
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.acento.withValues(alpha: .13),
              ),
              gradient: RadialGradient(
                colors: [
                  AppColors.acento.withValues(alpha: .18),
                  Colors.transparent,
                ],
              ),
            ),
            child: PerfilIcono(icono: icono, tamano: 64),
          ),
        const SizedBox(height: 18),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            descripcion,
            textAlign: TextAlign.center,
            style: const TextStyle(color: PerfilEstilo.textoSuave, height: 1.5),
          ),
        ),
        if (accion != null) ...[const SizedBox(height: 22), accion!],
      ],
    ),
  );
}

class PerfilEtiqueta extends StatelessWidget {
  final String texto;
  final Color color;

  const PerfilEtiqueta({
    super.key,
    required this.texto,
    this.color = AppColors.acento,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      border: Border.all(color: color.withValues(alpha: .25)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      texto,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}
