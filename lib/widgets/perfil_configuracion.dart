import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formato.dart';
import '../services/pedido_service.dart';
import '../services/saldo_service.dart';
import 'perfil_componentes.dart';

const _violetaCuenta = Color(0xFFA986FF);

class PerfilCuenta extends StatelessWidget {
  final String nombre;
  final String correo;
  final GlobalKey<FormState> formKey;
  final TextEditingController nombreController;
  final TextEditingController correoController;
  final TextEditingController telefonoController;
  final VoidCallback onGuardar;

  const PerfilCuenta({
    super.key,
    required this.nombre,
    required this.correo,
    required this.formKey,
    required this.nombreController,
    required this.correoController,
    required this.telefonoController,
    required this.onGuardar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PerfilEncabezado(
          titulo: 'Mi cuenta',
          descripcion: 'Tu espacio personal dentro de WEIKANG SHOP.',
          icono: Icons.manage_accounts_outlined,
          etiqueta: 'CONFIGURACIÓN',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final identidad = _identidad();
            final formulario = _formulario();
            if (constraints.maxWidth < 850) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [identidad, const SizedBox(height: 18), formulario],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 280, child: identidad),
                const SizedBox(width: 20),
                Expanded(child: formulario),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _identidad() {
    final inicial = nombre.trim().isEmpty
        ? 'P'
        : nombre.trim().characters.first.toUpperCase();
    return PerfilPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: PerfilEtiqueta(texto: 'TU PERFIL', color: _violetaCuenta),
          ),
          const SizedBox(height: 28),
          Center(
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF164A7A), Color(0xFF30205D)],
                ),
                border: Border.all(color: _violetaCuenta.withValues(alpha: .5)),
                boxShadow: [
                  BoxShadow(
                    color: _violetaCuenta.withValues(alpha: .13),
                    blurRadius: 32,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                inicial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            correo,
            textAlign: TextAlign.center,
            style: const TextStyle(color: PerfilEstilo.textoSuave, height: 1.5),
          ),
          const SizedBox(height: 18),
          const Center(child: PerfilEtiqueta(texto: 'MIEMBRO WEIKANG')),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(color: PerfilEstilo.borde, height: 1),
          ),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: _violetaCuenta,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mantén tus datos al día para identificar tus compras y tu cuenta.',
                  style: TextStyle(color: PerfilEstilo.textoSuave, height: 1.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formulario() {
    return PerfilPanel(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                PerfilIcono(icono: Icons.edit_outlined, color: _violetaCuenta),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información personal',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Así te conocemos en la tienda.',
                        style: TextStyle(color: PerfilEstilo.textoSuave),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _campo(
              titulo: 'Nombre',
              child: TextFormField(
                controller: nombreController,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                decoration: _entrada('Tu nombre', Icons.person_outline),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ingresa tu nombre'
                    : null,
              ),
            ),
            const SizedBox(height: 22),
            _campo(
              titulo: 'Correo electrónico',
              child: TextFormField(
                controller: correoController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: _entrada(
                  'nombre@correo.com',
                  Icons.alternate_email,
                ),
                validator: (value) =>
                    value == null ||
                        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(value.trim())
                    ? 'Ingresa un correo válido'
                    : null,
              ),
            ),
            const SizedBox(height: 22),
            _campo(
              titulo: 'Teléfono',
              opcional: true,
              child: TextFormField(
                controller: telefonoController,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                textInputAction: TextInputAction.done,
                decoration: _entrada(
                  'Tu número de contacto',
                  Icons.phone_outlined,
                ),
                onFieldSubmitted: (_) => onGuardar(),
              ),
            ),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _violetaCuenta.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _violetaCuenta.withValues(alpha: .18),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: _violetaCuenta),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'El acceso al prototipo sigue usando la cuenta de prueba original.',
                      style: TextStyle(
                        color: PerfilEstilo.textoSuave,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onGuardar,
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text('Guardar cambios'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo({
    required String titulo,
    required Widget child,
    bool opcional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (opcional)
              const Text(
                'Opcional',
                style: TextStyle(color: PerfilEstilo.textoSuave, fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  InputDecoration _entrada(String hint, IconData icono) {
    return InputDecoration(
      hintText: hint,
      fillColor: const Color(0xFF0A1728),
      prefixIcon: Icon(icono, size: 20, color: PerfilEstilo.textoSuave),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _violetaCuenta),
      ),
    );
  }
}

enum _TipoAviso { todos, compra, recarga }

class PerfilNotificaciones extends StatefulWidget {
  final List<PedidoDemo> pedidos;
  final List<RecargaDemo> recargas;
  final VoidCallback onCompras;
  final VoidCallback onSaldo;
  final VoidCallback onTienda;

  const PerfilNotificaciones({
    super.key,
    required this.pedidos,
    required this.recargas,
    required this.onCompras,
    required this.onSaldo,
    required this.onTienda,
  });

  @override
  State<PerfilNotificaciones> createState() => _PerfilNotificacionesState();
}

class _PerfilNotificacionesState extends State<PerfilNotificaciones> {
  _TipoAviso _filtro = _TipoAviso.todos;

  List<_AvisoPerfil> get _avisos => [
    for (final pedido in widget.pedidos)
      _AvisoPerfil(
        tipo: _TipoAviso.compra,
        fecha: pedido.fecha,
        titulo: '¡Gracias por tu pedido!',
        descripcion:
            'Tu pedido #${pedido.numero} por ${formatoPrecio(pedido.total)} ya está registrado. Revisa los detalles en Compras.',
      ),
    for (final recarga in widget.recargas)
      _AvisoPerfil(
        tipo: _TipoAviso.recarga,
        fecha: recarga.fecha,
        titulo: 'Saldo agregado a tu billetera',
        descripcion:
            'Agregaste ${formatoPrecio(recarga.centimos / 100)} con ${recarga.metodoPago}. Consulta tu saldo y tus recargas.',
      ),
  ]..sort((a, b) => b.fecha.compareTo(a.fecha));

  @override
  Widget build(BuildContext context) {
    final avisos = _avisos;
    final visibles = avisos
        .where((aviso) => _filtro == _TipoAviso.todos || aviso.tipo == _filtro)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PerfilEncabezado(
          titulo: 'Notificaciones',
          descripcion: 'Sigue la actividad de tus compras y tu billetera.',
          icono: Icons.notifications_none_rounded,
          etiqueta: 'CONFIGURACIÓN',
        ),
        PerfilPanel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PerfilIcono(
                icono: Icons.notifications_active_outlined,
                tamano: 54,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tu actividad, en un solo lugar',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cada compra y recarga aparece aquí para que puedas encontrarla fácilmente.',
                      style: TextStyle(
                        color: PerfilEstilo.textoSuave,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 14),
                    PerfilEtiqueta(
                      texto:
                          '${avisos.length} ${avisos.length == 1 ? 'AVISO' : 'AVISOS'}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _chip(_TipoAviso.todos, 'Todos', avisos.length, Icons.apps_rounded),
            _chip(
              _TipoAviso.compra,
              'Compras',
              widget.pedidos.length,
              Icons.shopping_bag_outlined,
            ),
            _chip(
              _TipoAviso.recarga,
              'Billetera',
              widget.recargas.length,
              Icons.account_balance_wallet_outlined,
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (visibles.isEmpty)
          PerfilPanel(
            child: PerfilVacio(
              icono: Icons.notifications_none_rounded,
              titulo: _filtro == _TipoAviso.todos
                  ? 'Todo tranquilo por aquí'
                  : 'Sin avisos en esta sección',
              descripcion: _filtro == _TipoAviso.recarga
                  ? 'Cuando agregues saldo, verás aquí el aviso de tu recarga.'
                  : 'Tus próximas compras aparecerán aquí. Mientras tanto, descubre lo que tenemos para ti.',
              accion: FilledButton.icon(
                onPressed: _filtro == _TipoAviso.recarga
                    ? widget.onSaldo
                    : widget.onTienda,
                icon: Icon(
                  _filtro == _TipoAviso.recarga
                      ? Icons.account_balance_wallet_outlined
                      : Icons.shopping_cart_outlined,
                  size: 18,
                ),
                label: Text(
                  _filtro == _TipoAviso.recarga
                      ? 'Ver mi billetera'
                      : 'Explorar la tienda',
                ),
              ),
            ),
          )
        else ...[
          for (var i = 0; i < visibles.length; i++) ...[
            _tarjeta(visibles[i]),
            if (i != visibles.length - 1) const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  Widget _chip(_TipoAviso tipo, String texto, int cantidad, IconData icono) {
    final seleccionado = tipo == _filtro;
    return FilterChip(
      selected: seleccionado,
      showCheckmark: false,
      avatar: Icon(
        icono,
        size: 17,
        color: seleccionado ? AppColors.acento : PerfilEstilo.textoSuave,
      ),
      label: Text('$texto · $cantidad'),
      selectedColor: const Color(0xFF102F50),
      backgroundColor: const Color(0xFF0C192A),
      labelStyle: TextStyle(
        color: seleccionado ? Colors.white : PerfilEstilo.textoSuave,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: seleccionado ? AppColors.acento : PerfilEstilo.borde,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      onSelected: (_) => setState(() => _filtro = tipo),
    );
  }

  Widget _tarjeta(_AvisoPerfil aviso) {
    final compra = aviso.tipo == _TipoAviso.compra;
    final color = compra ? AppColors.acento : const Color(0xFF4CDAC2);
    return PerfilPanel(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PerfilIcono(
            icono: compra
                ? Icons.shopping_bag_outlined
                : Icons.account_balance_wallet_outlined,
            color: color,
            tamano: 44,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PerfilEtiqueta(
                      texto: compra ? 'COMPRA' : 'BILLETERA',
                      color: color,
                    ),
                    Text(
                      _fechaHora(aviso.fecha),
                      style: const TextStyle(
                        fontSize: 12,
                        color: PerfilEstilo.textoSuave,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  aviso.titulo,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  aviso.descripcion,
                  style: const TextStyle(
                    color: PerfilEstilo.textoSuave,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: compra ? widget.onCompras : widget.onSaldo,
                  label: Text(compra ? 'Ver mis compras' : 'Ver mi saldo'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fechaHora(DateTime fecha) {
    String dos(int numero) => numero.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} · ${dos(fecha.hour)}:${dos(fecha.minute)}';
  }
}

class _AvisoPerfil {
  final _TipoAviso tipo;
  final DateTime fecha;
  final String titulo;
  final String descripcion;

  const _AvisoPerfil({
    required this.tipo,
    required this.fecha,
    required this.titulo,
    required this.descripcion,
  });
}
