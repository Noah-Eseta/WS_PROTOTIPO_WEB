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
