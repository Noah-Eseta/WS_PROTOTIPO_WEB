import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formato.dart';
import '../services/pedido_service.dart';
import 'perfil_componentes.dart';

class PerfilRewards extends StatelessWidget {
  final List<PedidoDemo> pedidos;
  final int puntos;

  const PerfilRewards({super.key, required this.pedidos, required this.puntos});

  static const _niveles = [
    _Nivel(
      nombre: 'NOVA',
      meta: 300,
      beneficio: '5 - 15 PEN',
      imagen: 'assets/images/Banners/reward_nova.png',
      color: Color(0xFF35C4FF),
    ),
    _Nivel(
      nombre: 'ADVANCE',
      meta: 700,
      beneficio: '12 - 30 PEN',
      imagen: 'assets/images/Banners/reward_advance.png',
      color: Color(0xFFC57AFF),
    ),
    _Nivel(
      nombre: 'PRESTIGE',
      meta: 1500,
      beneficio: '20 - 60 PEN',
      imagen: 'assets/images/Banners/reward_prestige.png',
      color: Color(0xFFFF5B7D),
    ),
    _Nivel(
      nombre: 'PRIME',
      meta: 3500,
      beneficio: '40 - 150 PEN',
      imagen: 'assets/images/Banners/reward_prime.png',
      color: Color(0xFFFFD34F),
    ),
  ];

  double _consumo(DateTime mes) => pedidos
      .where(
        (pedido) =>
            pedido.fecha.year == mes.year && pedido.fecha.month == mes.month,
      )
      .fold<double>(0, (total, pedido) => total + pedido.total);

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final consumoMes = _consumo(ahora);
    final meses = List.generate(
      3,
      (indice) => DateTime(ahora.year, ahora.month - 2 + indice),
    );
    final consumos = meses.map(_consumo).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TU ACTIVIDAD TIENE RECOMPENSA',
                style: TextStyle(
                  color: AppColors.acento,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  text: 'WEIKANG ',
                  children: const [
                    TextSpan(
                      text: 'REWARDS',
                      style: TextStyle(color: Color(0xFF35C4FF)),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontSize: constraints.maxWidth < 520 ? 33 : 42,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: const Text(
                  'Puntos y beneficios de demostración de esta sesión; no son recompensas reales de tu cuenta.',
                  style: TextStyle(
                    color: PerfilEstilo.textoSuave,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PerfilEtiqueta(
                    texto: '${formatoPrecio(consumoMes)} en compras este mes',
                  ),
                  PerfilEtiqueta(
                    texto: '$puntos puntos acumulados',
                    color: const Color(0xFFC57AFF),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final columnas = constraints.maxWidth >= 1080
                ? 4
                : constraints.maxWidth >= 630
                ? 2
                : 1;
            final ancho =
                (constraints.maxWidth - 14 * (columnas - 1)) / columnas;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final nivel in _niveles)
                  SizedBox(
                    width: ancho,
                    child: _TarjetaNivel(nivel: nivel, consumoMes: consumoMes),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _Legendary(meses: meses, consumos: consumos),
        const SizedBox(height: 18),
        PerfilPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'BENEFICIOS RECIBIDOS',
                style: TextStyle(
                  color: AppColors.acento,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: PerfilEstilo.borde),
              const PerfilVacio(
                icono: Icons.card_giftcard_outlined,
                titulo: 'Tus beneficios aparecerán aquí',
                descripcion: 'Los canjes y recompensas de estos niveles estarán disponibles próximamente.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Nivel {
  final String nombre;
  final double meta;
  final String beneficio;
  final String imagen;
  final Color color;

  const _Nivel({
    required this.nombre,
    required this.meta,
    required this.beneficio,
    required this.imagen,
    required this.color,
  });
}

class _TarjetaNivel extends StatelessWidget {
  final _Nivel nivel;
  final double consumoMes;

  const _TarjetaNivel({required this.nivel, required this.consumoMes});

  @override
  Widget build(BuildContext context) {
    final alcanzado = consumoMes >= nivel.meta;
    return Container(
      height: 350,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: nivel.color, width: 1.2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [nivel.color.withValues(alpha: .12), const Color(0xFF0D1422)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nivel.nombre,
                      style: TextStyle(
                        color: nivel.color,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'S/ ${nivel.meta.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'de consumo mensual',
                      style: TextStyle(
                        fontSize: 11,
                        color: PerfilEstilo.textoSuave,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Insignia(
                    texto: alcanzado
                        ? 'Alcanzado'
                        : 'Faltan ${formatoPrecio(nivel.meta - consumoMes)}',
                    color: alcanzado ? const Color(0xFF51D9B1) : nivel.color,
                    ancho: 112,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: nivel.color),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.card_giftcard_outlined,
                      size: 20,
                      color: nivel.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Expanded(
            child: Image.asset(
              nivel.imagen,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
          Center(
            child: _Insignia(
              texto: nivel.beneficio,
              color: nivel.color,
              ancho: 185,
              icono: alcanzado ? Icons.check_rounded : Icons.lock_outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legendary extends StatelessWidget {
  final List<DateTime> meses;
  final List<double> consumos;

  const _Legendary({required this.meses, required this.consumos});

  static const _meta = 10000.0;
  static const _azul = Color(0xFF35C4FF);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final horizontal = constraints.maxWidth >= 860;
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _azul),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF10334E), Color(0xFF091424)],
          ),
        ),
        child: horizontal
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 360, child: _intro()),
                  const SizedBox(
                    width: 1,
                    height: 330,
                    child: ColoredBox(color: PerfilEstilo.borde),
                  ),
                  Expanded(child: _progreso()),
                ],
              )
            : Column(
                children: [
                  _intro(),
                  const Divider(height: 1, color: PerfilEstilo.borde),
                  _progreso(),
                ],
              ),
      );
    },
  );

  Widget _intro() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LEGENDARY',
          style: TextStyle(
            color: _azul,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'S/ 10,000',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        const Text(
          'de consumo mensual durante 3 meses',
          style: TextStyle(color: PerfilEstilo.textoSuave, fontSize: 11),
        ),
        Center(
          child: Image.asset(
            'assets/images/Banners/reward_legendary.png',
            width: 248,
            height: 185,
            fit: BoxFit.contain,
          ),
        ),
        const Center(
          child: _Insignia(
            texto: '100 - 500 PEN',
            color: _azul,
            ancho: 180,
            icono: Icons.lock_outline,
          ),
        ),
      ],
    ),
  );

  Widget _progreso() {
    final completados = consumos.where((consumo) => consumo >= _meta).length;
    final acumulado = consumos.fold<double>(
      0,
      (suma, consumo) => suma + consumo,
    );
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'TU PROGRESO A LEGENDARY',
                  style: TextStyle(
                    color: _azul,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Text(
                '$completados de 3',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var indice = 0; indice < 3; indice++) ...[
                Expanded(
                  child: LinearProgressIndicator(
                    value: (consumos[indice] / _meta).clamp(0.0, 1.0),
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(8),
                    backgroundColor: const Color(0xFF0A1D32),
                    color: _azul,
                  ),
                ),
                if (indice < 2) const SizedBox(width: 4),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${formatoPrecio(acumulado)} acumulados en los últimos 3 meses',
            style: const TextStyle(
              color: PerfilEstilo.textoSuave,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final tarjetas = [
                _DetalleLegendary(
                  icono: Icons.calendar_month_outlined,
                  titulo: 'Últimos 3 meses',
                  detalle:
                      '${_mes(meses[0])}, ${_mes(meses[1])} y ${_mes(meses[2])}',
                ),
                _DetalleLegendary(
                  icono: Icons.home_outlined,
                  titulo: 'S/ 10,000 cada mes',
                  detalle: 'Objetivo mensual para LEGENDARY',
                ),
              ];
              return constraints.maxWidth >= 600
                  ? Row(
                      children: [
                        Expanded(child: tarjetas[0]),
                        const SizedBox(width: 10),
                        Expanded(child: tarjetas[1]),
                      ],
                    )
                  : Column(
                      children: [
                        tarjetas[0],
                        const SizedBox(height: 10),
                        tarjetas[1],
                      ],
                    );
            },
          ),
          const SizedBox(height: 10),
          const _DetalleLegendary(
            icono: Icons.card_giftcard_outlined,
            titulo: '¿Cómo funciona LEGENDARY?',
            detalle: 'Completa el objetivo mensual en cada uno de los tres meses mostrados para alcanzar este nivel.',
          ),
        ],
      ),
    );
  }

  String _mes(DateTime fecha) => const [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ][fecha.month - 1];
}

class _DetalleLegendary extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;

  const _DetalleLegendary({
    required this.icono,
    required this.titulo,
    required this.detalle,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0x80071422),
      border: Border.all(color: PerfilEstilo.borde),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        PerfilIcono(icono: icono, tamano: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detalle,
                style: const TextStyle(
                  color: PerfilEstilo.textoSuave,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Insignia extends StatelessWidget {
  final String texto;
  final Color color;
  final double? ancho;
  final IconData? icono;

  const _Insignia({
    required this.texto,
    required this.color,
    this.ancho,
    this.icono,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: ancho,
    constraints: const BoxConstraints(minHeight: 28),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      border: Border.all(color: color.withValues(alpha: .6)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, color: color, size: 13),
            const SizedBox(width: 5),
          ],
          Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}
