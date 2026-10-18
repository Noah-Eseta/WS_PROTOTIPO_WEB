import '../core/http/error_carrito.dart';
import 'item_carrito.dart';

/// Única representación visible: datos remotos confirmados y selecciones locales.
final class EstadoCarrito {
  final List<ItemCarrito> locales;
  final List<ItemCarrito> remotos;
  final List<ItemCarrito> items;
  final int? usuarioId;
  final int? version;
  final bool sincronizando;
  final bool necesitaConsulta;
  final bool fusionPendiente;
  final ErrorCarrito? error;
  EstadoCarrito({
    Iterable<ItemCarrito> items = const [],
    Iterable<ItemCarrito> remotos = const [],
    this.usuarioId,
    this.version,
    this.sincronizando = false,
    this.necesitaConsulta = false,
    this.fusionPendiente = false,
    this.error,
  }) : locales = List.unmodifiable(items),
       remotos = List.unmodifiable(remotos),
       items = List.unmodifiable([...remotos, ...items]);
  bool get vacio => items.isEmpty;
  int get cantidadTotal => items.fold(0, (s, item) => s + item.cantidad);
  int get totalCentimos =>
      items.fold(0, (s, item) => s + (item.subtotalCentimos ?? 0));
  double get total => totalCentimos / 100;
  bool get contieneNoDisponibles => items.any((i) => !i.producto.disponible);
  bool get puedeSimular =>
      !vacio &&
      !sincronizando &&
      !fusionPendiente &&
      !necesitaConsulta &&
      !contieneNoDisponibles &&
      (usuarioId == null || version != null);
  EstadoCarrito copiar({
    Iterable<ItemCarrito>? locales,
    Iterable<ItemCarrito>? remotos,
    int? version,
    bool? sincronizando,
    bool? necesitaConsulta,
    bool? fusionPendiente,
    ErrorCarrito? error,
    bool limpiarError = false,
  }) => EstadoCarrito(
    items: locales ?? this.locales,
    remotos: remotos ?? this.remotos,
    usuarioId: usuarioId,
    version: version ?? this.version,
    sincronizando: sincronizando ?? this.sincronizando,
    necesitaConsulta: necesitaConsulta ?? this.necesitaConsulta,
    fusionPendiente: fusionPendiente ?? this.fusionPendiente,
    error: limpiarError ? null : error ?? this.error,
  );
}
