import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/core/app_theme.dart';
import 'package:prototipo_app/services/pedido_service.dart';
import 'package:prototipo_app/models/billetera.dart';
import 'package:prototipo_app/widgets/perfil_billetera.dart';
import 'package:prototipo_app/widgets/perfil_compras.dart';
import 'package:prototipo_app/widgets/perfil_configuracion.dart';
import 'package:prototipo_app/widgets/perfil_rewards.dart';

void main() {
  final fecha = DateTime(2026, 10, 16, 9, 30);
  final pedido = PedidoDemo(
    numero: 1,
    fecha: fecha,
    metodoPago: 'Yape',
    productos: const ['CANVA PRO x1'],
    total: 7.90,
  );
  final recarga = MovimientoBilletera(
    id: 'id-prueba',
    operacion: 'operacion-prueba',
    tipo: 'admin_credit',
    descripcion: 'Crédito de presentación',
    centimos: 2000,
    saldoAnterior: 0,
    saldoPosterior: 2000,
    version: 1,
    fecha: fecha.add(const Duration(minutes: 5)),
  );

  Future<void> mostrar(WidgetTester tester, Widget contenido) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.tema,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: contenido,
          ),
        ),
      ),
    );
  }

  testWidgets('Las cinco secciones caben en móvil y muestran datos reales', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await mostrar(tester, PerfilCompras(pedidos: [pedido], onTienda: () {}));
    expect(find.text('Pedido #0001'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField).first, 'sin coincidencias');
    await tester.pump();
    expect(find.text('Sin resultados'), findsOneWidget);
    final limpiar = find.text('Ver todos los pedidos');
    await tester.ensureVisible(limpiar);
    await tester.tap(limpiar);
    await tester.pump();
    expect(find.text('Pedido #0001'), findsOneWidget);

    await mostrar(
      tester,
      PerfilSaldo(
        saldo: 20,
        recargas: [recarga],
        onAgregarSaldo: () {},
        onTransacciones: () {},
      ),
    );
    expect(find.text('S/ 20.00'), findsWidgets);
    expect(tester.takeException(), isNull);

    await mostrar(
      tester,
      PerfilTransacciones(
        pedidos: [pedido],
        recargas: [recarga],
        onAgregarSaldo: () {},
        onTienda: () {},
      ),
    );
    expect(find.text('Pedido #0001'), findsOneWidget);
    expect(find.text('Crédito ficticio'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Billetera  1'));
    await tester.pump();
    expect(find.text('Crédito ficticio'), findsOneWidget);
    expect(find.text('Pedido #0001'), findsNothing);
    expect(tester.takeException(), isNull);

    await mostrar(
      tester,
      PerfilNotificaciones(
        pedidos: [pedido],
        recargas: [recarga],
        onCompras: () {},
        onSaldo: () {},
        onTienda: () {},
      ),
    );
    expect(find.text('¡Gracias por tu pedido!'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Billetera · 1'));
    await tester.pump();
    expect(find.text('Crédito ficticio'), findsOneWidget);
    expect(find.text('¡Gracias por tu pedido!'), findsNothing);
    expect(tester.takeException(), isNull);

    final nombre = TextEditingController(text: 'Prueba');
    final correo = TextEditingController(text: 'Prueba@email.com');
    final telefono = TextEditingController();
    addTearDown(() {
      nombre.dispose();
      correo.dispose();
      telefono.dispose();
    });
    final formKey = GlobalKey<FormState>();
    var guardados = 0;
    await mostrar(
      tester,
      PerfilCuenta(
        nombre: 'Prueba',
        correo: 'Prueba@email.com',
        formKey: formKey,
        nombreController: nombre,
        correoController: correo,
        telefonoController: telefono,
        onGuardar: () {
          if (formKey.currentState!.validate()) guardados++;
        },
      ),
    );
    final boton = find.widgetWithText(FilledButton, 'Guardar cambios');
    await tester.ensureVisible(boton);
    await tester.tap(boton);
    expect(guardados, 1);
    await tester.enterText(find.byType(TextFormField).at(1), 'correo inválido');
    await tester.ensureVisible(boton);
    await tester.tap(boton);
    await tester.pump();
    expect(find.text('Ingresa un correo válido'), findsOneWidget);
    expect(guardados, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Los estados vacíos y el formulario caben en escritorio', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await mostrar(tester, PerfilCompras(pedidos: const [], onTienda: () {}));
    expect(find.text('Tu próxima compra empieza aquí'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await mostrar(
      tester,
      PerfilSaldo(
        saldo: 0,
        recargas: const [],
        onAgregarSaldo: () {},
        onTransacciones: () {},
      ),
    );
    expect(find.text('Dale vida a tu billetera'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await mostrar(
      tester,
      PerfilTransacciones(
        pedidos: const [],
        recargas: const [],
        onAgregarSaldo: () {},
        onTienda: () {},
      ),
    );
    expect(find.text('Tu historial empieza aquí'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await mostrar(
      tester,
      PerfilNotificaciones(
        pedidos: const [],
        recargas: const [],
        onCompras: () {},
        onSaldo: () {},
        onTienda: () {},
      ),
    );
    expect(find.text('Todo tranquilo por aquí'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rewards muestra los niveles y el avance en móvil y escritorio', (
    tester,
  ) async {
    final compraDelMes = PedidoDemo(
      numero: 2,
      fecha: DateTime.now(),
      metodoPago: 'Yape',
      productos: const ['Producto digital x1'],
      total: 350,
    );
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final ancho in [360.0, 1280.0]) {
      tester.view.physicalSize = Size(ancho, 900);
      tester.view.devicePixelRatio = 1;
      await mostrar(
        tester,
        PerfilRewards(pedidos: [compraDelMes], puntos: 3500),
      );
      await tester.pump();
      expect(find.text('NOVA'), findsOneWidget);
      expect(find.text('ADVANCE'), findsOneWidget);
      expect(find.text('LEGENDARY'), findsOneWidget);
      expect(find.text('Alcanzado'), findsOneWidget);
      expect(find.text('Faltan S/ 350.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
