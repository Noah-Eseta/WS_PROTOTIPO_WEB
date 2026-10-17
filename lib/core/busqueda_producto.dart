import '../models/producto.dart';

String normalizarBusqueda(String texto) => texto
    .toLowerCase()
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u')
    .trim();

List<Producto> buscarProductos(List<Producto> productos, String texto) {
  final consulta = normalizarBusqueda(texto);
  if (consulta.isEmpty) return const [];
  return productos
      .where((producto) {
        final contenido = normalizarBusqueda(
          '${producto.nombre} ${producto.subtitulo} ${producto.categoria}',
        );
        return contenido.contains(consulta);
      })
      .toList(growable: false);
}
