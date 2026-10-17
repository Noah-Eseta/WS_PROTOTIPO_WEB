enum OrigenCatalogo { mock, api }

final class ConfiguracionApi {
  static const urlProduccion = 'https://weikangapi-production.up.railway.app';

  final OrigenCatalogo origen;
  final String urlBase;

  const ConfiguracionApi._(this.origen, this.urlBase);

  factory ConfiguracionApi({
    String origen = 'mock',
    String urlBase = urlProduccion,
  }) {
    final seleccionado = switch (origen) {
      'mock' => OrigenCatalogo.mock,
      'api' => OrigenCatalogo.api,
      _ => throw const FormatException('CATALOGO_ORIGEN debe ser mock o api.'),
    };
    final uri = Uri.tryParse(urlBase);
    final local =
        uri != null &&
        ['localhost', '127.0.0.1', '::1', '[::1]'].contains(uri.host);
    if (uri == null ||
        uri.host.isEmpty ||
        !(uri.scheme == 'https' || (uri.scheme == 'http' && local)) ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw const FormatException(
        'API_BASE_URL debe ser un origen HTTPS válido, sin credenciales ni ruta. '
        'HTTP solo se admite en localhost.',
      );
    }
    return ConfiguracionApi._(seleccionado, uri.replace(path: '').toString());
  }

  factory ConfiguracionApi.desdeEntorno() => ConfiguracionApi(
    origen: const String.fromEnvironment(
      'CATALOGO_ORIGEN',
      defaultValue: 'mock',
    ),
    urlBase: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: urlProduccion,
    ),
  );
}
