# Pendientes visuales de Home

Última comprobación: 17 de octubre de 2026, al completar la separación del catálogo.

El usuario revisó la tienda y decidió aplazar los desbordamientos menores que no
afectan el uso normal. Esta etapa conserva el diseño, las dimensiones, los estilos
y las animaciones. No se suprimen errores ni se relajan las pruebas existentes.

## Desbordamientos conocidos

Estas medidas proceden de widget tests, con densidad de píxeles 1 y el tema de la
aplicación. No representan una medición en un navegador o dispositivo físico.

| Resolución | Componente | Desbordamiento vertical observado |
| --- | --- | --- |
| 600 × 960 | Columna de texto de `_PromoCard`, en `lib/widgets/home/promociones_laterales.dart` | 21 px |
| 768 × 1024 | Columna de texto de `_PromoCard`, en `lib/widgets/home/promociones_laterales.dart` | 2 px |
| 1440 × 900 | Columna de texto de `MasVendido`, en `lib/widgets/home/tarjetas_destacadas.dart` | 6 px |

Las promociones horizontales tienen 104 px de alto y su texto dispone de 84 px
después del padding. En esas dos resoluciones, los saltos de línea del texto
requieren respectivamente 105 y 86 px en el entorno de pruebas.

Las tarjetas de más vendidos conservan 100 px de alto. En las tarjetas afectadas,
los textos requieren 88 px y la columna dispone de 82 px.

No se observaron desbordamientos en los recorridos comparados a 360 × 800,
390 × 844 y 1024 × 768. Esto describe los recorridos ejecutados, no una cobertura
exhaustiva de todos los productos, escalas de texto y plataformas.

## Estado de la suite

`test/home_alignment_test.dart` conserva sus cuatro verificaciones originales de
geometría y la selección por `ValueKey('catalogo-Streaming')`. Las verificaciones
de alineación se cumplen, pero la prueba falla por las excepciones de layout de
`MasVendido` al desplazarse por Home.

Reproducción:

```powershell
flutter test --no-pub test/home_alignment_test.dart
```

No se añade una excepción para ignorar esos errores, ni se cambia la resolución,
la tolerancia o las dimensiones de las tarjetas para ocultarlos.

## Comprobaciones de la etapa 3

Se comparó Home inmediatamente anterior y posterior al refactor en los seis
anchos: 360, 390, 600, 768, 1024 y 1440 px. Coinciden las posiciones, dimensiones,
estilos, imágenes y disponibilidad de los callbacks de los elementos inspeccionados,
además de los errores de layout observados. El recorrido incluye la portada,
el chat abierto y cerrado, novedades, beneficios y la categoría Streaming.

Las referencias y los informes de esta comparación son artefactos locales en
`.dart_tool/stage3_audit/`, ignorados por Git. Las pruebas permanentes siguen
reportando los errores pendientes con normalidad.

La corrección previa del pie de `TarjetaProducto` y sus pruebas se mantienen.
El desbordamiento de 12 px de `CANVA PRO` ya no forma parte de los pendientes.

## Comprobaciones durante la migración del carrito

Se compararon la cabecera, `CarritoScreen` y `PagoScreen` antes y después de la
migración en 360, 390, 600, 768, 1024 y 1440 px. Coinciden los textos, estilos,
imágenes, posiciones, dimensiones y errores observados. Las referencias anteriores
se usan exclusivamente como fixtures de diagnóstico en `.dart_tool/carrito_audit/`;
no forman parte de la aplicación. La aplicación tiene un único carrito en Riverpod.

La comparación también reprodujo estos problemas anteriores de `CarritoScreen`,
con una línea de CANVA PRO de S/ 6.00 y una unidad:

| Resolución | Desbordamientos horizontales anteriores y posteriores |
| --- | --- |
| 360 × 800 | 70 px en la cabecera del carrito y otro de 2.8 px en su contenido |
| 390 × 844 | 40 px en la cabecera del carrito |

Al aumentar el total, el texto de la cabecera puede requerir más ancho y aumentar
ese desbordamiento. No se ha modificado el layout para resolverlo. La nueva prueba
funcional de navegación del carrito se ejecuta en 1024 × 900, donde no aparece;
las comprobaciones móviles de pago y contador se ejecutan en 390 × 844. La auditoría
de comparación conserva y registra los errores de ambas versiones en móvil.

El overflow de 6 px de `MasVendido` sigue provocando el fallo conocido de
`home_alignment_test.dart`. La adaptación de esa prueba a `ProviderScope` conserva
sus selectores y todas sus verificaciones geométricas; no ignora excepciones.

## Comprobaciones durante la migración del catálogo

Se comparó Home antes y después de sustituir la carga local por Riverpod en
360 × 800, 390 × 844, 600 × 960, 768 × 1024, 1024 × 768 y 1440 × 900.
Las 12 vistas inspeccionadas por resolución coinciden en posiciones, dimensiones,
textos, estilos, imágenes y disponibilidad de callbacks. El recorrido incluye
portada, soporte abierto y cerrado, novedades, beneficios y las siete secciones
de categorías y especiales. Son widget tests; no una validación en dispositivos
Android ni en un navegador real.

Los errores anteriores y posteriores también coinciden: 21 px en las promociones
a 600 px, 2 px a 768 px y 6 px en más vendidos a 1440 px. El diagnóstico compara
los errores de ambas versiones y conserva su informe en
`.dart_tool/catalogo_audit/report.json`, ignorado por Git. No se han modificado
las pruebas existentes ni su tratamiento de errores.

Validación de esta migración: `flutter analyze` sin incidencias; `flutter test`
con 72 pruebas aprobadas y el único fallo conocido de `home_alignment_test.dart`
por los dos desbordamientos de 6 px. Las 16 pruebas nuevas de datos, providers e
integración pasan, incluido el flujo de búsqueda, detalle, carrito, contador,
pago y confirmación con el catálogo demo. Las seis comparaciones de resoluciones
se ejecutan por separado como diagnóstico local.

## Comprobaciones durante la integración HTTP con Railway

Se conserva el catálogo local como origen predeterminado. El modo API requiere
`--dart-define=CATALOGO_ORIGEN=api`; no mezcla productos locales ni los usa como
fallback. Los 34 productos de la respuesta real coinciden con el mock en todos
sus atributos, precios y orden; se conservan los 11 productos sin disponibilidad.

La comparación entre Home anterior con mock y Home actual con una respuesta HTTP
de prueba coincide en 360 × 800, 390 × 844, 600 × 960, 768 × 1024, 1024 × 768 y
1440 × 900. Se comparan las mismas 12 vistas por resolución, incluyendo geometría,
estilos, imágenes, callbacks y errores. Persisten los 21 px de las promociones a
600 px, los 2 px a 768 px y los 6 px de más vendidos a 1440 px. Los diagnósticos
están en `.dart_tool/http_catalogo_audit/`, ignorado por Git. Las pruebas permanentes
conservan su tratamiento de errores y sus verificaciones originales.

La compilación Web release con `--base-href /WS_PROTOTIPO_WEB/` y modo API funciona
en Brave headless con perfil aislado y sin desactivar CORS ni seguridad. Se comprobó
la petición HTTPS real (HTTP 200, 34 productos y 11 no disponibles), el renderizado
con assets locales, el estado de error al bloquear la petición y la recuperación
mediante «Reintentar» con otra respuesta HTTP 200. No hubo excepciones JavaScript.
Las capturas y el informe se conservan localmente en el directorio del diagnóstico.

La única ampliación visual corresponde al estado de error: mensaje del fallo
y acción «Reintentar». El catálogo cargado mantiene los componentes existentes.

Validación: 68 pruebas nuevas aprobadas; suite completa con 140 aprobadas y el
único fallo conocido de `home_alignment_test.dart` por los dos overflows de 6 px.
`flutter analyze` y `git diff --check` sin errores. Se verifican la compra simulada,
el contador y la conservación de productos y cantidades al recargar el catálogo.

Se generó el APK de depuración con modo API y permiso de Internet. No había
dispositivos ni emuladores Android conectados, por lo que queda pendiente la
comprobación de ejecución y conexión HTTPS en un dispositivo Android real.
No se modificaron el backend, Railway ni los archivos de publicación de GitHub Pages.

## Comprobaciones durante la autenticación real

Se mantiene intacto `home_alignment_test.dart`, incluido su fallo por los dos
overflows preexistentes de 6 px. La comparación de Home con el archivo anterior
de Git coincide en las seis resoluciones habituales: geometría, estilos, imágenes,
callbacks y errores. Persisten las promociones de 21 px a 600 px y 2 px a 768 px
ya registradas en las etapas anteriores.

La comprobación ampliada del perfil detectó errores anteriores adicionales:

| Ancho | Resumen del perfil, antes y después |
| --- | --- |
| 360 px | 26 px a la derecha en el balance y 22 px abajo en un acceso rápido |
| 390, 600 y 768 px | Sin overflows en la vista inicial comprobada |
| 1024 y 1440 px | 13 px a la derecha en la pantalla completa |

Se contrastaron el resumen y la pantalla completa con sus archivos originales de
Git, usando los mismos datos y constraints. Las medidas y cantidades de errores
coinciden; no se modificó su layout. Informes locales:
`.dart_tool/auth_audit/perfil_report.json` y `perfil_screen_report.json`.
Los diagnósticos registran los errores de ambos lados; no sustituyen ni modifican
las verificaciones de las pruebas permanentes.

Login y registro, con validaciones visibles, y saldo y pago autenticados pasan
sus pruebas de layout a 360, 390, 600, 768, 1024 y 1440 px. Se conservan tamaños,
fuentes, colores, imágenes y navegación. Los textos distinguen los datos financieros
demo de la identidad real. El panel lateral de perfil utiliza el mismo color
sobre `Material`, evitando la advertencia de Flutter sobre ListTile oculto bajo
ColoredBox sin modificar medidas.

La Web compilada con el base-href de GitHub Pages funciona en Brave headless con
perfil aislado y seguridad normal: catálogo real de 34 productos, error/reintento,
CORS de `/me` y cero excepciones JavaScript. No se crearon cuentas ni se usaron
credenciales reales para estas comprobaciones. La prueba autenticada de extremo
a extremo con una cuenta real y la ejecución física Android quedan pendientes.

Validación final de autenticación: 55 pruebas nuevas aprobadas; 195 aprobadas en
la suite completa y únicamente el fallo conocido de `home_alignment_test.dart`.
El analizador no encuentra incidencias y `git diff --check` no detecta errores.
