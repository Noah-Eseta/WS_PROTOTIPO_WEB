import '../item_carrito.dart';
import '../producto.dart';

final class LineaCarritoApi {
  final String id;
  final String nombre;
  final int cantidad;
  final int? precioCentimos;
  const LineaCarritoApi(
    this.id,
    this.nombre,
    this.cantidad,
    this.precioCentimos,
  );
  ItemCarrito aItem(List<Producto> catalogo) {
    final origen =
        catalogo.where((p) => p.id == id).firstOrNull ??
        Producto(
          id: id,
          nombre: nombre,
          subtitulo: '',
          categoria: '',
          colores: const [],
          entrega: '',
          logo: '',
          banner: '',
        );
    return ItemCarrito(
      origen.conPrecio(
        precioCentimos == null ? null : precioCentimos! / 100,
        nombreActual: nombre,
      ),
      cantidad: cantidad,
      persistente: true,
      precioCentimos: precioCentimos,
    );
  }
}

final class CarritoApiDto {
  final int version;
  final List<LineaCarritoApi> items;
  CarritoApiDto(this.version, Iterable<LineaCarritoApi> items)
    : items = List.unmodifiable(items);
  factory CarritoApiDto.fromJson(Object? json) {
    if (json is! Map<String, dynamic> ||
        json['data'] is! Map<String, dynamic>) {
      throw const FormatException();
    }
    final data = json['data'] as Map<String, dynamic>;
    final version = data['version'], raw = data['items'];
    if (!_entero(version, 0, 999999999999999) ||
        data['currency'] != 'PEN' ||
        raw is! List) {
      throw const FormatException();
    }
    final ids = <String>{};
    final lines = <LineaCarritoApi>[];
    var total = 0, cantidad = 0;
    var noDisponibles = false;
    for (final item in raw) {
      if (item is! Map<String, dynamic>) throw const FormatException();
      final id = item['product_id'],
          name = item['name'],
          qty = item['quantity'];
      final cents = item['unit_price_cents'], available = item['available'];
      if (id is! String ||
          !uuidValido(id) ||
          !ids.add(id.toLowerCase()) ||
          name is! String ||
          name.trim().isEmpty ||
          !_entero(qty, 1, 99) ||
          (cents != null && !_entero(cents, 0, 2147483647)) ||
          !item.containsKey('unit_price_cents') ||
          !item.containsKey('subtotal_cents') ||
          available != (cents != null) ||
          item['subtotal_cents'] !=
              (cents == null ? null : (qty as int) * (cents as int))) {
        throw const FormatException();
      }
      cantidad += qty as int;
      total += cents == null ? 0 : qty * (cents as int);
      noDisponibles |= cents == null;
      lines.add(LineaCarritoApi(id.toLowerCase(), name, qty, cents as int?));
    }
    if (data['quantity_total'] != cantidad ||
        data['total_cents'] != total ||
        data['has_unavailable_items'] != noDisponibles ||
        total > 9007199254740991) {
      throw const FormatException();
    }
    return CarritoApiDto(version as int, lines);
  }
  static bool _entero(Object? n, int min, int max) =>
      n is int && n >= min && n <= max;
}

bool uuidValido(String id) =>
    RegExp(r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$')
        .hasMatch(id);

final class ComprobanteFusion {
  final String operacion;
  final int versionAplicada;
  final int cantidadLineas;
  final bool repetida;
  const ComprobanteFusion(
    this.operacion,
    this.versionAplicada,
    this.cantidadLineas,
    this.repetida,
  );
  factory ComprobanteFusion.fromJson(Object? json) {
    if (json is! Map || json['data'] is! Map) throw const FormatException();
    final data = json['data'] as Map;
    if (data['operation_id'] is! String ||
        !uuidValido(data['operation_id']) ||
        data['status'] != 'applied' ||
        data['applied_version'] is! int ||
        (data['applied_version'] as int) < 1 ||
        data['merged_items_count'] is! int ||
        (data['merged_items_count'] as int) < 1 ||
        data['replayed'] is! bool) {
      throw const FormatException();
    }
    return ComprobanteFusion(
      data['operation_id'].toLowerCase(),
      data['applied_version'],
      data['merged_items_count'],
      data['replayed'],
    );
  }
}
