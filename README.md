# prototipo_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Catálogo local y API de Railway

El origen predeterminado es `mock`. Solo se utiliza Laravel cuando se especifica
`--dart-define=CATALOGO_ORIGEN=api`. La selección y la URL se resuelven al compilar;
para cambiarlas hay que reiniciar la ejecución o recompilar.

Datos locales, sin solicitudes HTTP del catálogo:

```sh
flutter run --dart-define=CATALOGO_ORIGEN=mock
```

Datos remotos, exclusivamente desde PostgreSQL mediante Laravel:

```sh
flutter run --dart-define=CATALOGO_ORIGEN=api --dart-define=API_BASE_URL=https://weikangapi-production.up.railway.app
```

Para probar en Brave, iniciar un servidor web y abrir `http://localhost:8080`
en ese navegador:

```sh
flutter run -d web-server --web-port=8080 --dart-define=CATALOGO_ORIGEN=api --dart-define=API_BASE_URL=https://weikangapi-production.up.railway.app
```

`API_BASE_URL` tiene como valor predeterminado el origen público de Railway.
Debe contener únicamente el origen HTTPS, sin `/api`, query, fragmento ni
credenciales. HTTP se admite exclusivamente para localhost, 127.0.0.1 y ::1.
Un origen de catálogo o una URL inválidos generan error; no seleccionan mock.
Los `dart-define` de Flutter Web son públicos: no introducir secretos en ellos.

### Carga, errores y reintentos

`catalogoRepositoryProvider` selecciona `ProductoService` o `ApiCatalogoRepository`.
Ambos alimentan el mismo `catalogoProvider` y sus secciones derivadas. No hay
listas paralelas, mezcla de productos, caché HTTP ni fallback automático.

El cliente Dio se comparte durante la vida del `ProviderScope`, con 10 segundos
de conexión y 20 de recepción. Se cierra mediante `ref.onDispose`; reintentar
el catálogo no recrea el cliente ni modifica el carrito.

En modo API se solicita `GET /api/v1/products`, sin autenticación ni cookies.
La respuesta debe tener un objeto con `data` de tipo lista. Se conserva su orden;
`data: []` es un catálogo vacío válido. No se impone que siempre haya 34 productos
en ejecución: ese número y sus atributos se comprueban en las pruebas del catálogo
actual. Una respuesta incorrecta genera error, sin mostrar un catálogo parcial.

Los errores HTTP, de conexión, timeout, certificado y formato muestran un mensaje
y la opción «Reintentar». El botón invalida únicamente `catalogoProvider`.
No hay reintentos automáticos. Un fallo de red en el navegador también puede
proceder de CORS o del bloqueo del navegador; no se diagnostica como CORS sin
comprobar las cabeceras y la consola.

### Conversión y compatibilidad

`ProductoApiDto` valida los campos utilizados por el modelo actual:

| API | Modelo Flutter |
| --- | --- |
| `name`, `subtitle`, `category` | `nombre`, `subtitulo`, `categoria` |
| `price_cents`, `previous_price_cents` | `precio`, `precioAntes` |
| `is_featured`, `is_new` | `top`, `nuevo` |
| `logo_asset`, `banner_asset` | `logo`, `banner` |
| `colors` (`#AARRGGBB`) | `colores`, lista inmutable de `Color` |
| `delivery`, `type` | `entrega`, `tipo` |

Los precios se validan como enteros no negativos dentro del rango INTEGER de
PostgreSQL, o `null`. Se dividen una sola vez entre 100 al construir `Producto`,
que conserva su tipo `double`: 790 equivale al mismo 7.90 que el mock. Las pruebas
comparan los 34 importes y su equivalencia en céntimos. Esto conserva la precisión
actual; no convierte el modelo ni el carrito en aritmética decimal exacta.

Se exige moneda PEN y coherencia de `available` con el precio y de `is_on_sale`
con ambos precios. Un importe cero sigue disponible; un precio nulo sigue sin
disponibilidad. Los identificadores, fechas y posición que entrega el backend
no requieren cambios en el modelo visual ni en la agrupación actual del carrito.

Las imágenes siguen siendo referencias a assets locales, con sus mayúsculas
originales. No se antepone la URL de Laravel: `ImagenProducto` conserva `Image.asset`.
Las listas y colores publicados son inmutables. Búsqueda, filtros, formularios,
paquetes de juegos, opciones de redes y compras simuladas conservan su lógica.

### Web, GitHub Pages y Android

Compilación remota para la ruta actual de GitHub Pages:

```sh
flutter build web --release --base-href /WS_PROTOTIPO_WEB/ --dart-define=CATALOGO_ORIGEN=api --dart-define=API_BASE_URL=https://weikangapi-production.up.railway.app
```

Para generar esa misma compilación con datos locales, utilizar
`--dart-define=CATALOGO_ORIGEN=mock`. La API usa una URL absoluta y no depende del
`base-href`. El resultado está en `build/web`; compilar no publica la aplicación.
No se han modificado los archivos ni el procedimiento de despliegue de GitHub Pages.

Android incluye `android.permission.INTERNET` en el manifest principal, también
para release. Se conserva HTTPS y la validación de certificados; no se habilita
tráfico HTTP externo ni se modifica la firma de la aplicación.

```sh
flutter build apk --debug --dart-define=CATALOGO_ORIGEN=api --dart-define=API_BASE_URL=https://weikangapi-production.up.railway.app
```

Las consultas públicas y los OPTIONS comprobados permiten los orígenes locales
y de GitHub Pages mediante `Access-Control-Allow-Origin: *`, sin credenciales.
No ha sido necesario modificar Laravel. Si esa política cambia, habrá que
autorizar expresamente los orígenes correspondientes en el backend; esta integración
no cambia CORS, Railway ni PostgreSQL.

### Pruebas

```sh
flutter analyze
flutter test
git diff --check
```

Las pruebas HTTP usan un `HttpClientAdapter` de Dio sin nuevas dependencias ni
acceso a Railway. `test/fixtures/catalogo_api.json` es una respuesta real guardada
exclusivamente para pruebas; no es otro catálogo de ejecución. Se compara con
los datos de `ProductoService` y con los assets empaquetados.

La suite conserva el fallo conocido de `home_alignment_test.dart` por el overflow
preexistente de 6 px. Sus verificaciones y el resto de las pruebas anteriores
permanecen intactos. El detalle de las comprobaciones visuales está en
`PENDIENTES_UI.md`.

Resultados de esta integración: 68 pruebas nuevas aprobadas y 140 aprobadas en
la suite completa, con el único fallo responsive de 6 px ya documentado.
La compilación Web release en modo API y el APK debug terminaron correctamente.
En Brave headless se comprobó la carga real de los 34 productos desde Railway,
el error de conexión simulado y la recuperación con «Reintentar», sin excepciones
JavaScript. No había un dispositivo Android conectado: su ejecución real queda
pendiente. Las seis resoluciones comparadas mantienen el diseño y los errores
preexistentes. No se hicieron commits, push ni despliegues.
