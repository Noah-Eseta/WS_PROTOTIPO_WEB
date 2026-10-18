import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/carrito_provider.dart';
import '../../core/formato.dart';

class EstadoSincronizacionCarrito extends ConsumerWidget {
  const EstadoSincronizacionCarrito({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(carritoProvider);
    if (estado.usuarioId == null && !estado.fusionPendiente) {
      return estado.vacio
          ? const SizedBox.shrink()
          : const Text(
              'Carrito visitante · se conserva mientras esta aplicación siga abierta.',
            );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (estado.sincronizando)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            Text(
              estado.sincronizando
                  ? 'Sincronizando carrito…'
                  : estado.version == null
                  ? 'Carrito de tu cuenta pendiente de consulta'
                  : 'Carrito de tu cuenta',
            ),
            TextButton(
              onPressed: estado.sincronizando
                  ? null
                  : () => ref.read(carritoProvider.notifier).actualizar(),
              child: const Text('Actualizar'),
            ),
          ],
        ),
        if (estado.remotos.isNotEmpty && estado.locales.isNotEmpty)
          Text(
            'Cuenta: ${formatoPrecio(estado.remotos.fold(0, (s, i) => s + i.subtotal))} · Selección local: ${formatoPrecio(estado.locales.fold(0, (s, i) => s + i.subtotal))}',
          ),
        if (estado.fusionPendiente ||
            estado.locales.any((i) => i.producto.sincronizable))
          const Text(
            'Selecciones de visitante pendientes de fusión. Se conservan hasta confirmar el resultado.',
          ),
        if (estado.error != null) Text(estado.error!.mensaje),
        if (estado.error != null || estado.fusionPendiente)
          TextButton(
            onPressed: estado.sincronizando
                ? null
                : () => ref.read(carritoProvider.notifier).sincronizar(),
            child: const Text('Reintentar sincronización'),
          ),
      ],
    );
  }
}
