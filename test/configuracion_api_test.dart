import 'package:flutter_test/flutter_test.dart';
import 'package:prototipo_app/core/configuracion_api.dart';

void main() {
  test('El origen predeterminado es mock y la URL es pública HTTPS', () {
    final configuracion = ConfiguracionApi();
    expect(configuracion.origen, OrigenCatalogo.mock);
    expect(configuracion.urlBase, ConfiguracionApi.urlProduccion);
    expect(ConfiguracionApi.desdeEntorno().origen, OrigenCatalogo.mock);
  });

  test('API requiere selección expresa y admite otra URL HTTPS', () {
    final configuracion = ConfiguracionApi(
      origen: 'api',
      urlBase: 'https://catalogo.example/',
    );
    expect(configuracion.origen, OrigenCatalogo.api);
    expect(configuracion.urlBase, 'https://catalogo.example');
  });

  for (final origen in ['', 'API', 'automatico', ' api ']) {
    test('Rechaza el origen inválido "$origen" sin elegir mock', () {
      expect(() => ConfiguracionApi(origen: origen), throwsFormatException);
    });
  }

  for (final url in [
    '',
    'api.example',
    'http://catalogo.example',
    'ftp://catalogo.example',
    'https://usuario:secreto@catalogo.example',
    'https://catalogo.example/api',
    'https://catalogo.example?token=secreto',
    'https://catalogo.example#fragmento',
  ]) {
    test('Rechaza una URL insegura o ambigua: $url', () {
      expect(() => ConfiguracionApi(urlBase: url), throwsFormatException);
    });
  }

  test('Permite HTTP exclusivamente para servidores locales de desarrollo', () {
    for (final url in [
      'http://localhost:8080',
      'http://127.0.0.1:8080',
      'http://[::1]:8080',
    ]) {
      expect(ConfiguracionApi(origen: 'api', urlBase: url).urlBase, url);
    }
  });
}
