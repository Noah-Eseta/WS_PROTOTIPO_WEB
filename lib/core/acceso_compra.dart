import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../services/sesion_service.dart';
import '../widgets/pantalla_carga.dart';

/// Solicita una cuenta local antes de continuar con una acción de compra.
Future<bool> solicitarSesionParaComprar(BuildContext context) async {
  if (SesionService.instancia.iniciada) return true;

  final irALogin = await showDialog<bool>(
    context: context,
    builder: (dialogo) => AlertDialog(
      title: const Text('Inicia sesión para comprar'),
      content: const Text(
        'Necesitas una cuenta para añadir productos y completar pedidos.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogo).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogo).pop(true),
          child: const Text('Iniciar sesión'),
        ),
      ],
    ),
  );
  if (irALogin != true || !context.mounted) return false;

  await Navigator.of(context).push(RutaConCarga(destino: const LoginScreen()));
  return context.mounted && SesionService.instancia.iniciada;
}
