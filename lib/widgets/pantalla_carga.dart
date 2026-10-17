import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'logo_marca.dart';

/// Ruta que muestra una pantalla de carga breve antes de mostrar [destino].
/// Se usa en lugar de MaterialPageRoute en cada cambio de pantalla.
class RutaConCarga<T> extends PageRouteBuilder<T> {
  RutaConCarga({
    required Widget destino,
    Duration duracion = const Duration(milliseconds: 700),
  }) : super(
         pageBuilder: (_, _, _) =>
             PantallaConCarga(duracion: duracion, destino: destino),
         transitionDuration: const Duration(milliseconds: 250),
         reverseTransitionDuration: duracion,
         transitionsBuilder: (_, animation, _, child) => AnimatedBuilder(
           animation: animation,
           child: child,
           builder: (_, contenido) {
             if (animation.status == AnimationStatus.reverse) {
               return const PantallaCarga();
             }
             return FadeTransition(opacity: animation, child: contenido);
           },
         ),
       );
}

/// Muestra la carga inicial antes de presentar el contenido.
class PantallaConCarga extends StatefulWidget {
  final Duration duracion;
  final Widget destino;

  const PantallaConCarga({
    super.key,
    this.duracion = const Duration(milliseconds: 700),
    required this.destino,
  });

  @override
  State<PantallaConCarga> createState() => _CargaTransitoriaState();
}

class _CargaTransitoriaState extends State<PantallaConCarga> {
  bool _listo = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.duracion, () {
      if (mounted) setState(() => _listo = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _listo
          ? KeyedSubtree(key: const ValueKey('destino'), child: widget.destino)
          : const PantallaCarga(key: ValueKey('carga')),
    );
  }
}

class PantallaCarga extends StatelessWidget {
  const PantallaCarga({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.fondo,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LogoMarca(tamano: 64),
            SizedBox(height: 28),
            SizedBox(
              width: 150,
              child: LinearProgressIndicator(
                minHeight: 3,
                color: AppColors.acento,
                backgroundColor: AppColors.borde,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
