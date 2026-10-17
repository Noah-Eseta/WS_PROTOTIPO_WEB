import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/sesion_service.dart';
import '../widgets/logo_marca.dart';

const _fondoLogin = Color(0xFF03060A);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _mostrarPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  void _iniciarSesion() {
    if (!_formKey.currentState!.validate()) return;
    final valido = SesionService.instancia.iniciarSesion(
      _emailController.text,
      _passwordController.text,
    );
    if (!valido) {
      _aviso('Correo o contraseña incorrectos');
      return;
    }
    FocusScope.of(context).unfocus();
    _aviso('¡Bienvenido, Prueba!');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final dosPaneles = ancho >= 900;

    return Scaffold(
      backgroundColor: _fondoLogin,
      body: SafeArea(
        child: Stack(
          children: [
            if (dosPaneles)
              Row(
                children: [
                  const Expanded(flex: 11, child: _PanelPresentacion()),
                  Container(width: 1, color: AppColors.borde),
                  Expanded(flex: 9, child: _panelFormulario()),
                ],
              )
            else
              _panelFormulario(conLogo: true),
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

  Widget _panelFormulario({bool conLogo = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.2,
          colors: [AppColors.acento.withValues(alpha: 0.12), _fondoLogin],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (conLogo) ...[
                    const Center(child: LogoMarca(tamano: 48)),
                    const SizedBox(height: 28),
                  ],
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: _IconoCaja(Icons.person_outline, tamano: 40),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Iniciar sesión',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Accede a tu cuenta para continuar',
                    style: TextStyle(
                      color: AppColors.textoSecundario,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const _Etiqueta('Correo'),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Tu correo electrónico',
                      prefixIcon: Icon(Icons.person_outline, size: 18),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) return 'Ingresa tu correo';
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(email)) {
                        return 'Correo no válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const _Etiqueta('Contraseña'),
                  TextFormField(
                    controller: _passwordController,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _iniciarSesion(),
                    obscureText: !_mostrarPassword,
                    decoration: InputDecoration(
                      hintText: 'Tu contraseña',
                      prefixIcon: const Icon(Icons.lock_outline, size: 18),
                      suffixIcon: IconButton(
                        tooltip: _mostrarPassword
                            ? 'Ocultar contraseña'
                            : 'Mostrar contraseña',
                        onPressed: () => setState(
                          () => _mostrarPassword = !_mostrarPassword,
                        ),
                        icon: Icon(
                          _mostrarPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                        ),
                      ),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Ingresa tu contraseña'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _iniciarSesion,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Iniciar sesión'),
                        SizedBox(width: 8),
                        Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.borde)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'o continúa con',
                          style: TextStyle(
                            color: AppColors.textoSecundario,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.borde)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _aviso('Google pendiente de implementar'),
                    icon: const Icon(Icons.g_mobiledata, size: 26),
                    label: const Text('Continuar con Google'),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        '¿No tienes cuenta? ',
                        style: TextStyle(
                          color: AppColors.textoSecundario,
                          fontSize: 12,
                        ),
                      ),
                      InkWell(
                        onTap: () =>
                            _aviso('Registro pendiente de implementar'),
                        child: const Text(
                          'Regístrate aquí',
                          style: TextStyle(
                            color: AppColors.acento,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;

  const _Etiqueta(this.texto);

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

class _IconoCaja extends StatelessWidget {
  final IconData icono;
  final double tamano;

  const _IconoCaja(this.icono, {required this.tamano});

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
class _PanelPresentacion extends StatelessWidget {
  const _PanelPresentacion();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.3, 0.8),
          radius: 0.9,
          colors: [AppColors.acento.withValues(alpha: 0.18), _fondoLogin],
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
          _IconoCaja(icono, tamano: 38),
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
