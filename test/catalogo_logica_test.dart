import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/core/busqueda_producto.dart';
import 'package:prototipo_app/core/catalogo_producto.dart';
import 'package:prototipo_app/models/categoria.dart';
import 'package:prototipo_app/models/producto.dart';
import 'package:prototipo_app/repositories/catalogo_repository.dart';
import 'package:prototipo_app/services/producto_service.dart';

void main() {
  late List<Producto> productos;
  setUp(() async => productos = await ProductoService().obtenerProductos());

  test(
    'El repositorio demo conserva los 34 nombres, precios y su orden',
    () async {
      final CatalogoRepository repositorio = ProductoService();
      final datos = await repositorio.obtenerProductos();
      expect(datos.map((p) => (p.nombre, p.precio, p.precioAntes)), [
        ('FREE FIRE +10%', 19.90, null),
        ('FREE FIRE · OFERTA LIMITADA', 14.90, null),
        ('TIKTOK', 5.90, null),
        ('CANVA PRO', 7.90, 12.90),
        ('INSTAGRAM', 6.90, null),
        ('ROBLOX', 10.00, null),
        ('YOUTUBE PREMIUM', 9.90, null),
        ('MOBILE LEGENDS', 8.90, null),
        ('PRIME VIDEO', 6.00, 11.00),
        ('MAX PLATINO', 6.00, 11.00),
        ('CRUNCHYROLL MEGA FAN', 6.00, 11.00),
        ('VIX PREMIUM', 3.50, 8.50),
        ('PARAMOUNT+', 5.00, 11.00),
        ('APPLE TV+', 6.00, 11.00),
        ('VIKI RAKUTEN', 5.00, 10.00),
        ('TIDAL FAMILIAR', 10.00, 15.00),
        ('NETFLIX', null, null),
        ('DISNEY+', null, null),
        ('SPOTIFY', null, null),
        ('DEEZER', null, null),
        ('CHATGPT PLUS', 9.90, 14.90),
        ('CAPCUT PRO', 8.90, 13.90),
        ('GOOGLE ONE', 18.90, 23.90),
        ('LEONARDO AI', 9.90, 14.90),
        ('MICROSOFT OFFICE', 29.90, 34.00),
        ('NORDVPN', 19.90, 24.90),
        ('KASPERSKY PREMIUM + VPN', 39.90, 44.90),
        ('PUBG MOBILE', null, null),
        ('BLOOD STRIKE', null, null),
        ('DELTA FORCE', null, null),
        ('ARENA BREAKOUT', null, null),
        ('FARLIGHT 84', null, null),
        ('FACEBOOK', null, null),
        ('YOUTUBE', null, null),
      ]);
      expect(datos.where((p) => !p.disponible), hasLength(11));
      expect(() => datos.clear(), throwsUnsupportedError);
      expect(() => datos.first.colores.clear(), throwsUnsupportedError);
    },
  );

  test(
    'Las categorías conservan conteos y orden, incluidos no disponibles',
    () {
      for (final (categoria, cantidad) in [
        (Categoria.streaming, 13),
        (Categoria.software, 8),
        (Categoria.juegos, 9),
        (Categoria.redes, 4),
      ]) {
        final seccion = productosDeSeccion(categoria, productos);
        expect(seccion, hasLength(cantidad));
        expect(
          seccion,
          productos.where((p) => p.categoria == categoria.nombre),
        );
        expect(() => seccion.clear(), throwsUnsupportedError);
      }
    },
  );

  test('Ofertas depende de los precios, no del nombre del producto', () {
    final ofertas = productosDeSeccion(Categoria.ofertas, productos);
    expect(ofertas, hasLength(16));
    expect(ofertas.first.nombre, 'CANVA PRO');
    expect(ofertas.last.nombre, 'KASPERSKY PREMIUM + VPN');
    expect(ofertas.any((p) => p.nombre.contains('OFERTA LIMITADA')), isFalse);

    Producto ejemplo(String nombre, double? precio, double? anterior) =>
        Producto(
          nombre: nombre,
          subtitulo: '',
          categoria: 'Software',
          colores: const [],
          entrega: '',
          precio: precio,
          precioAntes: anterior,
          logo: '',
          banner: '',
        );
    final casos = [
      ejemplo('Sin precio', null, 10),
      ejemplo('Sin anterior', 5, null),
      ejemplo('Iguales', 5, 5),
      ejemplo('Subida', 6, 5),
      ejemplo('Gratis', 0, 5),
    ];
    expect(
      productosDeSeccion(Categoria.ofertas, casos).single,
      same(casos.last),
    );
    expect(casos.last.disponible, isTrue);
  });

  test('Destacados y novedades mantienen sus indicadores y posiciones', () {
    expect(
      productosDeSeccion(Categoria.masVendidos, productos).map((p) => p.nombre),
      [
        'FREE FIRE +10%',
        'FREE FIRE · OFERTA LIMITADA',
        'TIKTOK',
        'NETFLIX',
        'DISNEY+',
        'CHATGPT PLUS',
      ],
    );
    expect(
      productosDeSeccion(Categoria.novedades, productos).map((p) => p.nombre),
      [
        'INSTAGRAM',
        'YOUTUBE PREMIUM',
        'MOBILE LEGENDS',
        'CAPCUT PRO',
        'GOOGLE ONE',
        'LEONARDO AI',
      ],
    );
    expect(productosDeSeccion(Categoria.software, const []), isEmpty);
  });

  test(
    'La búsqueda conserva normalización, campos y orden de coincidencias',
    () {
      expect(buscarProductos(productos, '  yÓuTÚbÉ  ').map((p) => p.nombre), [
        'YOUTUBE PREMIUM',
        'YOUTUBE',
      ]);
      expect(
        buscarProductos(productos, 'software'),
        productosDeSeccion(Categoria.software, productos),
      );
      expect(
        buscarProductos(productos, 'activacion a dominio').map((p) => p.nombre),
        [
          'CANVA PRO',
          'GOOGLE ONE',
          'MICROSOFT OFFICE',
          'KASPERSKY PREMIUM + VPN',
        ],
      );
      expect(buscarProductos(productos, '   '), isEmpty);
      expect(buscarProductos(productos, 'inexistente'), isEmpty);
    },
  );
}
