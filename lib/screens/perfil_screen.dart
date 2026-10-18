import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/autenticacion/acceso_autenticado.dart';

import '../core/app_theme.dart';
import '../services/pedido_service.dart';
import '../services/saldo_service.dart';
import '../providers/auth_provider.dart';
import '../models/estado_autenticacion.dart';
import '../widgets/pantalla_carga.dart';
import '../widgets/perfil_billetera.dart';
import '../widgets/perfil_compras.dart';
import '../widgets/perfil_configuracion.dart';
import '../widgets/perfil_resumen.dart';
import '../widgets/perfil_rewards.dart';
import 'saldo_screen.dart';

enum _SeccionPerfil {
  resumen,
  compras,
  saldo,
  transacciones,
  rewards,
  reseller,
  referidos,
  colaboradores,
  notificaciones,
  cuenta,
}

class PerfilScreen extends ConsumerStatefulWidget {
  final bool mostrarCompras;
  final bool mostrarRewards;
  final bool mostrarColaboradores;

  const PerfilScreen({
    super.key,
    this.mostrarCompras = false,
    this.mostrarRewards = false,
    this.mostrarColaboradores = false,
  });

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  static const _anchoEscritorio = 1000.0;
  EstadoAutenticacion get _sesion => ref.read(authProvider);
  final _pedidos = PedidoService.instancia;
  final _saldo = SaldoService.instancia;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _correo;
  final _telefono = TextEditingController();
  late _SeccionPerfil _seccion = widget.mostrarCompras
      ? _SeccionPerfil.compras
      : widget.mostrarRewards
      ? _SeccionPerfil.rewards
      : widget.mostrarColaboradores
      ? _SeccionPerfil.colaboradores
      : _SeccionPerfil.resumen;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: _sesion.nombre);
    _correo = TextEditingController(text: _sesion.correo ?? '');
    ref.listenManual(authProvider.select((s) => s.usuario), (_, usuario) {
      _nombre.text = usuario?.nombre ?? '';
      _correo.text = usuario?.correo ?? '';
      _telefono.clear();
    });
  }

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _telefono.dispose();
    super.dispose();
  }

  void _irA(_SeccionPerfil destino, {bool cerrarDrawer = false}) {
    setState(() => _seccion = destino);
    if (cerrarDrawer) Navigator.of(context).pop();
  }

  void _volverATienda() =>
      Navigator.of(context).popUntil((route) => route.isFirst);

  Future<void> _cerrarSesion() async {
    await ref.read(authProvider.notifier).cerrarSesion();
    if (mounted) {
      final aviso = ref.read(authProvider).error?.mensaje;
      if (aviso != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(aviso)));
      }
      _volverATienda();
    }
  }

  void _agregarSaldo() =>
      Navigator.of(context).push(RutaConCarga(destino: const SaldoScreen()));

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);
    ref.listen(authProvider, (anterior, actual) {
      if (actual.iniciada &&
          actual.error != null &&
          actual.error != anterior?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(actual.error!.mensaje),
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: () => ref.read(authProvider.notifier).obtenerPerfil(),
            ),
          ),
        );
      }
    });
    final ancho = MediaQuery.sizeOf(context).width;
    final escritorio = ancho >= _anchoEscritorio;
    return AccesoAutenticado(
      consultarPerfil: true,
      builder: (context) => Scaffold(
        backgroundColor: const Color(0xFF07111E),
        appBar: escritorio
            ? null
            : AppBar(
                title: Text(_titulo),
                backgroundColor: const Color(0xFF081322),
              ),
        drawer: escritorio ? null : Drawer(child: _navegacion()),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (escritorio) SizedBox(width: 280, child: _navegacion()),
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A1728), Color(0xFF07111E)],
                  ),
                ),
                child: SafeArea(
                  top: escritorio,
                  child: ListenableBuilder(
                    listenable: Listenable.merge([_pedidos, _saldo]),
                    builder: (context, _) => SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: escritorio ? 42 : 16,
                        vertical: escritorio ? 32 : 20,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1320),
                          child: _contenido(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _titulo => switch (_seccion) {
    _SeccionPerfil.resumen => 'Resumen',
    _SeccionPerfil.compras => 'Compras',
    _SeccionPerfil.saldo => 'Saldo',
    _SeccionPerfil.transacciones => 'Transacciones',
    _SeccionPerfil.rewards => 'Rewards',
    _SeccionPerfil.reseller => 'Reseller',
    _SeccionPerfil.referidos => 'Referidos',
    _SeccionPerfil.colaboradores => 'Colaboradores',
    _SeccionPerfil.notificaciones => 'Notificaciones',
    _SeccionPerfil.cuenta => 'Mi cuenta',
  };

  Widget _navegacion() {
    return Material(
      color: const Color(0xFF08111E),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/Logotipos/logo.webp',
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  const Text.rich(
                    TextSpan(
                      text: 'WEIKANG ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                      children: [
                        TextSpan(
                          text: 'SHOP',
                          style: TextStyle(color: AppColors.acento),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Material(
              color: const Color(0xFF101D30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF1B354F)),
              ),
              child: InkWell(
                onTap: () => _irA(
                  _SeccionPerfil.cuenta,
                  cerrarDrawer:
                      MediaQuery.sizeOf(context).width < _anchoEscritorio,
                ),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF07549C),
                        child: Text(
                          _sesion.nombre.isEmpty
                              ? 'P'
                              : _sesion.nombre.characters.first.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF41C6FF),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _sesion.nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'MIEMBRO WEIKANG',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF9DB3D2),
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _grupo('GESTIÓN'),
            _opcion(
              Icons.dashboard_outlined,
              'Resumen',
              _SeccionPerfil.resumen,
            ),
            _opcion(
              Icons.receipt_long_outlined,
              'Compras',
              _SeccionPerfil.compras,
            ),
            _grupo('BILLETERA'),
            _opcion(
              Icons.account_balance_wallet_outlined,
              'Saldo',
              _SeccionPerfil.saldo,
            ),
            _opcion(
              Icons.credit_card_outlined,
              'Transacciones',
              _SeccionPerfil.transacciones,
            ),
            _grupo('BENEFICIOS'),
            _opcion(
              Icons.card_giftcard_outlined,
              'Rewards',
              _SeccionPerfil.rewards,
            ),
            _opcion(
              Icons.workspace_premium_outlined,
              'Reseller',
              _SeccionPerfil.reseller,
            ),
            _opcion(
              Icons.group_outlined,
              'Referidos',
              _SeccionPerfil.referidos,
            ),
            _opcion(
              Icons.handshake_outlined,
              'Colaboradores',
              _SeccionPerfil.colaboradores,
            ),
            _grupo('CONFIGURACIÓN'),
            _opcion(
              Icons.notifications_none,
              'Notificaciones',
              _SeccionPerfil.notificaciones,
            ),
            _opcion(
              Icons.settings_outlined,
              'Mi cuenta',
              _SeccionPerfil.cuenta,
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFF1C354E)),
            const SizedBox(height: 8),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: const Icon(Icons.open_in_new, color: AppColors.acento),
              title: const Text(
                'Volver a la tienda',
                style: TextStyle(color: AppColors.acento),
              ),
              onTap: _volverATienda,
            ),
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: const Icon(Icons.logout_outlined),
              title: const Text('Cerrar sesión'),
              onTap: _cerrarSesion,
            ),
          ],
        ),
      ),
    );
  }

  Widget _grupo(String titulo) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 10, 8),
    child: Text(
      titulo,
      style: const TextStyle(
        color: Color(0xFF9DB3D2),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _opcion(IconData icono, String texto, _SeccionPerfil destino) {
    final seleccionada = _seccion == destino;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: seleccionada ? const Color(0xFF102B50) : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: () => _irA(
            destino,
            cerrarDrawer: MediaQuery.sizeOf(context).width < _anchoEscritorio,
          ),
          borderRadius: BorderRadius.circular(9),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: seleccionada ? AppColors.acento : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icono,
                  size: 20,
                  color: seleccionada
                      ? AppColors.acento
                      : const Color(0xFFD8E4F5),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    texto,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: seleccionada
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: seleccionada
                          ? AppColors.acento
                          : const Color(0xFFE8F1FE),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenido() => switch (_seccion) {
    _SeccionPerfil.resumen => _resumen(),
    _SeccionPerfil.compras => _compras(),
    _SeccionPerfil.saldo => _saldoContenido(),
    _SeccionPerfil.transacciones => _transacciones(),
    _SeccionPerfil.rewards => _rewards(),
    _SeccionPerfil.cuenta => _miCuenta(),
    _SeccionPerfil.reseller => _proximamente(
      Icons.workspace_premium_outlined,
      'Programa Reseller',
      'La inscripción al programa estará disponible próximamente.',
    ),
    _SeccionPerfil.referidos => _proximamente(
      Icons.group_outlined,
      'Referidos',
      'Pronto podrás invitar a otras personas y consultar tus beneficios.',
    ),
    _SeccionPerfil.colaboradores => _proximamente(
      Icons.handshake_outlined,
      'Colaboradores',
      'El programa de colaboradores estará disponible próximamente.',
    ),
    _SeccionPerfil.notificaciones => PerfilNotificaciones(
      pedidos: _pedidos.pedidos,
      recargas: _saldo.recargas,
      onCompras: () => _irA(_SeccionPerfil.compras),
      onSaldo: () => _irA(_SeccionPerfil.saldo),
      onTienda: _volverATienda,
    ),
  };

  Widget _resumen() => PerfilResumen(
    nombre: _sesion.nombre,
    saldo: _saldo.saldo,
    puntos: _puntos,
    pedidos: _pedidos.pedidos,
    onAgregarSaldo: _agregarSaldo,
    onTransacciones: () => _irA(_SeccionPerfil.transacciones),
    onCompras: () => _irA(_SeccionPerfil.compras),
    onSaldo: () => _irA(_SeccionPerfil.saldo),
    onRewards: () => _irA(_SeccionPerfil.rewards),
    onCuenta: () => _irA(_SeccionPerfil.cuenta),
    onTienda: _volverATienda,
  );

  Widget _compras() =>
      PerfilCompras(pedidos: _pedidos.pedidos, onTienda: _volverATienda);

  Widget _saldoContenido() => PerfilSaldo(
    saldo: _saldo.saldo,
    recargas: _saldo.recargas,
    onAgregarSaldo: _agregarSaldo,
    onTransacciones: () => _irA(_SeccionPerfil.transacciones),
  );

  Widget _transacciones() => PerfilTransacciones(
    pedidos: _pedidos.pedidos,
    recargas: _saldo.recargas,
    onAgregarSaldo: _agregarSaldo,
    onTienda: _volverATienda,
  );
  int get _puntos => _pedidos.pedidos.fold<int>(
    0,
    (total, pedido) => total + (pedido.total * 10).floor(),
  );

  Widget _rewards() =>
      PerfilRewards(pedidos: _pedidos.pedidos, puntos: _puntos);

  Widget _miCuenta() => PerfilCuenta(
    nombre: _sesion.nombre,
    correo: _sesion.correo ?? '',
    formKey: _formKey,
    soloLectura: true,
    nombreController: _nombre,
    correoController: _correo,
    telefonoController: _telefono,
    onGuardar: () {
      if (!_formKey.currentState!.validate()) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La API todavía no permite editar el perfil ni el teléfono.',
          ),
        ),
      );
    },
  );
  Widget _proximamente(IconData icono, String titulo, String detalle) =>
      _seccionLista(titulo, 'WEIKANG SHOP', _vacio(icono, titulo, detalle));

  Widget _seccionLista(String titulo, String subtitulo, Widget contenido) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        Text(
          subtitulo,
          style: const TextStyle(color: AppColors.textoSecundario),
        ),
        const SizedBox(height: 24),
        Container(decoration: _decoracion(), child: contenido),
      ],
    );
  }

  Widget _vacio(IconData icono, String titulo, String detalle) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 58),
    child: Column(
      children: [
        Icon(icono, size: 40, color: AppColors.acento),
        const SizedBox(height: 12),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          detalle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textoSecundario),
        ),
      ],
    ),
  );

  BoxDecoration _decoracion() => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF101D30), Color(0xFF10243D)],
    ),
    border: Border.all(color: const Color(0xFF214463)),
    borderRadius: BorderRadius.circular(12),
  );
}
