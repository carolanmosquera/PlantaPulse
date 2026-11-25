import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../bloc/ordenes_bloc.dart';

enum _FiltroResumen { pendientes, enProgreso, completadas, criticas }

class ResumenTurnoScreen extends StatefulWidget {
  const ResumenTurnoScreen({super.key});

  @override
  State<ResumenTurnoScreen> createState() => _ResumenTurnoScreenState();
}

class _ResumenTurnoScreenState extends State<ResumenTurnoScreen> {
  _FiltroResumen? _filtro;

  @override
  void initState() {
    super.initState();
    final plantaId =
        context.read<SesionBloc>().state.usuario?.plantaId ?? '';
    context.read<OrdenesBloc>().add(OrdenesSuscritas(plantaId));
  }

  List<Orden> _filtrar(List<Orden> ordenes) {
    final filtro = _filtro;
    if (filtro == null) return ordenes;

    final estado = switch (filtro) {
      _FiltroResumen.pendientes => EstadoOrden.pendiente,
      _FiltroResumen.enProgreso => EstadoOrden.enProgreso,
      _FiltroResumen.completadas => EstadoOrden.completada,
      _FiltroResumen.criticas => EstadoOrden.critica,
    };
    return ordenes.where((orden) => orden.estado == estado).toList();
  }

  List<Orden> _porVencer(List<Orden> ordenes) {
    final limite = DateTime.now().add(const Duration(hours: 24));
    final proximas = ordenes
        .where((orden) =>
            orden.estado.estaAbierta &&
            !orden.fechaLimite.isAfter(limite))
        .toList()
      ..sort((a, b) => a.fechaLimite.compareTo(b.fechaLimite));
    return proximas;
  }

  int _contar(List<Orden> ordenes, EstadoOrden estado) =>
      ordenes.where((orden) => orden.estado == estado).length;

  void _seleccionar(_FiltroResumen filtro) {
    setState(() => _filtro = _filtro == filtro ? null : filtro);
  }

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: 'Resumen de Planta',
      mostrarAtras: true,
      tabActiva: 0,
      cuerpo: BlocBuilder<OrdenesBloc, OrdenesState>(
        builder: (context, state) {
          final ordenes = state.ordenes;
          final visibles = _filtrar(ordenes);
          final porVencer = _porVencer(ordenes);

          if (state.status == EstadoOrdenes.cargando && ordenes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 12),
              Text(
                'Estado general de la planta',
                style: AppText.titulo.segunTema(context),
              ),
              const SizedBox(height: 4),
              Text(
                'Selecciona un contador para filtrar las órdenes.',
                style: AppText.gris.segunTema(context),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _contador(
                    key: 'resumen-pendientes',
                    filtro: _FiltroResumen.pendientes,
                    valor: _contar(ordenes, EstadoOrden.pendiente),
                    etiqueta: 'Pendientes',
                    icono: Icons.pending_actions,
                    color: AppColors.ambar,
                  ),
                  const SizedBox(width: 10),
                  _contador(
                    key: 'resumen-en-progreso',
                    filtro: _FiltroResumen.enProgreso,
                    valor: _contar(ordenes, EstadoOrden.enProgreso),
                    etiqueta: 'En progreso',
                    icono: Icons.sync,
                    color: AppColors.azul,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _contador(
                    key: 'resumen-completadas',
                    filtro: _FiltroResumen.completadas,
                    valor: _contar(ordenes, EstadoOrden.completada),
                    etiqueta: 'Completadas',
                    icono: Icons.check_circle_outline,
                    color: AppColors.verde,
                  ),
                  const SizedBox(width: 10),
                  _contador(
                    key: 'resumen-criticas',
                    filtro: _FiltroResumen.criticas,
                    valor: _contar(ordenes, EstadoOrden.critica),
                    etiqueta: 'Críticas',
                    icono: Icons.error_outline,
                    color: AppColors.rojo,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SeccionHeader(
                icono: Icons.schedule,
                titulo: 'ÓRDENES POR VENCER',
                accion: '${porVencer.length}',
                colorAccion: AppColors.rojo,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Órdenes abiertas que vencen en 24 horas o ya están vencidas.',
                  style: AppText.gris.segunTema(context),
                ),
              ),
              if (porVencer.isEmpty)
                _mensajeVacio(context, 'No hay órdenes próximas a vencer.')
              else
                ...porVencer.map(
                  (orden) => FilaAlerta(
                    key: ValueKey('resumen-por-vencer-${orden.id}'),
                    icono: Icons.schedule,
                    titulo: orden.titulo,
                    descripcion: orden.ubicacion,
                    hora: orden.tiempoRestante,
                    codigo: orden.codigo,
                    color: orden.estaVencida ? AppColors.rojo : AppColors.ambar,
                    onTap: () => Navigator.pushNamed(
                      context,
                      Rutas.detalleOrden,
                      arguments: orden,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              SeccionHeader(
                titulo: _filtro == null
                    ? 'DETALLE DE ÓRDENES (${visibles.length})'
                    : 'ÓRDENES ${_nombreFiltro(_filtro!)} (${visibles.length})',
                accion: _filtro == null ? null : 'Ver todas',
                onAccion: _filtro == null
                    ? null
                    : () => setState(() => _filtro = null),
              ),
              if (state.status == EstadoOrdenes.error) ...[
                TileAviso(
                  icono: Icons.cloud_off,
                  titulo: 'No se pudieron actualizar las órdenes',
                  subtitulo: state.mensajeError,
                  color: AppColors.rojo,
                ),
                const SizedBox(height: 12),
              ],
              if (visibles.isEmpty)
                _mensajeVacio(
                  context,
                  _filtro == null
                      ? 'Aún no hay órdenes en esta planta.'
                      : 'No hay órdenes en este estado.',
                )
              else
                ...visibles.map(
                  (orden) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: OrdenCard(
                      key: ValueKey('resumen-orden-${orden.id}'),
                      codigo: orden.codigo,
                      titulo: orden.titulo,
                      ubicacion: orden.ubicacion,
                      estado: orden.estado.etiqueta,
                      estadoColor: orden.estado.color,
                      hora: orden.hora,
                      prioridad: orden.prioridadTexto,
                      estilo: EstiloOrden.conBarra,
                      sinAsignar: orden.sinAsignar,
                      reportes: orden.totalReportes,
                      onTap: () => Navigator.pushNamed(
                        context,
                        Rutas.detalleOrden,
                        arguments: orden,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _contador({
    required String key,
    required _FiltroResumen filtro,
    required int valor,
    required String etiqueta,
    required IconData icono,
    required Color color,
  }) {
    final seleccionado = _filtro == filtro;
    return Expanded(
      child: Semantics(
        button: true,
        selected: seleccionado,
        label: '$etiqueta: $valor',
        child: GestureDetector(
          key: ValueKey(key),
          onTap: () => _seleccionar(filtro),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: seleccionado
                    ? AppColors.azul.segunTema(context)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: StatCard(
              icono: icono,
              valor: '$valor',
              etiqueta: etiqueta,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  String _nombreFiltro(_FiltroResumen filtro) => switch (filtro) {
        _FiltroResumen.pendientes => 'PENDIENTES',
        _FiltroResumen.enProgreso => 'EN PROGRESO',
        _FiltroResumen.completadas => 'COMPLETADAS',
        _FiltroResumen.criticas => 'CRÍTICAS',
      };

  Widget _mensajeVacio(BuildContext context, String mensaje) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text(mensaje, style: AppText.gris.segunTema(context)),
        ),
      );
}
