import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../providers/auth_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/autenticacion/estructura_autenticacion.dart';
import '../widgets/pantalla_carga.dart';
import 'registro_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool integrado;
  const LoginScreen({super.key, this.integrado = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
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

  Future<void> _iniciarSesion() async {
    if (ref.read(authProvider).enProceso ||
        !_formKey.currentState!.validate()) {
      return;
    }
    final valido = await ref
        .read(authProvider.notifier)
        .iniciarSesion(
          correo: _emailController.text,
          password: _passwordController.text,
        );
    if (!mounted) return;
    if (!valido) {
      _aviso(
        ref.read(authProvider).error?.mensaje ?? 'No se pudo iniciar sesión.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    _aviso('¡Bienvenido, ${ref.read(authProvider).nombre}!');
    if (!widget.integrado) Navigator.of(context).pop(true);
  }

  Future<void> _registrar() async {
    await Navigator.of(context)
        .push(RutaConCarga(destino: const RegistroScreen()));
    if (mounted && !widget.integrado && ref.read(authProvider).iniciada) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) => EstructuraAutenticacion(
    formulario: (conLogo) => _panelFormulario(conLogo: conLogo),
  );

  Widget _panelFormulario({bool conLogo = false}) => FormularioAutenticacion(
    formKey: _formKey,
    conLogo: conLogo,
    children: [
      const Align(
        alignment: Alignment.centerLeft,
        child: IconoAutenticacion(Icons.person_outline, tamano: 40),
      ),
      const SizedBox(height: 18),
      const Text(
        'Iniciar sesión',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 4),
      const Text(
        'Accede a tu cuenta para continuar',
        style: TextStyle(color: AppColors.textoSecundario, fontSize: 12),
      ),
      const SizedBox(height: 26),
      const EtiquetaAutenticacion('Correo'),
      TextFormField(
        controller: _emailController,
        forceErrorText: ref
            .watch(authProvider)
            .error
            ?.campos['email']
            ?.firstOrNull,
        onChanged: (_) => ref.read(authProvider.notifier).limpiarError(),
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          hintText: 'Tu correo electrónico',
          prefixIcon: Icon(Icons.person_outline, size: 18),
        ),
        validator: (value) {
          final email = value?.trim() ?? '';
          if (email.isEmpty) return 'Ingresa tu correo';
          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
            return 'Correo no válido';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      const EtiquetaAutenticacion('Contraseña'),
      TextFormField(
        controller: _passwordController,
        forceErrorText: ref
            .watch(authProvider)
            .error
            ?.campos['password']
            ?.firstOrNull,
        onChanged: (_) => ref.read(authProvider.notifier).limpiarError(),
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _iniciarSesion(),
        obscureText: !_mostrarPassword,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          hintText: 'Tu contraseña',
          prefixIcon: const Icon(Icons.lock_outline, size: 18),
          suffixIcon: IconButton(
            tooltip: _mostrarPassword
                ? 'Ocultar contraseña'
                : 'Mostrar contraseña',
            onPressed: () =>
                setState(() => _mostrarPassword = !_mostrarPassword),
            icon: Icon(
              _mostrarPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
            ),
          ),
        ),
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Ingresa tu contraseña' : null,
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: ref.watch(authProvider).enProceso ? null : _iniciarSesion,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Iniciar sesión'),
            SizedBox(width: 8),
            if (ref.watch(authProvider).enProceso)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.chevron_right, size: 18),
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
              style: TextStyle(color: AppColors.textoSecundario, fontSize: 11),
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
            style: TextStyle(color: AppColors.textoSecundario, fontSize: 12),
          ),
          InkWell(
            onTap: ref.watch(authProvider).enProceso ? null : _registrar,
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
  );
}
