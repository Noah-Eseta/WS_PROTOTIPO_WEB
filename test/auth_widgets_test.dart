import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/core/app_theme.dart';
import 'package:prototipo_app/core/http/error_autenticacion.dart';
import 'package:prototipo_app/models/dto/autenticacion_api_dto.dart';
import 'package:prototipo_app/models/usuario_autenticado.dart';
import 'package:prototipo_app/providers/carrito_provider.dart';
import 'package:prototipo_app/providers/catalogo_provider.dart';
import 'package:prototipo_app/screens/home_screen.dart';
import 'package:prototipo_app/screens/login_screen.dart';
import 'package:prototipo_app/screens/registro_screen.dart';
import 'package:prototipo_app/screens/perfil_screen.dart';
import 'package:prototipo_app/screens/saldo_screen.dart';
import 'package:prototipo_app/screens/pago_screen.dart';
import 'package:prototipo_app/widgets/autenticacion/acceso_autenticado.dart';
import 'package:prototipo_app/widgets/cabecera_tienda.dart';
import 'package:prototipo_app/widgets/perfil_configuracion.dart';
import 'package:prototipo_app/services/producto_service.dart';

import 'support/auth_test_repository.dart';

void main() {
  late ProviderContainer container;
  late AuthTestRepository repo;
  setUp(() {
    repo = AuthTestRepository();
    container = ProviderContainer(
      overrides: [
        cartRepositoryProvider.overrideWithValue(CartTestRepository()),
        authRepositoryProvider.overrideWithValue(repo),
      ],
    );
  });
  tearDown(() => container.dispose());

  Future<void> mount(WidgetTester tester, Widget home) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.tema,
          builder: (context, child) => ObservadorAutenticacion(child: child!),
          home: home,
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> loginFields(WidgetTester tester) async {
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'persona@example.test',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'entrada-fixture');
  }

  Future<void> press(WidgetTester tester, String label) async {
    final button = find.widgetWithText(FilledButton, label);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
  }

  for (final width in [360.0, 390.0, 600.0, 768.0, 1024.0, 1440.0]) {
    testWidgets('Login y registro conservan layout sin overflow a $width px', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(tester, const LoginScreen(integrado: true));
      expect(find.text('Tu correo electrónico'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await press(tester, 'Iniciar sesión');
      expect(find.text('Ingresa tu correo'), findsOneWidget);
      expect(repo.logins, 0);
      expect(tester.takeException(), isNull);
      await mount(tester, const RegistroScreen());
      expect(find.byType(TextFormField), findsNWidgets(4));
      await press(tester, 'Crear cuenta');
      expect(find.text('Ingresa tu nombre'), findsOneWidget);
      expect(repo.registros, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Login bloquea duplicados y la ruta privada aparece al autenticar',
    (tester) async {
      repo.pendiente = Completer<AutenticacionApiDto>();
      await mount(
        tester,
        AccesoAutenticado(
          builder: (_) => const Scaffold(body: Text('Contenido privado')),
        ),
      );
      final cart = container.read(carritoProvider);
      await loginFields(tester);
      await press(tester, 'Iniciar sesión');
      expect(repo.logins, 1);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Iniciar sesión'),
            )
            .onPressed,
        isNull,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      repo.pendiente!.complete(repo.sesion());
      await tester.pump();
      await tester.pump();
      expect(find.text('Contenido privado'), findsOneWidget);
      expect(container.read(carritoProvider).items, cart.items);
      await container.read(authProvider.notifier).cerrarSesion();
      await tester.pump();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Contenido privado'), findsNothing);
    },
  );

  for (final code in [401, 422, 429]) {
    testWidgets('Formulario muestra HTTP $code y permite corregir/reintentar', (
      tester,
    ) async {
      repo.errorLogin = ErrorAutenticacion(
        'Error seguro $code',
        estadoHttp: code,
        campos: code == 422
            ? {
                'email': ['Correo ya registrado.'],
              }
            : {},
      );
      await mount(tester, const LoginScreen(integrado: true));
      await loginFields(tester);
      await press(tester, 'Iniciar sesión');
      await tester.pump();
      expect(find.text('Error seguro $code'), findsOneWidget);
      if (code == 422) {
        expect(find.text('Correo ya registrado.'), findsOneWidget);
      }
      expect(container.read(authProvider).iniciada, isFalse);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Iniciar sesión'),
            )
            .onPressed,
        isNotNull,
      );
      await tester.enterText(
        find.byType(TextFormField).first,
        'otro@example.test',
      );
      expect(container.read(authProvider).error, isNull);
    });
  }

  testWidgets('Registro valida confirmación y registra con los cuatro datos', (
    tester,
  ) async {
    await mount(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RegistroScreen()),
            ),
            child: const Text('Abrir registro'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir registro'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Persona');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'persona@example.test',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'entrada-fixture');
    await tester.enterText(find.byType(TextFormField).at(3), 'otra-entrada');
    await press(tester, 'Crear cuenta');
    expect(
      find.text('La confirmación de contraseña no coincide'),
      findsOneWidget,
    );
    expect(repo.registros, 0);
    await tester.enterText(find.byType(TextFormField).at(3), 'entrada-fixture');
    await press(tester, 'Crear cuenta');
    await tester.pumpAndSettle();
    expect(repo.registros, 1);
    expect(container.read(authProvider).iniciada, isTrue);
    expect(find.text('Abrir registro'), findsOneWidget);
    await container.read(authProvider.notifier).cerrarSesion();
  });

  for (final page in <Widget>[
    const PerfilScreen(),
    const SaldoScreen(),
    const PagoScreen(),
  ]) {
    testWidgets('Bloquea acceso directo invitado a ${page.runtimeType}', (
      tester,
    ) async {
      await mount(tester, page);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(repo.perfiles, 0);
      expect(container.read(authProvider).iniciada, isFalse);
    });
  }

  testWidgets(
    'Navegar conserva sesión y carrito; perfil muestra datos reales solo lectura',
    (tester) async {
      repo.usuario = const UsuarioAutenticado(
        id: 9,
        nombre: 'Nombre Laravel',
        correo: 'real@example.test',
      );
      await tester.runAsync(() => iniciarSesionPrueba(container));
      final products = await ProductoService().obtenerProductos();
      final cart = container.read(carritoProvider.notifier);
      await cart.agregar(products.firstWhere((p) => p.disponible));
      await cart.agregar(products.firstWhere((p) => p.disponible));
      final snapshot = container.read(carritoProvider);
      await mount(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PerfilScreen()),
              ),
              child: const Text('Abrir perfil'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir perfil'));
      await tester.pumpAndSettle();
      expect(repo.perfiles, 1);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      expect(find.text('Nombre Laravel'), findsWidgets);
      await tester.tap(find.text('Nombre Laravel'));
      await tester.pumpAndSettle();
      expect(find.byType(PerfilCuenta), findsOneWidget);
      final fields = tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .toList();
      expect(fields.map((f) => f.controller!.text), [
        'Nombre Laravel',
        'real@example.test',
        '',
      ]);
      expect(
        tester
            .widgetList<TextField>(find.byType(TextField))
            .every((f) => f.readOnly),
        isTrue,
      );
      Navigator.of(tester.element(find.byType(PerfilScreen))).pop();
      await tester.pumpAndSettle();
      expect(container.read(authProvider).usuario!.id, 9);
      expect(
        container.read(carritoProvider).cantidadTotal,
        snapshot.cantidadTotal,
      );
      expect(
        container.read(carritoProvider).totalCentimos,
        snapshot.totalCentimos,
      );
      expect(snapshot.cantidadTotal, 2);
    },
  );

  testWidgets(
    'La caducidad oculta contenido privado y solicita login sin perder carrito',
    (tester) async {
      repo.vigencia = const Duration(seconds: 2);
      await iniciarSesionPrueba(container);
      final snapshot = container.read(carritoProvider);
      await mount(
        tester,
        AccesoAutenticado(
          builder: (_) => const Scaffold(body: Text('Perfil privado')),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.textContaining('Tu sesión ha caducado'), findsOneWidget);
      expect(
        container.read(carritoProvider).cantidadTotal,
        snapshot.cantidadTotal,
      );
      expect(
        container.read(carritoProvider).totalCentimos,
        snapshot.totalCentimos,
      );
    },
  );

  testWidgets(
    'El catálogo de 34 productos sigue público y cerrar sesión no lo recarga',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(tester, const HomeScreen());
      await tester.pumpAndSettle();
      final catalog = container.read(catalogoProvider).requireValue;
      expect(catalog, hasLength(34));
      expect(find.byType(CabeceraTienda), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      await tester.runAsync(() => iniciarSesionPrueba(container));
      await tester.pumpAndSettle();
      await container.read(authProvider.notifier).cerrarSesion();
      await tester.pumpAndSettle();
      expect(container.read(catalogoProvider).requireValue, same(catalog));
      expect(find.byType(CabeceraTienda), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [360.0, 390.0, 600.0, 768.0, 1024.0, 1440.0]) {
    testWidgets('Saldo y pago autenticados sin overflow a $width px', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() => iniciarSesionPrueba(container));
      for (final page in <Widget>[const SaldoScreen(), const PagoScreen()]) {
        await mount(tester, page);
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsNothing);
        expect(
          tester.takeException(),
          isNull,
          reason: page.runtimeType.toString(),
        );
      }
    });
  }
  testWidgets(
    'Una confirmación de otra cuenta no expone sus datos después de cambiar usuario',
    (tester) async {
      await tester.runAsync(() => iniciarSesionPrueba(container));
      await mount(
        tester,
        AccesoAutenticado(
          propietario: 1,
          builder: (_) =>
              const Scaffold(body: Text('Confirmación de la primera cuenta')),
        ),
      );
      expect(find.text('Confirmación de la primera cuenta'), findsOneWidget);
      await container.read(authProvider.notifier).cerrarSesion();
      repo.usuario = const UsuarioAutenticado(
        id: 2,
        nombre: 'Otra persona',
        correo: 'otra@example.test',
      );
      await tester.runAsync(() => iniciarSesionPrueba(container));
      await tester.pump();
      expect(find.text('Confirmación de la primera cuenta'), findsNothing);
      expect(find.text('Sesión diferente'), findsOneWidget);
    },
  );
}
