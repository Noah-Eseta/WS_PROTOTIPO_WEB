import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../models/billetera.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/autenticacion/acceso_autenticado.dart';
import '../widgets/billetera/historial_billetera.dart';
import '../widgets/pantalla_carga.dart';
import 'admin_billetera_screen.dart';

const _bordePanel = Color(0xFF214463);

class SaldoScreen extends ConsumerWidget {
  const SaldoScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(authProvider);
    final id = sesion.usuario?.id;
    return AccesoAutenticado(
      builder: (context) {
        if (id == null) return const SizedBox.shrink();
        final permiso = ref.watch(permisoAdminProvider);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Saldo de demostración'),
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
                    'Saldo de demostración',
                    style: TextStyle(
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Saldo ficticio en PEN, guardado en tu cuenta. No representa dinero real.',
                    style: TextStyle(color: AppColors.textoSecundario),
                  ),
                  const SizedBox(height: 25),
                  EstadoWallet(
                    valor: ref.watch(walletProvider(id)),
                    reintentar: () => ref.invalidate(walletProvider(id)),
                    builder: (billetera) => billetera == null
                        ? const SizedBox.shrink()
                        : _tarjeta(billetera),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          ref.invalidate(walletProvider(id));
                          ref.invalidate(movimientosWalletProvider(id));
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Actualizar billetera'),
                      ),
                      if (datosWallet(permiso) == true)
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            RutaConCarga(destino: const AdminBilleteraScreen()),
                          ),
                          icon: const Icon(Icons.admin_panel_settings_outlined),
                          label: const Text('Administrar créditos ficticios'),
                        ),
                      if (permiso.hasError)
                        TextButton(
                          onPressed: () => ref.invalidate(permisoAdminProvider),
                          child: const Text(
                            'Reintentar comprobación de permisos',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Los créditos ficticios solo pueden ser asignados por un administrador autorizado. Las compras simuladas no descuentan este saldo.',
                  ),
                  const SizedBox(height: 24),
                  HistorialBilletera(
                    key: ValueKey((id, sesion.expiraEn)),
                    usuario: id,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tarjeta(Billetera billetera) => Container(
    key: const ValueKey('wallet-card'),
    height: 210,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
    foregroundDecoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.acento.withValues(alpha: .55)),
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
              colors: [Color(0xF2081830), Color(0xC0081830), Color(0x08081830)],
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
                  color: AppColors.acento.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.acento,
                ),
              ),
              const Spacer(),
              const Text(
                'SALDO FICTICIO',
                style: TextStyle(
                  color: Color(0xFFBAD0E8),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatoCentimos(billetera.centimos),
                  style: const TextStyle(
                    fontSize: 37,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Text(
                'Tu billetera WEIKANG SHOP',
                style: TextStyle(color: Color(0xFFBAD0E8), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
