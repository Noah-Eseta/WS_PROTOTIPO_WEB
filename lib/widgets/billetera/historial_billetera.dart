import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/billetera.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/auth_provider.dart';
import '../perfil_componentes.dart';

class EstadoWallet<T> extends StatelessWidget {
  final AsyncValue<T> valor;
  final VoidCallback reintentar;
  final Widget Function(T) builder;
  const EstadoWallet({
    super.key,
    required this.valor,
    required this.reintentar,
    required this.builder,
  });
  @override
  Widget build(BuildContext context) {
    if (valor.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (valor.hasError) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(mensajeWallet(valor.error!), textAlign: TextAlign.center),
          TextButton(onPressed: reintentar, child: const Text('Reintentar')),
        ],
      );
    }
    return builder(valor.requireValue);
  }
}

class HistorialBilletera extends ConsumerStatefulWidget {
  final int usuario;
  const HistorialBilletera({super.key, required this.usuario});
  @override
  ConsumerState<HistorialBilletera> createState() => _HistorialBilleteraState();
}

class _HistorialBilleteraState extends ConsumerState<HistorialBilletera> {
  bool _cargando = false;
  String? _error;
  Future<void> _mas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await ref
          .read(movimientosWalletProvider(widget.usuario).notifier)
          .siguiente();
    } catch (error) {
      if (mounted) setState(() => _error = mensajeWallet(error));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) => EstadoWallet(
    valor: ref.watch(movimientosWalletProvider(widget.usuario)),
    reintentar: () => ref.invalidate(movimientosWalletProvider(widget.usuario)),
    builder: (pagina) => PerfilPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Historial de movimientos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Créditos ficticios y ajustes de demostración. No son pagos ni compras.',
          ),
          const SizedBox(height: 12),
          if (pagina.elementos.isEmpty)
            const Text('Sin movimientos de billetera.'),
          for (final movimiento in pagina.elementos) ...[
            const Divider(color: PerfilEstilo.borde),
            MovimientoBilleteraFila(movimiento: movimiento),
          ],
          const SizedBox(height: 8),
          Text(
            '${pagina.elementos.length} movimiento(s) cargado(s). No es un total histórico.',
          ),
          if (_error != null) Text(_error!),
          if (pagina.siguiente != null)
            TextButton(
              onPressed: _cargando ? null : _mas,
              child: Text(_cargando ? 'Cargando…' : 'Cargar más movimientos'),
            ),
        ],
      ),
    ),
  );
}

class MovimientoBilleteraFila extends StatelessWidget {
  final MovimientoBilletera movimiento;
  const MovimientoBilleteraFila({super.key, required this.movimiento});
  @override
  Widget build(BuildContext context) {
    final fecha = movimiento.fecha.toLocal();
    String dos(int n) => n.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              Text(
                movimiento.titulo,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${movimiento.centimos > 0 ? '+ ' : ''}${formatoCentimos(movimiento.centimos)}',
                style: const TextStyle(
                  color: Color(0xFF53D9B0),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(movimiento.descripcion),
          const SizedBox(height: 4),
          Text(
            '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} ${dos(fecha.hour)}:${dos(fecha.minute)}',
            style: const TextStyle(
              color: PerfilEstilo.textoSuave,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class SaldoWalletTexto extends ConsumerWidget {
  final TextStyle? estilo;
  const SaldoWalletTexto({super.key, this.estilo});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(authProvider.select((s) => s.usuario?.id));
    if (id == null) return const SizedBox.shrink();
    final saldo = ref.watch(walletProvider(id));
    return Text(
      saldo.isLoading
          ? 'Cargando…'
          : saldo.hasError
          ? 'Ver saldo'
          : datosWallet(saldo) == null
          ? 'Ver saldo'
          : formatoCentimos(datosWallet(saldo)!.centimos),
      style: estilo,
    );
  }
}
