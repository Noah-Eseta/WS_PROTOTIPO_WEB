import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../screens/login_screen.dart';

class AccesoAutenticado extends ConsumerStatefulWidget {
  final WidgetBuilder builder;
  final bool consultarPerfil;
  final int? propietario;
  const AccesoAutenticado({
    super.key,
    required this.builder,
    this.consultarPerfil = false,
    this.propietario,
  });
  @override
  ConsumerState<AccesoAutenticado> createState() => _AccesoAutenticadoState();
}

class _AccesoAutenticadoState extends ConsumerState<AccesoAutenticado> {
  int? _consultado;
  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(authProvider);
    final vigente =
        sesion.iniciada &&
        sesion.expiraEn != null &&
        sesion.expiraEn!.isAfter(ref.read(relojAuthProvider)().toUtc());
    if (!vigente) {
      if (sesion.iniciada) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ref.read(authProvider.notifier).verificarVigencia();
        });
      }
      _consultado = null;
      return const LoginScreen(integrado: true);
    }
    if (widget.propietario != null &&
        widget.propietario != sesion.usuario!.id) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sesión diferente')),
        body: Center(
          child: TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text(
              'Vuelve a la tienda para continuar con tu cuenta',
            ),
          ),
        ),
      );
    }
    if (widget.consultarPerfil && _consultado != sesion.usuario!.id) {
      _consultado = sesion.usuario!.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(authProvider.notifier).obtenerPerfil();
      });
    }
    return widget.builder(context);
  }
}

class ObservadorAutenticacion extends ConsumerStatefulWidget {
  final Widget child;
  const ObservadorAutenticacion({super.key, required this.child});
  @override
  ConsumerState<ObservadorAutenticacion> createState() =>
      _ObservadorAutenticacionState();
}

class _ObservadorAutenticacionState
    extends ConsumerState<ObservadorAutenticacion>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(authProvider.notifier).verificarVigencia();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);
    ref.listen(authProvider, (anterior, actual) {
      if (actual.caducada && !(anterior?.caducada ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu sesión ha caducado. Inicia sesión nuevamente.'),
          ),
        );
      }
    });
    return widget.child;
  }
}
