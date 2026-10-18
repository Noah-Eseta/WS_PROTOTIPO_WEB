# Carrito persistente: Flutter y Laravel

La aplicación mantiene un único estado visible, carritoProvider. No hay un
servicio paralelo ni otra caché. EstadoCarrito contiene líneas remotas confirmadas
y selecciones locales, con colecciones y productos inmutables. Los totales se
calculan con enteros en céntimos y se convierten a decimales para la presentación.

## Identidad y HTTP

Producto.id conserva el UUID real de Laravel, también en las copias inmutables.
Los 34 productos mock contienen los mismos UUID que el fixture remoto, sin duplicar
la lista. Se conservan sus atributos, orden, assets y 11 productos no disponibles.

El origen del catálogo sigue siendo configurable: mock por defecto y api
expresamente. La autenticación y el carrito de una cuenta son siempre remotos,
también con catálogo visual mock. Un visitante no realiza peticiones de carrito.
No existe fallback local cuando falla el carrito de la cuenta.

Las líneas remotas se identifican por UUID. Nombres, disponibilidad y precios
actuales proceden de Laravel; las imágenes se resuelven con el catálogo compartido
e Image.asset. Un UUID remoto que ya no figure en el catálogo no se descarta:
mantiene los datos del servidor y puede eliminarse; usa el placeholder existente.

ApiCartRepository reutiliza clienteHttpProvider, sin crear ni cerrar otro Dio.
Exige HTTPS y no sigue redirecciones. AuthNotifier.conToken presta la credencial
por petición, sin publicarla, persistirla o añadirla a cabeceras globales. Tampoco
se envía al catálogo. No se registran credenciales.

| Operación | Petición |
| --- | --- |
| Consultar | GET /api/v1/cart |
| Cantidad absoluta | PUT /api/v1/cart/items/{uuid} con {"quantity":2} |
| Eliminar línea | DELETE /api/v1/cart/items/{uuid} |
| Vaciar expresamente | DELETE /api/v1/cart |
| Fusionar visitante | POST /api/v1/cart/merge con operation_id e items |

Toda modificación lleva X-Cart-Version. Nunca se envían precios, descuentos,
nombres ni configuraciones especiales. Se admiten 1 a 99 unidades; disminuir a
cero equivale a eliminar. Los no disponibles permanecen visibles: no se pueden
añadir o aumentar, pero sí reducir o eliminar, sujeto a confirmación de Laravel.

Se valida el JSON: PEN, versión, UUID únicos, cantidades, precios, subtotales,
totales y disponibilidad. Una respuesta inválida nunca se convierte en carrito
vacío. Se muestran mensajes seguros para 401, 404, 409, 422, 429, desconexión,
timeout y respuestas inesperadas, sin exponer excepciones internas.

## Confirmaciones, fusiones y privacidad

Las modificaciones se serializan y esperan confirmación HTTP antes de cambiar
las líneas remotas. El contador observa el mismo estado. Un error conserva la
última representación confirmada y exige volver a consultar.

Un 409 provoca GET para recuperar los cambios ajenos. No se repite la modificación
ni las modificaciones ya en cola. El usuario decide una nueva acción con la
versión actual. Actualizar solo consulta; Reintentar sincronización permite resolver
explícitamente una fusión pendiente.

Al iniciar sesión se consulta el carrito y se congela un lote con los productos
simples del visitante y un UUID v4 operation_id. Se conservan ID y contenido al
reintentar, incluso si se pierde la respuesta. Solo un comprobante válido permite
retirar esas cantidades locales; después se consulta nuevamente el carrito. Si
este GET falla, el lote ya confirmado no vuelve a sumarse.

Una fusión incierta bloquea la edición de sus líneas. Un 422 o
CART_VERSION_CONFLICT definitivo permite corregirlas: editar invalida ese lote
no aplicado y el siguiente intento genera otra operación. Un lote pendiente
pertenece a su cuenta original; no se reasigna a otra. Volver a esa cuenta permite
resolverlo con el mismo ID.

El lote y el carrito visitante viven en memoria, como antes. No se añade
persistencia en disco. Recargar la Web pierde esas selecciones locales, pero no
borra PostgreSQL ni repite automáticamente una fusión. El carrito remoto se
recupera al iniciar sesión nuevamente: el token también permanece solo en memoria.

Logout, cambio de cuenta y caducidad retiran inmediatamente la representación
privada remota, sin DELETE ni conversión a carrito visitante. Las respuestas
de sesiones anteriores se descartan, incluso un 401 tardío. Se consulta al iniciar
sesión, abrir carrito, reanudar la aplicación y pulsar Actualizar. No hay polling.

## Variantes y simulación

Las selecciones construidas en detalles de juegos y redes se marcan como
especiales. Sus paquetes, ID de jugador, enlaces y configuraciones siguen locales,
sin UUID base ni conversión automática a productos simples. Las líneas indican
su procedencia: cuenta, visitante o demostración local. Una mezcla muestra los
importes separados.

El pago es una demostración local: no cobra, no crea pedidos Laravel y nunca
llama a DELETE del carrito remoto. PedidoService registra primero una instantánea
inmutable.

- Con persistentes o una mezcla, la simulación conserva todo el carrito.
- Con selecciones exclusivamente especiales locales, se consumen solo tras
  registrar correctamente la demostración.
- Si falla o no se completa, no se consumen selecciones.
- Un envío duplicado del botón no registra dos demostraciones.
- Eliminar y vaciar explícitamente siguen siendo acciones distintas y confirmadas
  por Laravel. Un vaciado en curso conserva selecciones locales agregadas después.

No se implementan pagos, billetera, pedidos persistentes ni variantes del backend.

## Ejecución

Web; abrir en Brave la dirección que muestre el servidor:

~~~sh
flutter run -d web-server --web-port=8080 --dart-define=CATALOGO_ORIGEN=api --dart-define=API_BASE_URL=https://weikangapi-production.up.railway.app
~~~

Android; usar un dispositivo de flutter devices:

~~~sh
flutter run -d <identificador-android> --dart-define=CATALOGO_ORIGEN=api --dart-define=API_BASE_URL=https://weikangapi-production.up.railway.app
~~~

Para catálogo local, sustituir CATALOGO_ORIGEN=api por CATALOGO_ORIGEN=mock.
La cuenta y su carrito seguirán usando la API. No se crean cuentas de prueba.

Compilar sin publicar:

~~~sh
flutter build web --release --no-pub --base-href /WS_PROTOTIPO_WEB/ --dart-define=CATALOGO_ORIGEN=api --dart-define=API_BASE_URL=https://weikangapi-production.up.railway.app
flutter build apk --debug --no-pub --dart-define=CATALOGO_ORIGEN=api --dart-define=API_BASE_URL=https://weikangapi-production.up.railway.app
~~~

El permiso Android INTERNET ya existía. No se modifican dependencias, Laravel,
PostgreSQL, Railway ni la publicación de GitHub Pages.

## Archivos

| Tipo | Archivos |
| --- | --- |
| Nuevos: contrato y HTTP | lib/repositories/cart_repository.dart; lib/repositories/api_cart_repository.dart; lib/core/http/error_carrito.dart |
| Nuevos: JSON y presentación | lib/models/dto/carrito_api_dto.dart; lib/widgets/carrito/estado_sincronizacion_carrito.dart |
| Modificados: catálogo e identidad | lib/models/producto.dart; lib/models/dto/producto_api_dto.dart; lib/services/producto_service.dart |
| Modificados: estado | lib/models/item_carrito.dart; lib/models/estado_carrito.dart; lib/providers/carrito_provider.dart; lib/providers/auth_provider.dart |
| Modificados: pantallas | lib/screens/home_screen.dart; lib/screens/carrito_screen.dart; lib/screens/pago_screen.dart; lib/screens/detalle/detalle_producto_base.dart; lib/screens/detalle/detalle_juegos_screen.dart; lib/screens/detalle/detalle_redes_screen.dart |
| Modificados: integración | lib/widgets/cabecera_tienda.dart; lib/widgets/autenticacion/acceso_autenticado.dart |
| Nuevos: pruebas | test/api_cart_repository_test.dart; test/carrito_remoto_test.dart; test/carrito_remoto_widgets_test.dart; test/support/cart_test_repository.dart |
| Modificados: pruebas y soporte | test/support/auth_test_repository.dart; test/auth_notifier_test.dart; test/auth_widgets_test.dart; test/carrito_riverpod_test.dart; test/catalogo_api_provider_test.dart; test/catalogo_riverpod_test.dart; test/detalle_juegos_test.dart; test/detalle_redes_test.dart; test/pago_screen_test.dart; test/saldo_flow_test.dart; test/ventana_notificaciones_test.dart |
| Documentación | README.md; PENDIENTES_UI.md; docs/CARRITO_PERSISTENTE.md |

Las expectativas de logout comprueban ahora conservación en servidor y retirada
de datos privados. Las de compra remota comprueban que la simulación conserva
los productos. Geometría y prueba del overflow de Home permanecen intactas.

## Validación y límites

Las pruebas nuevas usan repositorios y adaptadores HTTP locales: 34 UUID/precios,
inmutabilidad, visitante, recuperación en otro scope, versiones, cantidades,
conflictos, errores, no disponibles, fusiones idempotentes y respuestas perdidas,
cambio de cuenta, respuestas tardías, contador, simulaciones y responsive en
360, 390, 600, 768, 1024 y 1440 px.

Los preflights reales de GitHub Pages admiten GET/PUT/DELETE/POST según la ruta,
Authorization, Content-Type y X-Cart-Version. La versión procede del JSON, sin
depender de una cabecera de respuesta expuesta. El catálogo público real mantiene
34 productos, los mismos UUID/orden y 11 no disponibles. No se modifica CORS.

Diagnósticos locales: .dart_tool/cart_integration_audit/, ignorado por Git.
Home se compara con su archivo anterior en los seis anchos: coinciden imágenes,
estilos, geometría y errores previos. Ambos lados usan los componentes compartidos
actuales. La cabecera incorpora el acceso al carrito visitante. Los estados de
sincronización, procedencia y textos de simulación son ampliaciones necesarias.

Los problemas visuales siguen en PENDIENTES_UI.md, incluido el overflow de 6 px
que hace fallar home_alignment_test.dart. No se ocultan.

La prueba autenticada real entre dos dispositivos y la ejecución física Android
quedan pendientes de una cuenta del propietario y un dispositivo. No se crearon
usuarios ni se probaron mutaciones contra producción.

Resultado: flutter analyze sin incidencias; suite completa con 255 pruebas
aprobadas y únicamente el fallo preexistente de home_alignment_test.dart. Las
60 pruebas nuevas pasan. git diff --check sin errores de espacios. Se generaron
Web release para GitHub Pages y APK debug. Gradle emite advertencias de acceso
nativo de Java y Flutter recomienda opcionalmente WebAssembly; no impiden las
compilaciones y no se cambió configuración para silenciarlas.

Brave headless comprobó el catálogo real, su error/reintento y las respuestas JSON
401 de perfil y carrito con una credencial inválida, sin bloqueo CORS ni
excepciones JavaScript. localStorage y sessionStorage permanecieron vacíos.
