import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Estructura común de las pantallas: fondo, área segura, contenido centrado
/// con ancho máximo y desplazamiento.
class PantallaBase extends StatelessWidget {
  final Widget child;
  final double maxAncho;
  final Widget? floatingActionButton;

  const PantallaBase({
    super.key,
    required this.child,
    this.maxAncho = 1440,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxAncho),
            child: child,
          ),
        ),
      ),
    );
  }
}
