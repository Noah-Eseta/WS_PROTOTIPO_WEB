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

Saldo, recargas, pedidos, transacciones y puntos siguen siendo demostraciones
locales. Se etiquetan como tales y se limpian al autenticar, cerrar o caducar una
sesión; no están vinculados a PostgreSQL. Las confirmaciones de otra cuenta quedan
bloqueadas. El carrito y sus cantidades se conservan en todos esos casos.

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
