import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Ventana flotante del chat de asistencia (prototipo): muestra mensajes
/// predefinidos y el envío de mensajes está deshabilitado.
class ChatSoporteVentana extends StatelessWidget {
  final VoidCallback onCerrar;

  const ChatSoporteVentana({super.key, required this.onCerrar});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fondo,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.acento.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.acento.withValues(alpha: 0.22),
            blurRadius: 32,
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Colors.black54,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _Cabecera(onCerrar: onCerrar),
          const Expanded(child: _Mensajes()),
          const _Entrada(),
        ],
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  final VoidCallback onCerrar;

  const _Cabecera({required this.onCerrar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A5FB4), Color(0xFF079AEF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                  border: Border.all(color: Colors.white54),
                ),
                child: const Icon(
                  Icons.support_agent,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2EE67A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0A5FB4),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Soporte WEIKANG',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'En línea · Responde en minutos',
                  style: TextStyle(fontSize: 12.5, color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: onCerrar,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _Mensajes extends StatelessWidget {
  const _Mensajes();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.superficie,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Hoy',
              style: TextStyle(fontSize: 12, color: AppColors.textoSecundario),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const _Burbuja(
          texto:
              '¡Hola! 👋 Bienvenido a WEIKANG SHOP. Soy tu asistente virtual.',
          hora: '10:00',
        ),
        const SizedBox(height: 8),
        const _Burbuja(
          texto:
              'Pronto podrás escribirnos aquí para resolver dudas sobre tus '
              'compras, entregas digitales y pagos.',
          hora: '10:00',
        ),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Sugerencia(Icons.bolt, 'Entrega digital'),
            _Sugerencia(Icons.payments_outlined, 'Pagos'),
            _Sugerencia(Icons.receipt_long_outlined, 'Mis compras'),
          ],
        ),
      ],
    );
  }
}

class _Burbuja extends StatelessWidget {
  final String texto;
  final String hora;

  const _Burbuja({required this.texto, required this.hora});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.acento,
          child: Icon(Icons.support_agent, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            decoration: const BoxDecoration(
              color: Color(0xFF142233),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(texto, style: const TextStyle(fontSize: 15, height: 1.4)),
                const SizedBox(height: 4),
                Text(
                  hora,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Atajos decorativos: el prototipo no permite enviar mensajes.
class _Sugerencia extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Sugerencia(this.icono, this.texto);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.acento.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 15, color: AppColors.acento),
            const SizedBox(width: 6),
            Text(
              texto,
              style: const TextStyle(fontSize: 13, color: AppColors.acento),
            ),
          ],
        ),
      ),
    );
  }
}

class _Entrada extends StatelessWidget {
  const _Entrada();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.superficie,
        border: Border(top: BorderSide(color: AppColors.borde)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: AppColors.fondo,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borde),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: AppColors.textoSecundario,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chat disponible próximamente',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.borde.withValues(alpha: 0.7),
            ),
            child: const Icon(
              Icons.send_rounded,
              size: 20,
              color: AppColors.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}
