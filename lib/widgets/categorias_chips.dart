import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/categoria.dart';

class CategoriasChips extends StatefulWidget {
  final double margen;
  final int seleccionada;
  final ValueChanged<int> onSeleccion;

  const CategoriasChips({
    super.key,
    required this.margen,
    required this.seleccionada,
    required this.onSeleccion,
  });

  @override
  State<CategoriasChips> createState() => _CategoriasChipsState();
}

class _CategoriasChipsState extends State<CategoriasChips> {
  final _claves = List.generate(Categoria.lista.length, (_) => GlobalKey());

  double get margen => widget.margen;
  int get seleccionada => widget.seleccionada;
  ValueChanged<int> get onSeleccion => widget.onSeleccion;

  @override
  void initState() {
    super.initState();
    _centrar();
  }

  @override
  void didUpdateWidget(CategoriasChips anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.seleccionada != seleccionada) _centrar();
  }

  void _centrar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contexto = _claves[seleccionada].currentContext;
      if (!mounted || contexto == null) return;
      Scrollable.ensureVisible(
        contexto,
        alignment: 0.5,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: Color(0xFF07111C),
        border: Border(bottom: BorderSide(color: Color(0xFF132234))),
      ),
      child: Row(
        children: [
          Expanded(
            // Se usa Row (no ListView) para que todos los chips existan y
            // se pueda centrar cualquiera.
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: margen, vertical: 4),
              child: Row(
                children: [
                  for (var i = 0; i < Categoria.lista.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    _chip(i),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(int i) {
    final activa = i == seleccionada;
    final categoria = Categoria.lista[i];
    return KeyedSubtree(
      key: _claves[i],
      child: TextButton.icon(
        onPressed: () => onSeleccion(i),
        icon: Icon(categoria.icono, size: 14),
        label: Text(categoria.nombre, style: const TextStyle(fontSize: 15)),
        style: TextButton.styleFrom(
          foregroundColor: activa ? Colors.white : AppColors.textoSecundario,
          backgroundColor: activa
              ? const Color(0xFF0879F9)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          minimumSize: const Size(0, 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
