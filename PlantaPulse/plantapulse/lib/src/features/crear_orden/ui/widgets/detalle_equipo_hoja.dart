// lib/src/features/crear_orden/ui/widgets/detalle_equipo_hoja.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../../domain/usecases/crear_orden_casos.dart';
import 'alta_equipo_hoja.dart';

/// Ficha de un equipo con sus acciones: editar y dar de baja.
///
/// "Dar de baja" es la eliminación de un equipo: no se borra (las órdenes
/// viejas lo referencian y su historial de mantenimiento se conserva),
/// solo deja de aparecer en el asistente.
class DetalleEquipoHoja extends StatefulWidget {
  final Equipo equipo;
  final ValueChanged<Equipo> alEditar;
  final ValueChanged<String> alDarDeBaja;

  const DetalleEquipoHoja({
    super.key,
    required this.equipo,
    required this.alEditar,
    required this.alDarDeBaja,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required Equipo equipo,
    required ValueChanged<Equipo> alEditar,
    required ValueChanged<String> alDarDeBaja,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.fondo,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => DetalleEquipoHoja(
            equipo: equipo, alEditar: alEditar, alDarDeBaja: alDarDeBaja),
      );

  @override
  State<DetalleEquipoHoja> createState() => _DetalleEquipoHojaState();
}

class _DetalleEquipoHojaState extends State<DetalleEquipoHoja> {
  late Equipo _equipo = widget.equipo;
  bool _ocupado = false;

  Future<void> _editar() async {
    final editado = await AltaEquipoHoja.editar(context, _equipo);
    if (editado == null || !mounted) return;
    setState(() => _equipo = editado);
    widget.alEditar(editado);
  }

  Future<void> _darDeBaja() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Dar de baja ${_equipo.nombre}?'),
        content: const Text(
          'Dejará de aparecer al crear órdenes. Su historial no se borra: '
          'las órdenes que ya lo usan lo siguen mostrando.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.rojo),
              child: const Text('Dar de baja')),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    final baja = context.read<DarDeBajaEquipo>();
    final navegador = Navigator.of(context);
    final avisos = ScaffoldMessenger.of(context);
    setState(() => _ocupado = true);
    try {
      await baja.ejecutar(_equipo.id);
      widget.alDarDeBaja(_equipo.id);
      navegador.pop();
      // Fiable: el repositorio comprueba que de verdad quedó de baja
      avisos.showSnackBar(SnackBar(
        backgroundColor: AppColors.verde,
        content: Text('${_equipo.nombre} dado de baja'),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _ocupado = false);
      avisos.showSnackBar(SnackBar(
        backgroundColor: AppColors.rojo,
        content: Text(FalloApp.mensajeDe(e)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = _equipo;
    final medidas = MediaQuery.of(context);
    String o(String v) => v.trim().isEmpty ? '—' : v;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + medidas.padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.borde,
                borderRadius: BorderRadius.circular(2)))),
          Row(
            children: [
              Expanded(child: Text(e.nombre, style: AppText.titulo)),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textoGris),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          PillEstado(texto: e.estado.etiqueta,
              color: e.estado == EstadoEquipo.operativo
                  ? AppColors.verde : AppColors.ambar),
          const SizedBox(height: 16),
          TarjetaBlanca(
            child: Column(
              children: [
                MetaRow(icono: Icons.place_outlined, texto: 'ZONA',
                    valor: o(e.zonaNombre)),
                const SizedBox(height: 12),
                MetaRow(icono: Icons.qr_code_2, texto: 'SERIAL',
                    valor: o(e.serial)),
                const SizedBox(height: 12),
                MetaRow(icono: Icons.precision_manufacturing_outlined,
                    texto: 'MODELO', valor: o(e.modelo)),
                const SizedBox(height: 12),
                MetaRow(icono: Icons.category_outlined, texto: 'TIPO',
                    valor: tiposDeEquipo[e.tipo] ?? o(e.tipo)),
                const SizedBox(height: 12),
                MetaRow(icono: Icons.build_circle_outlined,
                    texto: 'ÚLTIMO MANTENIMIENTO',
                    valor: e.ultimoMantenimiento == null
                        ? 'Sin registro'
                        : fechaCorta(e.ultimoMantenimiento!),
                    atenuado: e.ultimoMantenimiento == null),
              ],
            ),
          ),
          const SizedBox(height: 20),
          BotonAncho(
            texto: 'EDITAR EQUIPO',
            icono: Icons.edit_outlined,
            onTap: _ocupado ? null : _editar,
          ),
          const SizedBox(height: 10),
          BotonAncho(
            texto: _ocupado ? 'DANDO DE BAJA...' : 'DAR DE BAJA',
            icono: Icons.delete_outline,
            estilo: EstiloBoton.peligro,
            onTap: _ocupado ? null : _darDeBaja,
          ),
        ],
      ),
    );
  }
}
