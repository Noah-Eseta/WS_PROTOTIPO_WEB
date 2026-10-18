import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/billetera.dart';
import '../../providers/admin_wallet_provider.dart';
import '../../providers/wallet_provider.dart';
import '../perfil_componentes.dart';

class FormularioCredito extends ConsumerStatefulWidget {
  final int destinatario;
  const FormularioCredito({super.key, required this.destinatario});
  @override
  ConsumerState<FormularioCredito> createState() => _FormularioCreditoState();
}

class _FormularioCreditoState extends ConsumerState<FormularioCredito> {
  final _formulario = GlobalKey<FormState>();
  final _importe = TextEditingController(), _motivo = TextEditingController();
  @override
  void initState() {
    super.initState();
    final intento = ref.read(creditoWalletProvider).intento;
    if (intento?.destinatario == widget.destinatario) {
      _importe.text =
          '${intento!.centimos ~/ 100}.${(intento.centimos % 100).toString().padLeft(2, '0')}';
      _motivo.text = intento.justificacion;
    }
  }

  @override
  void dispose() {
    _importe.dispose();
    _motivo.dispose();
    super.dispose();
  }

  void _enviar() {
    if (!(_formulario.currentState?.validate() ?? false)) return;
    ref
        .read(creditoWalletProvider.notifier)
        .acreditar(
          destinatario: widget.destinatario,
          centimos: centimosCredito(_importe.text)!,
          justificacion: _motivo.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(creditoWalletProvider);
    final autorizado = datosWallet(ref.watch(permisoAdminProvider)) == true;
    final otro =
        estado.intento != null &&
        estado.intento!.destinatario != widget.destinatario;
    final bloqueado =
        estado.enviando || estado.incierto || estado.recibo != null || otro;
    return PerfilPanel(
      child: Form(
        key: _formulario,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Créditos ficticios',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            const Text(
              'Asignación administrativa en PEN. No representa dinero real.',
            ),
            const SizedBox(height: 22),
            TextFormField(
              key: const ValueKey('credito-importe'),
              controller: _importe,
              readOnly: bloqueado,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Importe ficticio (S/)',
                helperText: 'De S/ 0.01 a S/ 10,000.00',
                errorText: estado.error?.campos['amount_cents']?.first,
              ),
              validator: (v) => centimosCredito(v ?? '') == null
                  ? 'Ingresa entre S/ 0.01 y S/ 10,000.00.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('credito-motivo'),
              controller: _motivo,
              readOnly: bloqueado,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Justificación',
                errorText: estado.error?.campos['reason']?.first,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty || v.trim().runes.length > 500
                  ? 'Escribe una justificación de hasta 500 caracteres.'
                  : null,
            ),
            const SizedBox(height: 16),
            if (estado.error != null) ...[
              Text(estado.error!.mensaje),
              const SizedBox(height: 12),
            ],
            if (otro)
              const Text(
                'Hay una operación de otra cuenta pendiente. Retómala antes de iniciar un nuevo crédito.',
              ),
            if (estado.incierto)
              const Text(
                'El servidor puede haber aplicado el crédito. Reintentar conserva el mismo identificador y contenido.',
              ),
            if (estado.recibo != null && !otro) ...[
              const Text(
                'Crédito ficticio confirmado. Consulta el saldo actualizado arriba.',
              ),
              if (estado.recibo!.repetido)
                const Text(
                  'Se recuperó el comprobante original; no se creó otro crédito.',
                ),
              SelectableText('Operación: ${estado.recibo!.operacion}'),
              if (estado.aviso != null) Text(estado.aviso!),
              TextButton(
                onPressed: () {
                  ref.read(creditoWalletProvider.notifier).nuevaOperacion();
                  _importe.clear();
                  _motivo.clear();
                },
                child: const Text('Nueva operación'),
              ),
            ] else
              FilledButton.icon(
                key: const ValueKey('credito-enviar'),
                onPressed: estado.enviando || otro || !autorizado
                    ? null
                    : _enviar,
                icon: estado.enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_card_outlined),
                label: Text(
                  estado.enviando
                      ? 'Confirmando…'
                      : estado.incierto
                      ? 'Reintentar la misma operación'
                      : 'Asignar crédito ficticio',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
