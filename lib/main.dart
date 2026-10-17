import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_theme.dart';
import 'screens/home_screen.dart';
import 'widgets/pantalla_carga.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MiAplicacion(),
    ),
  );
}

class MiAplicacion extends StatelessWidget {
  const MiAplicacion({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weikang Shop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.tema,
      home: PantallaConCarga(
        duracion: defaultTargetPlatform == TargetPlatform.android
            ? const Duration(milliseconds: 1400)
            : const Duration(milliseconds: 700),
        destino: const HomeScreen(),
      ),
    );
  }
}
