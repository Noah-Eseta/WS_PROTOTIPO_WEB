import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Da a las tarjetas clicables un resaltado suave al pasar el ratón.
class TarjetaInteractiva extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double radio;

  const TarjetaInteractiva({
    super.key,
    required this.child,
    required this.onTap,
    required this.radio,
  });

  @override
  State<TarjetaInteractiva> createState() => _TarjetaInteractivaState();
}

class _TarjetaInteractivaState extends State<TarjetaInteractiva> {
  bool _encima = false;

  @override
  Widget build(BuildContext context) {
    final activa = _encima && widget.onTap != null;
    const duracion = Duration(milliseconds: 180);

    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _encima = true),
      onExit: (_) => setState(() => _encima = false),
      child: AnimatedScale(
        scale: activa ? 1.015 : 1,
        duration: duracion,
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: duracion,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radio),
            boxShadow: [
              BoxShadow(
                color: activa
                    ? AppColors.acento.withValues(alpha: 0.24)
                    : Colors.transparent,
                blurRadius: activa ? 20 : 0,
                offset: Offset(0, activa ? 6 : 0),
              ),
            ],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radio),
            border: Border.all(
              color: activa ? AppColors.acento : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(widget.radio),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
