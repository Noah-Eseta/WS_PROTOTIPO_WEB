import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/billetera.dart';
import '../providers/auth_provider.dart';
import '../providers/admin_wallet_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/autenticacion/acceso_autenticado.dart';
import '../widgets/billetera/formulario_credito.dart';
import '../widgets/billetera/historial_billetera.dart';
import '../widgets/perfil_componentes.dart';

class AdminBilleteraScreen extends ConsumerStatefulWidget {
  const AdminBilleteraScreen({super.key});
  @override
  ConsumerState<AdminBilleteraScreen> createState() =>
      _AdminBilleteraScreenState();
}

class _AdminBilleteraScreenState extends ConsumerState<AdminBilleteraScreen> {
  ({int id, String nombre})? _seleccion;
  bool _cargando = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    ref.listenManual(sesionWalletProvider, (_, _) {
      if (mounted) {
        setState(() {
          _seleccion = null;
          _error = null;
          _cargando = false;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(permisoAdminProvider);
    });
  }

  Future<void> _mas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await ref.read(usuariosAdminProvider.notifier).siguiente();
    } catch (error) {
      if (mounted) setState(() => _error = mensajeWallet(error));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(authProvider);
    return AccesoAutenticado(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Créditos ficticios')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                EstadoWallet(
                  valor: ref.watch(permisoAdminProvider),
                  reintentar: () => ref.invalidate(permisoAdminProvider),
                  builder: (permitido) {
                    if (!permitido) {
                      return const Text(
                        'No tienes permiso para administrar billeteras.',
                      );
                    }
                    final seleccion = _seleccion;
                    if (seleccion != null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextButton.icon(
                            onPressed: () => setState(() => _seleccion = null),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Volver a usuarios'),
                          ),
                          Text(
                            '${seleccion.nombre} · Cuenta ${seleccion.id}',
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 20),
                          EstadoWallet(
                            valor: ref.watch(walletProvider(seleccion.id)),
                            reintentar: () =>
                                ref.invalidate(walletProvider(seleccion.id)),
                            builder: (saldo) => PerfilPanel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Saldo de demostración'),
                                  Text(
                                    saldo == null
                                        ? 'No disponible'
                                        : formatoCentimos(saldo.centimos),
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      ref.invalidate(
                                        walletProvider(seleccion.id),
                                      );
                                      ref.invalidate(
                                        movimientosWalletProvider(seleccion.id),
                                      );
                                    },
                                    child: const Text('Actualizar billetera'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          FormularioCredito(
                            key: ValueKey((
                              sesion.usuario?.id,
                              sesion.expiraEn,
                              seleccion.id,
                            )),
                            destinatario: seleccion.id,
                          ),
                          const SizedBox(height: 20),
                          HistorialBilletera(
                            key: ValueKey((
                              'historial',
                              sesion.usuario?.id,
                              sesion.expiraEn,
                              seleccion.id,
                            )),
                            usuario: seleccion.id,
                          ),
                        ],
                      );
                    }
                    final pendiente = ref.watch(creditoWalletProvider).intento;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Billeteras de demostración',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Usuarios y saldos ficticios en PEN. Solo un administrador autorizado puede asignar créditos.',
                        ),
                        if (pendiente != null)
                          TextButton(
                            onPressed: () => setState(
                              () => _seleccion = (
                                id: pendiente.destinatario,
                                nombre: 'Cuenta ${pendiente.destinatario}',
                              ),
                            ),
                            child: const Text('Retomar operación anterior'),
                          ),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(usuariosAdminProvider),
                          child: const Text('Actualizar usuarios'),
                        ),
                        EstadoWallet(
                          valor: ref.watch(usuariosAdminProvider),
                          reintentar: () =>
                              ref.invalidate(usuariosAdminProvider),
                          builder: (pagina) => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (pagina.elementos.isEmpty)
                                const Text('No hay usuarios para mostrar.'),
                              for (final usuario in pagina.elementos)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: PerfilPanel(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          usuario.nombre,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          'Cuenta ${usuario.id} · ${formatoCentimos(usuario.billetera.centimos)} · Saldo ficticio',
                                        ),
                                        TextButton(
                                          onPressed: () => setState(
                                            () => _seleccion = (
                                              id: usuario.id,
                                              nombre: usuario.nombre,
                                            ),
                                          ),
                                          child: const Text(
                                            'Consultar billetera',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (_error != null) Text(_error!),
                              if (pagina.siguiente != null)
                                TextButton(
                                  onPressed: _cargando ? null : _mas,
                                  child: Text(
                                    _cargando
                                        ? 'Cargando…'
                                        : 'Cargar más usuarios',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
