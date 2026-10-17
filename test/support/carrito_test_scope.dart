import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Conserva el mismo carrito al montar rutas o redimensionar dentro de un test.
Widget conCarritoScope(ProviderContainer container, Widget child) =>
    UncontrolledProviderScope(container: container, child: child);
