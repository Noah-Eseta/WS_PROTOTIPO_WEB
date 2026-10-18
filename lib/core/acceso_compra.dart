import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/login_screen.dart';
import '../providers/auth_provider.dart';
import '../widgets/pantalla_carga.dart';

/// Conserva el flujo de compra; la sesión se consulta en el scope de la tienda.
Future<bool> solicitarSesionParaComprar(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  if (container.read(authProvider.notifier).verificarVigencia()) return true;

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
  return context.mounted &&
      container.read(authProvider.notifier).verificarVigencia();
}
