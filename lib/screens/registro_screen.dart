import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../widgets/autenticacion/estructura_autenticacion.dart';

class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});
  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _password = TextEditingController();
  final _confirmacion = TextEditingController();
  bool _mostrar = false;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _password.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (ref.read(authProvider).enProceso || !_form.currentState!.validate()) {
      return;
    }
    final ok = await ref
        .read(authProvider.notifier)
        .registrar(
          nombre: _nombre.text,
          correo: _correo.text,
          password: _password.text,
          confirmacion: _confirmacion.text,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(authProvider).error?.mensaje ??
                'No se pudo registrar la cuenta.',
          ),
        ),
      );
    }
  }

  Widget _campo(
    String etiqueta,
    String clave,
    TextEditingController controller,
    String? Function(String?) validar, {
    bool secreto = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      EtiquetaAutenticacion(etiqueta),
      TextFormField(
        controller: controller,
        obscureText: secreto && !_mostrar,
        forceErrorText: ref
            .watch(authProvider)
            .error
            ?.campos[clave]
            ?.firstOrNull,
        onChanged: (_) => ref.read(authProvider.notifier).limpiarError(),
        keyboardType: clave == 'email'
            ? TextInputType.emailAddress
            : TextInputType.text,
        autocorrect: !secreto,
        enableSuggestions: !secreto,
        textInputAction: clave == 'password_confirmation'
            ? TextInputAction.done
            : TextInputAction.next,
        onFieldSubmitted: clave == 'password_confirmation'
            ? (_) => _registrar()
            : null,
        decoration: InputDecoration(
          hintText: etiqueta,
          prefixIcon: Icon(
            secreto ? Icons.lock_outline : Icons.person_outline,
            size: 18,
          ),
          suffixIcon: secreto
              ? IconButton(
                  tooltip: _mostrar
                      ? 'Ocultar contraseña'
                      : 'Mostrar contraseña',
                  onPressed: () => setState(() => _mostrar = !_mostrar),
                  icon: Icon(
                    _mostrar
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                  ),
                )
              : null,
        ),
        validator: validar,
      ),
      const SizedBox(height: 16),
    ],
  );

  @override
  Widget build(BuildContext context) => EstructuraAutenticacion(
    formulario: (conLogo) => FormularioAutenticacion(
      formKey: _form,
      conLogo: conLogo,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: IconoAutenticacion(Icons.person_add_outlined, tamano: 40),
        ),
        const SizedBox(height: 18),
        const Text(
          'Crear cuenta',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 26),
        _campo(
          'Nombre',
          'name',
          _nombre,
          (v) => (v?.trim().isEmpty ?? true)
              ? 'Ingresa tu nombre'
              : v!.trim().runes.length > 255
              ? 'El nombre no puede superar 255 caracteres'
              : null,
        ),
        _campo(
          'Correo',
          'email',
          _correo,
          (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v?.trim() ?? '')
              ? null
              : 'Correo no válido',
        ),
        _campo(
          'Contraseña',
          'password',
          _password,
          (v) => (v?.runes.length ?? 0) >= 12
              ? null
              : 'La contraseña debe tener al menos 12 caracteres',
          secreto: true,
        ),
        _campo(
          'Confirmar contraseña',
          'password_confirmation',
          _confirmacion,
          (v) => v == _password.text && (v?.isNotEmpty ?? false)
              ? null
              : 'La confirmación de contraseña no coincide',
          secreto: true,
        ),
        FilledButton(
          onPressed: ref.watch(authProvider).enProceso ? null : _registrar,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Crear cuenta'),
              const SizedBox(width: 8),
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
        const SizedBox(height: 14),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Ya tengo cuenta. Iniciar sesión'),
        ),
      ],
    ),
  );
}
