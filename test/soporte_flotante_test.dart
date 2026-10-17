import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/core/app_theme.dart';
import 'package:prototipo_app/widgets/chat_soporte_ventana.dart';
import 'package:prototipo_app/widgets/soporte/soporte_flotante.dart';

void main() {
  Future<void> montar(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.tema,
        home: const Scaffold(floatingActionButton: SoporteFlotante()),
      ),
    );
  }

  for (final caso in const [
    (Size(360, 640), Size(328, 450)),
    (Size(390, 844), Size(358, 480)),
    (Size(600, 960), Size(380, 480)),
    (Size(768, 1024), Size(380, 480)),
    (Size(1440, 900), Size(380, 480)),
  ]) {
    testWidgets('El chat abre y cierra sin desbordarse en ${caso.$1}', (
      tester,
    ) async {
      await montar(tester, caso.$1);
      final boton = find.byType(FloatingActionButton);
      final posicionInicial = tester.getRect(boton);
      expect(find.byType(ChatSoporteVentana), findsNothing);

      await tester.tap(boton);
      await tester.pumpAndSettle();
      expect(find.byType(ChatSoporteVentana), findsOneWidget);
      expect(tester.getSize(find.byType(ChatSoporteVentana)), caso.$2);
      expect(
        tester.getRect(boton),
        rectMoreOrLessEquals(posicionInicial, epsilon: 0.000001),
      );
      expect(find.text('Soporte WEIKANG'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatSoporteVentana), findsNothing);

      await tester.tap(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();
      expect(find.byType(ChatSoporteVentana), findsNothing);
      expect(
        tester.getRect(boton),
        rectMoreOrLessEquals(posicionInicial, epsilon: 0.000001),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('El hover conserva la escala y revierte al salir', (
    tester,
  ) async {
    await montar(tester, const Size(1440, 900));
    final boton = find.byType(FloatingActionButton);
    final normal = tester.getRect(boton);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(10, 10));
    addTearDown(mouse.removePointer);
    await mouse.moveTo(normal.center);
    await tester.pumpAndSettle();
    final hover = tester.getRect(boton);
    expect(hover.width, closeTo(normal.width * 1.08, 0.01));
    expect(hover.height, closeTo(normal.height * 1.08, 0.01));
    expect(
      hover.center,
      offsetMoreOrLessEquals(normal.center, epsilon: 0.000001),
    );
    await mouse.moveTo(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(boton),
      rectMoreOrLessEquals(normal, epsilon: 0.000001),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('El chat abierto conserva su estado al redimensionar', (
    tester,
  ) async {
    await montar(tester, const Size(390, 844));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();
    expect(find.byType(ChatSoporteVentana), findsOneWidget);
    expect(
      tester.getSize(find.byType(ChatSoporteVentana)),
      const Size(380, 480),
    );
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatSoporteVentana), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
