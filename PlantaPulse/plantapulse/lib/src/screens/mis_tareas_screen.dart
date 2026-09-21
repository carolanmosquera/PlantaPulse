// lib/src/screens/mis_tareas_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/orden.dart';
import '../models/datos_demo.dart';
import '../components/widgets.dart';

class MisTareasScreen extends StatefulWidget {
  const MisTareasScreen({super.key});
  @override
  State<MisTareasScreen> createState() => _MisTareasScreenState();
}

class _MisTareasScreenState extends State<MisTareasScreen> {
  int _filtro = 0;
  static const _filtros = ['Todas', 'Urgentes', 'Hoy', 'Próximas'];

  static bool _esUrgente(Orden t) =>
      t.prioridad == Prioridad.critica || t.prioridad == Prioridad.alta;

  static bool _venceHoy(Orden t) {
    final ahora = DateTime.now();
    final f = t.fechaLimite;
    return f.year == ahora.year && f.month == ahora.month && f.day == ahora.day;
  }

  List<Orden> get _visibles => switch (_filtro) {
    1 => tareasDemo.where(_esUrgente).toList(),
    2 => tareasDemo.where(_venceHoy).toList(),
    3 => tareasDemo.where((t) => !_venceHoy(t)).toList(),
    _ => tareasDemo,
  };

  @override
  Widget build(BuildContext context) {
    final visibles = _visibles;
    final criticas = tareasDemo.where(_esUrgente).length;

    return PantallaBase(
      titulo: 'Mis Tareas',
      mostrarAtras: false,
      mostrarMenu: true,
      tabActiva: 0,
      fab: FloatingActionButton(
        backgroundColor: AppColors.naranja,
        onPressed: () {},
        child: const Icon(Icons.more_vert, color: Colors.white),
      ),
      cuerpo: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resumen de Hoy', style: AppText.titulo),
                    const SizedBox(height: 3),
                    Text('Tienes $criticas tareas críticas pendientes',
                      style: AppText.gris),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13,
                                                    vertical: 7),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borde),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.filter_list, size: 14,
                    color: AppColors.textoGris),
                  SizedBox(width: 6),
                  Text('Filtrar', style: TextStyle(fontSize: 12.5)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ChipsFila(
            opciones: _filtros,
            onCambio: (i) => setState(() => _filtro = i),
          ),

          SeccionHeader(
            titulo: 'ÓRDENES ASIGNADAS (${visibles.length})',
            accion: 'VER CALENDARIO',
            onAccion: () {},
          ),

          if (visibles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 44),
              child: Center(child: Text('Sin tareas en este filtro',
                style: AppText.gris)),
            )
          else
            ...visibles.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OrdenCard(
                codigo: t.codigo,
                titulo: t.titulo,
                ubicacion: t.ubicacion,
                estado: t.estado.etiqueta,
                estadoColor: t.estado.color,
                hora: t.hora,
                prioridad: t.prioridadTexto,
                estilo: EstiloOrden.conBarra,    // ← variante sin foto
                onTap: () {},
              ),
            )),

          const SizedBox(height: 8),
          const TarjetaOscura(
            icono: Icon(Icons.check_circle_outline, color: AppColors.naranja,
              size: 28),
            titulo: 'Progreso Semanal',
            subtitulo: 'Has completado 12 órdenes de trabajo esta semana. '
                       '¡Vas por buen camino!',
          ),
          const SizedBox(height: 12),
          const TileAviso(
            icono: Icons.warning_amber_rounded,
            titulo: 'Asegúrese de usar EPP completo antes de iniciar '
                    'cualquier tarea técnica.',
            color: AppColors.ambar,
          ),
          const SizedBox(height: 14),
          const Center(child: Text('ID DISPOSITIVO: PULSE-MOB-7729',
            style: TextStyle(fontSize: 9, letterSpacing: 1,
                             color: AppColors.textoGris))),
          const Center(child: Text('SINC: 2024-05-23 10:15:33',
            style: TextStyle(fontSize: 9, letterSpacing: 1,
                             color: AppColors.textoGris))),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}