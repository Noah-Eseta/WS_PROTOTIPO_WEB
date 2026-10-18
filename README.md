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

## Autenticación real con Sanctum

La autenticación usa siempre Laravel mediante el cliente Dio compartido, incluso
con `CATALOGO_ORIGEN=mock`. No quedan credenciales ni sesiones simuladas en la app.
`SesionService` conserva su archivo como exportación del provider; ya no almacena
estado. No se añadieron dependencias.

`AuthRepository` / `ApiAuthRepository` utilizan estos endpoints:

| Acción | Petición | Respuesta utilizada |
| --- | --- | --- |
| Registro | `POST /api/v1/auth/register` | `data.user`, `data.token`, `data.token_type`, `data.expires_at` |
| Login | `POST /api/v1/auth/login` | Los mismos campos de sesión |
| Perfil | `GET /api/v1/auth/me` | `data.id`, `data.name`, `data.email` |
| Logout | `POST /api/v1/auth/logout` | `message` |

El usuario contiene únicamente ID, nombre y correo. El registro envía `name`,
`email`, `password` y `password_confirmation`; exige al menos 12 caracteres y
confirmación coincidente. Laravel conserva la validación definitiva, incluidos
los límites del algoritmo de hashing. El correo se normaliza antes de enviarlo.
Los errores 422 se muestran en sus campos; 401, 429, conexión y timeout utilizan
mensajes seguros. No se muestran excepciones internas ni se registran credenciales.

`authProvider` mantiene un único `AuthNotifier`, sin auto-dispose, en el scope raíz.
El estado observable es inmutable y no contiene el token. La credencial permanece
en un campo privado, exclusivamente en memoria, tanto en Web como en Android.
Recargar la página o reiniciar el proceso exige iniciar sesión nuevamente. No se
usan localStorage, sessionStorage, SharedPreferences ni cookies para persistirla.
Android Keystore queda pendiente de autorización para añadir almacenamiento seguro.

La autenticación exige HTTPS y no sigue redirecciones. `Authorization` se añade
solo a cada petición privada; nunca se modifica la cabecera global de Dio ni se
envía el token al catálogo. Se respeta `expires_at` del servidor mediante un
temporizador y una comprobación al reanudar. Un 401 en `/me` limpia la sesión.
No se implementaron renovación ni refresh tokens.

Las operaciones bloquean duplicados y descartan respuestas de una generación
anterior o de un scope destruido. Logout elimina la sesión local inmediatamente
y solicita revocación remota; si falla la conexión se informa de que no pudo
confirmarse esa revocación. El token remoto puede seguir vigente hasta caducar.

El catálogo permanece público. Perfil, saldo y pago requieren sesión; al caducar
se muestra login conservando la ruta. El perfil consulta `/me` y muestra nombre y
correo reales, sin simular cambios de perfil, teléfono ni Google. El formulario
de cuenta es de solo lectura y explica que la edición no está disponible.
Se reutiliza la estructura visual del login en registro.

Los pedidos simulados y puntos siguen siendo demostraciones locales. La billetera
ficticia se integra ahora con PostgreSQL mediante la API descrita al final de este
documento; no se utiliza para descontar compras simuladas. Las confirmaciones de
otra cuenta quedan bloqueadas. El carrito persistente conserva sus datos en el
servidor y retira de la pantalla sus datos privados cuando termina la sesión.

### Ejecución conectada a Railway

Web (abrir la URL del servidor en Brave):

```sh
flutter run -d web-server --web-port=8080 --dart-define=CATALOGO_ORIGEN=api --dart-define=API_BASE_URL=https://weikangapi-production.up.railway.app
```

Android (sustituir el identificador por uno de `flutter devices`):

```sh
flutter run -d <identificador-android> --dart-define=CATALOGO_ORIGEN=api --dart-define=API_BASE_URL=https://weikangapi-production.up.railway.app
```

Para mantener el catálogo local, cambiar a `--dart-define=CATALOGO_ORIGEN=mock`;
login y registro seguirán siendo reales. Los comandos de compilación Web con
`--base-href /WS_PROTOTIPO_WEB/` y APK indicados arriba incluyen autenticación.
Compilar no publica ni despliega.

### Archivos de la integración de autenticación

| Grupo | Archivos nuevos |
| --- | --- |
| Contrato y HTTP | `lib/repositories/auth_repository.dart`, `lib/repositories/api_auth_repository.dart`, `lib/core/http/error_autenticacion.dart` |
| Modelos y estado | `lib/models/usuario_autenticado.dart`, `lib/models/estado_autenticacion.dart`, `lib/models/dto/autenticacion_api_dto.dart`, `lib/providers/auth_provider.dart` |
| Presentación | `lib/screens/registro_screen.dart`, `lib/widgets/autenticacion/estructura_autenticacion.dart`, `lib/widgets/autenticacion/acceso_autenticado.dart` |
| Pruebas | `test/auth_repository_test.dart`, `test/auth_notifier_test.dart`, `test/auth_widgets_test.dart`, `test/support/auth_test_repository.dart` |

| Grupo | Archivos modificados |
| --- | --- |
| Integración | `lib/main.dart`, `lib/core/acceso_compra.dart`, `lib/services/sesion_service.dart` |
| Pantallas | `lib/screens/home_screen.dart`, `lib/screens/login_screen.dart`, `lib/screens/perfil_screen.dart`, `lib/screens/saldo_screen.dart`, `lib/screens/pago_screen.dart` |
| Consumidores y textos de demostración | `lib/widgets/cabecera_tienda.dart`, `lib/widgets/perfil_configuracion.dart`, `lib/widgets/perfil_resumen.dart`, `lib/widgets/perfil_billetera.dart`, `lib/widgets/perfil_compras.dart`, `lib/widgets/perfil_rewards.dart` |
| Limpieza de datos demo | `lib/services/pedido_service.dart`, `lib/services/saldo_service.dart` |
| Preparación de pruebas existentes | `test/carrito_riverpod_test.dart`, `test/catalogo_riverpod_test.dart`, `test/catalogo_api_provider_test.dart`, `test/detalle_juegos_test.dart`, `test/detalle_redes_test.dart`, `test/pago_screen_test.dart`, `test/saldo_flow_test.dart`, `test/ventana_notificaciones_test.dart` |
| Documentación | `README.md`, `PENDIENTES_UI.md` |

Las pruebas existentes conservan sus verificaciones; se sustituye la preparación
que usaba `SesionService` por un repositorio falso inyectado. Las nuevas cubren HTTP,
registro, login, validaciones, errores, caducidad, respuestas tardías, logout,
`/me`, protección, navegación y conservación del carrito. Los fixtures no contienen
cuentas reales y las pruebas no crean usuarios en Railway.

Se comprobaron preflights desde `https://noah-eseta.github.io`: los cuatro endpoints
admiten `Authorization` y `Content-Type` con origen `*` sin cookies. Brave comprobó
`/me` con una credencial inválida de diagnóstico y obtuvo el JSON 401 esperado sin
bloqueo CORS. No se cambió el backend. `Retry-After` no está expuesto a JavaScript;
el mensaje 429 no depende de leer esa cabecera.

Quedan pendientes la validación con credenciales reales introducidas por el
propietario y la ejecución en Android; no había un dispositivo conectado. Las
compilaciones Web release y APK debug se generaron correctamente. Los diagnósticos
locales de Brave y responsive están en `.dart_tool/auth_audit/`, ignorado por Git.
Los problemas visuales preexistentes se documentan en `PENDIENTES_UI.md`.

Resultado final de esta etapa: `flutter analyze` sin incidencias; 55 pruebas nuevas
aprobadas y 195 aprobadas en la suite completa. Persiste únicamente el fallo de
`home_alignment_test.dart` por el overflow de 6 px, sin modificar esa prueba.
`git diff --check` no detecta errores de espacios. Las compilaciones Web release
y APK debug finalizaron correctamente; no se hicieron commits, push ni despliegues.

## Carrito persistente en Laravel

La integración actual conserva el carrito de cada cuenta en PostgreSQL y utiliza
UUID, versiones y fusiones idempotentes. El pago continúa como simulación local
y nunca elimina productos persistentes. Contrato, archivos, pruebas, límites y
comandos de ejecución en [docs/CARRITO_PERSISTENTE.md](docs/CARRITO_PERSISTENTE.md).

## Billetera ficticia persistente

El saldo de demostración es ficticio, en PEN, y procede exclusivamente de Laravel.
`SaldoService` se conserva como archivo legado sin consumidores en la aplicación;
no se sincroniza ni se utiliza como respaldo al fallar la red. Cero solo se muestra
cuando lo confirma una respuesta válida; una billetera con `id: null` y saldo cero
es válida. Cabecera, perfil y saldo utilizan la misma instantánea Riverpod por cuenta.
El catálogo conserva sus 34 productos y el pago simulado no llama a esta API.

Se reutilizan `AuthNotifier`, el token solo en memoria y el Dio compartido. No hay
dependencias nuevas, almacenamiento persistente de tokens, cookies ni credenciales
en el frontend. El repositorio exige HTTPS, no sigue redirecciones ni agrega
Authorization al cliente global. Los DTO validan moneda, carácter ficticio,
enteros, límites, UUID, versiones, fechas UTC y coherencia de los movimientos.

### Consultas y permisos

- `GET /api/v1/wallet` y `/wallet/transactions`: saldo e historial propios.
- `GET /api/v1/admin/wallets?per_page=1`: confirma el permiso mediante una lectura
  autorizada del servidor. Ni el ID 1 ni un correo conceden permisos en Flutter.
- `GET /api/v1/admin/wallets`, `/{user}` y `/{user}/transactions`: administración.
- `POST /api/v1/admin/wallets/{user}/credits`: asignación de créditos ficticios.

La sección administrativa aparece solo después de recibir y validar una respuesta
autorizada. Un 403 la oculta sin cerrar una sesión válida; un error de conexión
deja el permiso sin confirmar. Laravel autoriza también cada escritura. No se
implementa una pantalla de ajustes ni débito, pagos o pedidos persistentes.

Las listas utilizan `meta.next_cursor`, no números de página ni URLs arbitrarias
del servidor. Se deduplican movimientos por UUID y usuarios por ID. El historial
señala que el contador corresponde a los movimientos cargados; no inventa totales
globales. Los avisos del perfil y la cabecera proceden de los movimientos cargados.
Los pedidos de demostración se siguen identificando como simulaciones locales.

Al cerrar sesión, caducar o cambiar de cuenta se limpian los datos privados,
permisos e intentos. Una revisión efímera distingue incluso dos sesiones de la
misma cuenta con igual fecha de caducidad. Las respuestas tardías no restauran los
datos anteriores. No se borra la billetera, su historial ni el carrito del servidor.

### Créditos e idempotencia

El importe se convierte desde texto con enteros, sin cálculos monetarios con double.
Se admite de S/0.01 a S/10,000.00 por operación, con justificación de 1 a 500
caracteres después de recortar extremos. No se envían saldo final, permisos,
moneda elegible ni identidad del administrador en el cuerpo.

Cada intención genera un UUID v4 con `Random.secure`. Se bloquea el doble envío y
no se reintentan POST automáticamente. Si una respuesta se pierde, se conservan
UUID, destinatario, importe y motivo; el formulario bloquea su edición y permite
reintentar exactamente la misma intención. No se incrementa el saldo visual antes
de confirmar. Un comprobante repetido se reconoce y se consulta el saldo actual;
su `balance_after_cents` es histórico y nunca sustituye esa consulta.

Si el crédito se confirmó pero falla la actualización, se informa de ambos hechos:
se reintenta la consulta, sin volver a enviar el crédito. Los conflictos 409
invalidan las consultas afectadas y no se resuelven con escrituras automáticas.
También se manejan 401, 403, 404, 422, 429 y errores de conexión con mensajes seguros.

Los intentos pendientes viven en memoria y se limpian al terminar la sesión.
Cerrar o recargar la página pierde esa información: no hay reenvío automático.
Si había un resultado incierto, revisar el historial antes de crear una operación
nueva; un UUID nuevo representaría otra operación. Recuperar ese intento después
de cerrar la página requeriría persistencia controlada o una consulta por UUID,
fuera del contrato actual. El token nunca se persiste.

### Probar con la cuenta administradora de Railway

```sh
flutter run -d web-server --web-port=8080 --dart-define=CATALOGO_ORIGEN=api --dart-define=API_BASE_URL=https://weikangapi-production.up.railway.app
```

Abrir la URL en Brave e iniciar sesión con la cuenta autorizada. Entrar en
«Ver mi billetera» desde el perfil o pulsar el saldo de la cabecera; después,
«Administrar créditos ficticios». Seleccionar una cuenta, revisar saldo e historial
y asignar un importe pequeño con justificación. Comprobar el movimiento y el saldo
actualizado. Cerrar sesión y entrar como destinatario debe recuperar esos datos.
Una cuenta sin permiso no debe ver administración. Confirmar un pago simulado no
debe modificar saldo ni historial de billetera ni borrar el carrito persistente.

Android, con el dispositivo conectado, utiliza el mismo comando sustituyendo
`web-server` por el ID de `flutter devices` y omitiendo `--web-port`.

Compilaciones locales; estos comandos no publican la aplicación:

```sh
flutter build web --release --base-href /WS_PROTOTIPO_WEB/ --dart-define=CATALOGO_ORIGEN=api --dart-define=API_BASE_URL=https://weikangapi-production.up.railway.app
flutter build apk --debug --dart-define=CATALOGO_ORIGEN=api --dart-define=API_BASE_URL=https://weikangapi-production.up.railway.app
```

El catálogo continúa admitiendo `CATALOGO_ORIGEN=mock`; autenticación, carrito
persistente y billetera siguen utilizando la API. Los preflights reales del
18/10/2026 para saldo GET y créditos POST desde `https://noah-eseta.github.io`
respondieron 204 y admitieron `Authorization` y `Content-Type`, sin cookies.
No se cambió el backend. La prueba con una cuenta administradora real queda a
cargo del propietario; las pruebas automatizadas utilizan repositorios aislados
y no crean créditos en Railway. No había un dispositivo Android conectado.

### Archivos de billetera y pruebas

Nuevos: `lib/models/billetera.dart`, `lib/models/dto/wallet_api_dto.dart`,
`lib/core/http/error_billetera.dart`, `lib/repositories/wallet_repository.dart`,
`lib/repositories/api_wallet_repository.dart`, `lib/providers/wallet_provider.dart`,
`lib/providers/admin_wallet_provider.dart`, `lib/screens/admin_billetera_screen.dart`,
`lib/widgets/billetera/historial_billetera.dart` y `formulario_credito.dart`.

Se adaptan `auth_provider.dart`, `saldo_screen.dart`, `perfil_screen.dart`,
`cabecera_tienda.dart`, `perfil_billetera.dart`, `perfil_resumen.dart`,
`perfil_configuracion.dart` y `ventana_notificaciones.dart`. La autenticación
mantiene sus reglas; se integra el 401 de billetera, la revisión de sesión y se
retira la limpieza del servicio de saldo legado.

Nuevas pruebas: `wallet_repository_test.dart`, `wallet_provider_test.dart`,
`wallet_widgets_test.dart` y `support/wallet_test_repository.dart`. Las pruebas
existentes reciben el repositorio de billetera aislado donde corresponde. El
recorrido de autorrecarga local se sustituye por consulta y actualización remotas;
se conservan las verificaciones de geometría y el fallo conocido de Home.
Los problemas visuales pendientes permanecen en `PENDIENTES_UI.md`.

Preparación actualizada en las pruebas existentes: `auth_notifier_test.dart`,
`auth_widgets_test.dart`, `carrito_remoto_test.dart`, `carrito_remoto_widgets_test.dart`,
`carrito_riverpod_test.dart`, `catalogo_api_provider_test.dart`, `catalogo_riverpod_test.dart`,
`detalle_juegos_test.dart`, `detalle_redes_test.dart`, `pago_screen_test.dart`,
`perfil_secciones_test.dart`, `saldo_flow_test.dart`, `ventana_notificaciones_test.dart`
y `support/auth_test_repository.dart`. Se inyecta el repositorio remoto aislado y
se esperan las nuevas cargas asíncronas; no se cambian tolerancias ni selectores
del test de Home. En total, 14 archivos nuevos y 24 existentes modificados,
incluida esta documentación y `PENDIENTES_UI.md`.

Resultado de la validación: `flutter analyze` sin incidencias; `flutter test`
con 344 pruebas aprobadas y un único fallo conocido, `home_alignment_test.dart`
por el overflow de 6 px. Las 90 pruebas nuevas de billetera aprueban, incluidos
los seis anchos, estado privado, idempotencia y conservación del saldo e historial
al confirmar un pago simulado. `git diff --check` no detecta errores de espacios.
Los builds Web release y APK debug son locales; no se publica contenido de `docs/`.
Brave headless cargó los 34 productos (11 no disponibles), obtuvo los 401 esperados
de saldo, historial y administración a través de CORS y no registró excepciones
de ejecución en ese recorrido público. Los informes locales están en
`.dart_tool/wallet_audit/` y los logs de validación en `.dart_tool/wallet_*.log`,
todos ignorados por Git. La comprobación autenticada con una cuenta real y la
ejecución en un dispositivo Android siguen pendientes.
