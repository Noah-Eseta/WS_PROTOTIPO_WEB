import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../chat_soporte_ventana.dart';

/// Controla la apertura y el hover del soporte sin reconstruir el catalogo.
class SoporteFlotante extends StatefulWidget {
  const SoporteFlotante({super.key});

  @override
  State<SoporteFlotante> createState() => _SoporteFlotanteState();
}

class _SoporteFlotanteState extends State<SoporteFlotante> {
  bool _chatAbierto = false;
  bool _soporteHover = false;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _chatAbierto
              ? Padding(
                  key: const ValueKey('chat-abierto'),
                  padding: const EdgeInsets.only(bottom: 14),
                  child: SizedBox(
                    width: ancho < 420 ? ancho - 32 : 380,
                    height: (MediaQuery.sizeOf(context).height - 190).clamp(
                      220.0,
                      480.0,
                    ),
                    child: ChatSoporteVentana(
                      onCerrar: () => setState(() => _chatAbierto = false),
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('chat-cerrado')),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _soporteHover = true),
          onExit: (_) => setState(() => _soporteHover = false),
          child: AnimatedScale(
            scale: _soporteHover ? 1.08 : 1,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: FloatingActionButton(
              backgroundColor: AppColors.acento,
              foregroundColor: Colors.white,
              tooltip: null,
              onPressed: () => setState(() => _chatAbierto = !_chatAbierto),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  key: ValueKey(_chatAbierto),
                  _chatAbierto ? Icons.close : Icons.headset_mic_outlined,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
