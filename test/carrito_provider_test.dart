import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/models/estado_carrito.dart';
import 'package:prototipo_app/models/item_carrito.dart';
import 'package:prototipo_app/models/producto.dart';
import 'package:prototipo_app/providers/carrito_provider.dart';

const producto = Producto(
  nombre: 'Producto demo',
  subtitulo: 'Digital',
  categoria: 'Software',
  colores: [Colors.blue],
  entrega: 'Automática',
  precio: 6,
  logo: '',
  banner: '',
);

Producto otro({
  String nombre = 'Otro',
  double? precio = 7.9,
  List<Color> colores = const [Colors.red],
}) => Producto(
  nombre: nombre,
  subtitulo: 'Digital',
  categoria: 'Software',
  colores: colores,
  entrega: 'Manual',
  precio: precio,
  logo: '',
  banner: '',
);

void main() {
  late ProviderContainer container;
  late CarritoNotifier carrito;
  EstadoCarrito estado() => container.read(carritoProvider);
  setUp(() {
    container = ProviderContainer();
    carrito = container.read(carritoProvider.notifier);
  });
  tearDown(() => container.dispose());

  test('Empieza vacío con totales cero', () {
    expect(estado().vacio, isTrue);
    expect(estado().cantidadTotal, 0);
    expect(estado().total, 0);
  });
  test('Ignora productos sin precio', () {
    carrito.agregar(otro(precio: null));
    expect(estado().vacio, isTrue);
  });
  test('Agrega un producto disponible y calcula su subtotal', () {
    carrito.agregar(producto);
    expect(estado().items.single.cantidad, 1);
    expect(estado().items.single.subtotal, 6);
    expect(estado().vacio, isFalse);
  });
  test('Agrupa por nombre y conserva los datos de la primera línea', () {
    carrito.agregar(producto);
    carrito.agregar(otro(nombre: producto.nombre, precio: 100));
    expect(estado().items, hasLength(1));
    expect(estado().items.single.cantidad, 2);
    expect(estado().items.single.producto.precio, 6);
    expect(estado().total, 12);
  });
  test('Mantiene separadas las variantes con nombres distintos', () {
    carrito.agregar(otro(nombre: 'JUEGO · ID 123'));
    carrito.agregar(otro(nombre: 'JUEGO · ID 456'));
    expect(estado().items, hasLength(2));
    expect(estado().cantidadTotal, 2);
  });
  test('Aumenta y disminuye sobre la cantidad vigente', () {
    carrito.agregar(producto);
    carrito.cambiarCantidad(producto.nombre, 2);
    carrito.cambiarCantidad(producto.nombre, -1);
    expect(estado().items.single.cantidad, 2);
    expect(estado().total, 12);
  });
  test('Elimina la línea al llegar a cero o a una cantidad negativa', () {
    for (final delta in [-1, -10]) {
      carrito.agregar(producto);
      carrito.cambiarCantidad(producto.nombre, delta);
      expect(estado().vacio, isTrue);
    }
  });
  test('Agregar repetidamente respeta el máximo de 99', () {
    for (var i = 0; i < 105; i++) {
      carrito.agregar(producto);
    }
    expect(estado().items.single.cantidad, 99);
    expect(estado().total, 594);
  });
  test('Ignora incrementos que superan 99 sin recortar el delta', () {
    carrito.agregar(producto);
    carrito.cambiarCantidad(producto.nombre, 99);
    expect(estado().items.single.cantidad, 1);
    carrito.cambiarCantidad(producto.nombre, 98);
    carrito.cambiarCantidad(producto.nombre, 1);
    expect(estado().items.single.cantidad, 99);
  });
  test('Quita solo el producto indicado e ignora nombres inexistentes', () {
    carrito.agregar(producto);
    carrito.agregar(otro());
    carrito.quitar(producto.nombre);
    carrito.quitar('Inexistente');
    carrito.cambiarCantidad('Inexistente', 1);
    expect(estado().items.single.producto.nombre, 'Otro');
  });
  test('Vacía todas las líneas y restablece los totales', () {
    carrito.agregar(producto);
    carrito.agregar(otro());
    carrito.vaciar();
    carrito.vaciar();
    expect(estado().vacio, isTrue);
    expect(estado().cantidadTotal, 0);
    expect(estado().total, 0);
  });
  test('Suma cantidades y subtotales de varias líneas', () {
    carrito.agregar(producto);
    carrito.agregar(producto);
    carrito.agregar(otro());
    expect(estado().cantidadTotal, 3);
    expect(estado().total, closeTo(19.9, 0.000001));
  });
  test('Las instantáneas anteriores no cambian tras actualizar o vaciar', () {
    carrito.agregar(producto);
    final anterior = estado();
    carrito.cambiarCantidad(producto.nombre, 1);
    expect(anterior.items.single.cantidad, 1);
    expect(anterior.total, 6);
    expect(estado().items.single.cantidad, 2);
    carrito.vaciar();
    expect(anterior.items.single.cantidad, 1);
    expect(() => anterior.items.clear(), throwsUnsupportedError);
  });
  test(
    'El estado copia la lista y congela también los colores del producto',
    () {
      final colores = <Color>[Colors.red];
      final lista = [ItemCarrito(otro(colores: colores))];
      final snapshot = EstadoCarrito(items: lista);
      lista.clear();
      colores[0] = Colors.green;
      expect(snapshot.items.single.producto.colores, [Colors.red]);
      expect(
        () => snapshot.items.add(ItemCarrito(producto)),
        throwsUnsupportedError,
      );
      expect(
        () => snapshot.items.single.producto.colores.clear(),
        throwsUnsupportedError,
      );
      carrito.agregar(otro(colores: colores));
      colores.clear();
      expect(estado().items.single.producto.colores, [Colors.green]);
    },
  );
  test('Los contenedores independientes no comparten carritos', () {
    final otroContainer = ProviderContainer();
    addTearDown(otroContainer.dispose);
    carrito.agregar(producto);
    expect(otroContainer.read(carritoProvider).vacio, isTrue);
  });
  test(
    'Conserva el carrito al quedarse temporalmente sin observadores',
    () async {
      final subscription = container.listen(carritoProvider, (_, _) {});
      carrito.agregar(producto);
      subscription.close();
      await container.pump();
      expect(estado().items.single.cantidad, 1);
    },
  );
}
