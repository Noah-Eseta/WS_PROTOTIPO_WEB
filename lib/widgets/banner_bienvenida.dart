import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class BannerBienvenida extends StatefulWidget {
  final bool compacto;
  final VoidCallback onExplorar;
  final VoidCallback onBeneficios;
  final VoidCallback onColaboradores;

  const BannerBienvenida({
    super.key,
    required this.compacto,
    required this.onExplorar,
    required this.onBeneficios,
    required this.onColaboradores,
  });

  @override
  State<BannerBienvenida> createState() => _BannerBienvenidaState();
}

class _BannerBienvenidaState extends State<BannerBienvenida> {
  static const _totalBanners = 3;
  final _paginas = PageController();
  Timer? _temporizador;
  int _actual = 0;

  @override
  void initState() {
    super.initState();
    _programarAvance();
  }

  void _programarAvance() {
    _temporizador?.cancel();
    _temporizador = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent != true ||
          !_paginas.hasClients ||
          _paginas.position.isScrollingNotifier.value) {
        _programarAvance();
        return;
      }
      _paginas.animateToPage(
        (_actual + 1) % _totalBanners,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  void _cambiarPagina(int pagina) {
    _programarAvance();
    _paginas.animateToPage(
      pagina,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _paginas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final estrecho = widget.compacto || constraints.maxWidth < 600;
        return Container(
          height: estrecho ? 370 : 340,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.acento.withValues(alpha: 0.48)),
          ),
          child: Stack(
            children: [
              PageView(
                controller: _paginas,
                onPageChanged: (pagina) {
                  setState(() => _actual = pagina);
                  _programarAvance();
                },
                children: [
                  _DiapositivaBanner(
                    imagen: 'assets/images/Banners/bnn1.webp',
                    etiqueta: 'BIENVENIDO A WEIKANG SHOP',
                    iconoEtiqueta: Icons.auto_awesome,
                    titulo: 'Todo digital en',
                    tituloAcento: 'un solo lugar',
                    descripcion: 'Compra rápido, recibe de forma segura y gestiona todo con la experiencia digital de WEIKANG SHOP.',
                    boton: 'Explorar tienda',
                    iconoBoton: Icons.arrow_forward,
                    onBoton: widget.onExplorar,
                    ventajas: const [
                      (Icons.bolt, 'Entrega digital'),
                      (Icons.verified_user_outlined, 'Pagos seguros'),
                      (Icons.headset_mic_outlined, 'Soporte al cliente'),
                    ],
                    estrecho: estrecho,
                  ),
                  _DiapositivaBanner(
                    imagen: 'assets/images/Banners/rewards.png',
                    etiqueta: 'WEIKANG REWARDS',
                    iconoEtiqueta: Icons.workspace_premium,
                    titulo: 'Convierte tus compras',
                    tituloAcento: 'en recompensas',
                    descripcion: 'Acumula puntos, desbloquea beneficios exclusivos y canjéalos por saldo dentro de WEIKANG SHOP.',
                    boton: 'Ver beneficios',
                    iconoBoton: Icons.arrow_forward,
                    onBoton: widget.onBeneficios,
                    ventajas: const [
                      (Icons.monetization_on_outlined, 'Acumula puntos'),
                      (Icons.card_giftcard_outlined, 'Canjea por saldo'),
                      (Icons.workspace_premium_outlined, 'Ofertas exclusivas'),
                    ],
                    estrecho: estrecho,
                  ),
                  _DiapositivaBanner(
                    imagen: 'assets/images/Banners/colaboradores.png',
                    etiqueta: 'PROGRAMA DE COLABORADORES',
                    iconoEtiqueta: Icons.groups_outlined,
                    titulo: 'Postula y',
                    tituloAcento: 'crece con WEIKANG',
                    descripcion: 'Obtén tu código único de colaborador, compártelo con tu comunidad y genera comisiones por las compras realizadas con tu código.',
                    boton: 'Postular ahora',
                    iconoBoton: Icons.send_outlined,
                    onBoton: widget.onColaboradores,
                    botonSecundario: 'Ver beneficios',
                    onBotonSecundario: widget.onColaboradores,
                    ventajas: const [
                      (Icons.key_outlined, 'Código único'),
                      (Icons.monetization_on_outlined, 'Comisiones por venta'),
                      (Icons.headset_mic_outlined, 'Soporte dedicado'),
                    ],
                    estrecho: estrecho,
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 7,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _totalBanners; i++)
                      Semantics(
                        button: true,
                        label: 'Mostrar banner ${i + 1} de $_totalBanners',
                        child: InkWell(
                          onTap: () => _cambiarPagina(i),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: _actual == i ? 19 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _actual == i
                                    ? AppColors.acento
                                    : Colors.white.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DiapositivaBanner extends StatelessWidget {
  final String imagen;
  final String etiqueta;
  final IconData iconoEtiqueta;
  final String titulo;
  final String tituloAcento;
  final String descripcion;
  final String boton;
  final IconData iconoBoton;
  final VoidCallback onBoton;
  final String? botonSecundario;
  final VoidCallback? onBotonSecundario;
  final List<(IconData, String)> ventajas;
  final bool estrecho;

  const _DiapositivaBanner({
    required this.imagen,
    required this.etiqueta,
    required this.iconoEtiqueta,
    required this.titulo,
    required this.tituloAcento,
    required this.descripcion,
    required this.boton,
    required this.iconoBoton,
    required this.onBoton,
    this.botonSecundario,
    this.onBotonSecundario,
    required this.ventajas,
    required this.estrecho,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(imagen),
              fit: BoxFit.cover,
              alignment: estrecho ? Alignment.centerRight : Alignment.center,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: estrecho
                  ? const [Color(0xE6061225), Color(0x99061225)]
                  : const [
                      Color(0xF0061225),
                      Color(0xB3061225),
                      Color(0x00061225),
                    ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            estrecho ? 20 : 28,
            estrecho ? 20 : 24,
            estrecho ? 20 : 28,
            26,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _etiqueta(),
              SizedBox(height: estrecho ? 14 : 10),
              SizedBox(
                width: estrecho ? double.infinity : 500,
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: estrecho ? 29 : 36,
                      fontWeight: FontWeight.w900,
                      height: 1.03,
                      letterSpacing: -1,
                    ),
                    children: [
                      TextSpan(text: '$titulo\n'),
                      TextSpan(
                        text: tituloAcento,
                        style: const TextStyle(color: AppColors.acento),
                      ),
                    ],
                  ),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: estrecho ? double.infinity : 430,
                child: Text(
                  descripcion,
                  maxLines: estrecho ? 4 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD1DEEF),
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ),
              SizedBox(height: estrecho ? 14 : 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onBoton,
                    icon: Icon(iconoBoton, size: 15),
                    label: Text(boton),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
                  if (botonSecundario != null)
                    OutlinedButton(
                      onPressed: onBotonSecundario,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF4776A5)),
                      ),
                      child: Text(botonSecundario!),
                    ),
                ],
              ),
              const Spacer(),
              if (!estrecho)
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    for (final (icono, texto) in ventajas)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icono, size: 13, color: AppColors.acento),
                          const SizedBox(width: 4),
                          Text(
                            texto,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _etiqueta() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xCC052742),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.acento.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconoEtiqueta, color: const Color(0xFF8CD1FF), size: 13),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              etiqueta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF8CD1FF),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
