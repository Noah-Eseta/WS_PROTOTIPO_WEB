import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../logo_marca.dart';

const fondoAutenticacion = Color(0xFF03060A);

class EstructuraAutenticacion extends StatelessWidget {
  final Widget Function(bool conLogo) formulario;
  const EstructuraAutenticacion({super.key, required this.formulario});
  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final dosPaneles = ancho >= 900;

    return Scaffold(
      backgroundColor: fondoAutenticacion,
      body: SafeArea(
        child: Stack(
          children: [
            if (dosPaneles)
              Row(
                children: [
                  const Expanded(
                    flex: 11,
                    child: PanelPresentacionAutenticacion(),
                  ),
                  Container(width: 1, color: AppColors.borde),
                  Expanded(flex: 9, child: formulario(false)),
                ],
              )
            else
              formulario(true),
            if (Navigator.of(context).canPop())
              Positioned(
                left: 8,
                top: 8,
                child: IconButton(
                  tooltip: 'Volver',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FormularioAutenticacion extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool conLogo;
  final List<Widget> children;
  const FormularioAutenticacion({
    super.key,
    required this.formKey,
    required this.conLogo,
    required this.children,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.2,
          colors: [
            AppColors.acento.withValues(alpha: 0.12),
            fondoAutenticacion,
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (conLogo) ...[
                    const Center(child: LogoMarca(tamano: 48)),
                    const SizedBox(height: 28),
                  ],
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EtiquetaAutenticacion extends StatelessWidget {
  final String texto;

  const EtiquetaAutenticacion(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class IconoAutenticacion extends StatelessWidget {
  final IconData icono;
  final double tamano;

  const IconoAutenticacion(this.icono, {super.key, required this.tamano});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: AppColors.acentoSuave,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.acento.withValues(alpha: 0.5)),
      ),
      child: Icon(icono, size: tamano * 0.5, color: AppColors.acento),
    );
  }
}

/// Panel izquierdo: marca, mensaje principal y beneficios.
class PanelPresentacionAutenticacion extends StatelessWidget {
  const PanelPresentacionAutenticacion({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.3, 0.8),
          radius: 0.9,
          colors: [
            AppColors.acento.withValues(alpha: 0.18),
            fondoAutenticacion,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(56, 40, 40, 40),
      child: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LogoMarca(tamano: 44),
                const SizedBox(height: 56),
                const Text(
                  'Todo lo que\nbuscas,',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -1.5,
                  ),
                ),
                const Text(
                  'en un solo lugar.',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -1.5,
                    color: AppColors.acento,
                  ),
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: const Text(
                    'Compra productos y servicios digitales de forma simple, '
                    'rápida y segura. Una sola cuenta para gestionar toda tu '
                    'experiencia en Weikang Shop.',
                    style: TextStyle(
                      color: AppColors.textoSecundario,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const _Beneficio(
                  Icons.dashboard_outlined,
                  'Todo en un solo lugar',
                  'Streaming, software, juegos y servicios digitales desde una misma plataforma.',
                ),
                const _Beneficio(
                  Icons.bolt,
                  'Compra simple y rápida',
                  'Encuentra lo que necesitas y realiza tus pedidos en pocos pasos.',
                ),
                const _Beneficio(
                  Icons.verified_user_outlined,
                  'Tu cuenta, protegida',
                  'Seguridad diseñada para proteger tu acceso y tus operaciones.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Beneficio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String texto;

  const _Beneficio(this.icono, this.titulo, this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          IconoAutenticacion(icono, tamano: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  texto,
                  style: const TextStyle(
                    color: AppColors.textoSecundario,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
