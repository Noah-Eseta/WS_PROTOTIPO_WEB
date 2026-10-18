import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../widgets/autenticacion/acceso_autenticado.dart';

import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/formato.dart';
import '../services/saldo_service.dart';
import '../widgets/pantalla_carga.dart';
import '../widgets/pie_tienda.dart';

const _fondoPanel = Color(0xFF101D30);
const _bordePanel = Color(0xFF214463);

class SaldoScreen extends ConsumerStatefulWidget {
  const SaldoScreen({super.key});

  @override
  ConsumerState<SaldoScreen> createState() => _SaldoScreenState();
}

class _SaldoScreenState extends ConsumerState<SaldoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _monto = TextEditingController();
  String? _metodo;

  @override
  void initState() {
    super.initState();
    ref.listenManual(authProvider.select((s) => s.usuario?.id), (_, _) {
      _monto.clear();
      setState(() => _metodo = null);
    });
  }

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  int? get _centimosIngresados {
    final texto = _monto.text.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(texto)) return null;
    final valor = double.tryParse(texto);
    if (valor == null || valor <= 0 || valor > 1000) return null;
    return (valor * 100).round();
  }

  void _recargar() {
    if (!ref.read(authProvider.notifier).verificarVigencia()) return;
    if (!_formKey.currentState!.validate()) return;
    if (_metodo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un método de pago')),
      );
      return;
    }
    final recarga = SaldoService.instancia.recargar(
      centimos: _centimosIngresados!,
      metodoPago: _metodo!,
    );
    Navigator.of(context).pushReplacement(
      RutaConCarga(
        destino: SaldoAgregadoScreen(
          recarga: recarga,
          usuarioId: ref.read(authProvider).usuario!.id,
        ),
      ),
    );
  }

  IconData _iconoMetodo(String metodo) => switch (metodo) {
    'Binance' => Icons.currency_exchange_rounded,
    'VISA' || 'Mastercard' => Icons.credit_card_rounded,
    'Yape' || 'Plin' => Icons.phone_iphone_rounded,
    _ => Icons.account_balance_wallet_outlined,
  };

  String _detalleMetodo(String metodo) => switch (metodo) {
    'Binance' => 'Billetera digital',
    'VISA' || 'Mastercard' => 'Tarjeta de crédito o débito',
    'Yape' || 'Plin' => 'Pago con tu celular',
    _ => 'Billetera del dispositivo',
  };

  @override
  Widget build(BuildContext context) {
    return AccesoAutenticado(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Agregar saldo'),
          backgroundColor: const Color(0xFF0B1728),
          surfaceTintColor: Colors.transparent,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: _bordePanel),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 44),
              children: [
                const Text(
                  'WEIKANG SHOP  /  BILLETERA',
                  style: TextStyle(
                    color: AppColors.acento,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Recarga de demostración',
                  style: TextStyle(
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Elige un monto y un método de pago para agregar saldo.',
                  style: TextStyle(color: AppColors.textoSecundario),
                ),
                const SizedBox(height: 25),
                ListenableBuilder(
                  listenable: SaldoService.instancia,
                  builder: (context, _) => Container(
                    height: 210,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    foregroundDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.acento.withValues(alpha: .55),
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/Banners/perfil_billetera.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.centerRight,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xF2081830),
                                Color(0xC0081830),
                                Color(0x08081830),
                              ],
                              stops: [0, .5, 1],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.acento.withValues(
                                    alpha: .15,
                                  ),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: AppColors.acento,
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                'SALDO DISPONIBLE',
                                style: TextStyle(
                                  color: Color(0xFFBAD0E8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                formatoPrecio(SaldoService.instancia.saldo),
                                style: const TextStyle(
                                  fontSize: 37,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Text(
                                'Tu billetera WEIKANG SHOP',
                                style: TextStyle(
                                  color: Color(0xFFBAD0E8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _fondoPanel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _bordePanel),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.add_card_rounded, color: AppColors.acento),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Elige cuánto agregar',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Ingresa un monto o selecciona una opción rápida.',
                        style: TextStyle(color: AppColors.textoSecundario),
                      ),
                      const SizedBox(height: 22),
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _monto,
                          onChanged: (_) => setState(() {}),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Monto en soles',
                            prefixIcon: Icon(Icons.payments_outlined),
                            prefixText: 'S/ ',
                            hintText: '20.00',
                          ),
                          validator: (_) => _centimosIngresados == null
                              ? 'Ingresa un monto entre S/ 0.01 y S/ 1,000.00'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final monto in [10, 20, 50, 100])
                            ActionChip(
                              label: Text('S/ $monto'),
                              backgroundColor: _monto.text == '$monto'
                                  ? const Color(0xFF103C62)
                                  : const Color(0xFF0B1728),
                              side: BorderSide(
                                color: _monto.text == '$monto'
                                    ? AppColors.acento
                                    : _bordePanel,
                              ),
                              onPressed: () {
                                _monto.text = '$monto';
                                setState(() {});
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B2137),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _bordePanel),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: AppColors.acento,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Recibirás en tu billetera',
                                style: TextStyle(
                                  color: AppColors.textoSecundario,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              _centimosIngresados == null
                                  ? 'S/ 0.00'
                                  : formatoPrecio(_centimosIngresados! / 100),
                              style: const TextStyle(
                                color: AppColors.acento,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _fondoPanel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _bordePanel),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            color: AppColors.acento,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Método de pago',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Selecciona cómo quieres simular la recarga.',
                        style: TextStyle(color: AppColors.textoSecundario),
                      ),
                      const SizedBox(height: 18),
                      RadioGroup<String>(
                        groupValue: _metodo,
                        onChanged: (valor) => setState(() => _metodo = valor),
                        child: Column(
                          children: [
                            for (final metodo in PieTienda.metodos)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 9),
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  color: _metodo == metodo
                                      ? const Color(0xFF102D4D)
                                      : const Color(0xFF0C1726),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: _metodo == metodo
                                          ? AppColors.acento
                                          : _bordePanel,
                                      width: _metodo == metodo ? 1.5 : 1,
                                    ),
                                  ),
                                  child: RadioListTile<String>(
                                    title: Text(
                                      metodo,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _detalleMetodo(metodo),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    secondary: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: AppColors.acento.withValues(
                                          alpha: .13,
                                        ),
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Icon(
                                        _iconoMetodo(metodo),
                                        color: AppColors.acento,
                                        size: 21,
                                      ),
                                    ),
                                    value: metodo,
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.textoSecundario,
                            size: 17,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Recarga de demostración: no se realizará ningún cobro.',
                              style: TextStyle(
                                color: AppColors.textoSecundario,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _recargar,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Agregar saldo'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SaldoAgregadoScreen extends StatelessWidget {
  final RecargaDemo recarga;
  final int? usuarioId;

  const SaldoAgregadoScreen({super.key, required this.recarga, this.usuarioId});

  @override
  Widget build(BuildContext context) {
    return AccesoAutenticado(
      propietario: usuarioId,
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Recarga completada')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: AppColors.acento,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '¡Saldo agregado!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${formatoPrecio(recarga.centimos / 100)} añadidos con ${recarga.metodoPago}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nuevo saldo: ${formatoPrecio(SaldoService.instancia.saldo)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Volver'),
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
