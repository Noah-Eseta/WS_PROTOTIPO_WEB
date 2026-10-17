import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'logo_marca.dart';

const _fondoPie = Color(0xFF080C12);
const _bordePie = Color(0xFF132234);

/// Barra inferior: métodos de pago y datos de la empresa. Ocupa todo el ancho.
class PieTienda extends StatelessWidget {
  const PieTienda({super.key});

  static const metodos = [
    'Binance',
    'VISA',
    'Mastercard',
    'Yape',
    'Plin',
    'Google Pay',
    'Apple Pay',
  ];

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final margen = ancho < 600 ? 16.0 : 32.0;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _fondoPie,
        border: Border(top: BorderSide(color: _bordePie)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 28, horizontal: margen),
            child: _pagos(),
          ),
          const Divider(height: 1, color: _bordePie),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 28, horizontal: margen),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: _datos(ancho),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pagos() {
    return Column(
      children: [
        const Text(
          'MÉTODOS DE PAGO INTEGRADOS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'La disponibilidad final depende del país, moneda y método habilitado para tu cuenta.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textoSecundario, fontSize: 10),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (final m in metodos)
              Container(
                width: 96,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.superficie,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borde),
                ),
                child: Text(
                  m,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _datos(double ancho) {
    final columnas = <Widget>[
      _columna('POLÍTICAS', [
        'Términos y condiciones',
        'Política de privacidad',
        'Política de reembolsos',
      ]),
      _columna('EMPRESA', [
        'Sobre nosotros',
        'Trabajar con nosotros',
        'Tienda digital',
      ]),
      _columna('AYUDA', ['Preguntas frecuentes', 'Cómo funciona', 'Tutorial']),
      _contacto(),
    ];

    final marca = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        LogoMarca(tamano: 34),
        SizedBox(height: 10),
        Text(
          'WEIKANG DIGITAL S.A.C. · Perú',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8),
        Text(
          'Plataforma orientada a la comercialización y gestión de productos y servicios digitales.',
          style: TextStyle(color: AppColors.textoSecundario, fontSize: 11),
        ),
      ],
    );

    final legal = Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 8,
      runSpacing: 6,
      children: const [
        Text(
          '© 2026 WEIKANG SHOP · Todos los derechos reservados.',
          style: TextStyle(color: AppColors.textoSecundario, fontSize: 10),
        ),
        Text(
          'Información, disponibilidad y métodos sujetos a las condiciones vigentes de la plataforma.',
          style: TextStyle(color: AppColors.textoSecundario, fontSize: 10),
        ),
      ],
    );

    final Widget cuerpo;
    if (ancho >= 1000) {
      cuerpo = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: marca),
          const SizedBox(width: 24),
          for (final c in columnas) Expanded(flex: 2, child: c),
        ],
      );
    } else {
      cuerpo = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          marca,
          const SizedBox(height: 24),
          Wrap(
            spacing: 40,
            runSpacing: 24,
            children: [
              for (final c in columnas) SizedBox(width: 170, child: c),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        cuerpo,
        const SizedBox(height: 24),
        const Divider(height: 1, color: _bordePie),
        const SizedBox(height: 14),
        legal,
      ],
    );
  }

  static Widget _titulo(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      t,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
    ),
  );

  static Widget _columna(String titulo, List<String> enlaces) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo(titulo),
        for (final e in enlaces)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              e,
              style: const TextStyle(
                color: AppColors.textoSecundario,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  static Widget _contacto() {
    Widget red(IconData i) => Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borde),
      ),
      child: Icon(i, size: 14),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('CONTACTO OFICIAL'),
        const Text(
          'administracion@shopweikang.es',
          style: TextStyle(color: AppColors.textoSecundario, fontSize: 11),
        ),
        const SizedBox(height: 4),
        const Text(
          'WhatsApp: +51 939 932 046',
          style: TextStyle(color: AppColors.textoSecundario, fontSize: 11),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            red(Icons.camera_alt_outlined),
            red(Icons.music_note),
            red(Icons.chat_bubble_outline),
            red(Icons.facebook),
          ],
        ),
      ],
    );
  }
}
