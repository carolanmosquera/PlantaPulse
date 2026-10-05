// lib/src/features/ordenes/ui/screens/resumen_turno_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/core.dart';

class ResumenTurnoScreen extends StatelessWidget {
  const ResumenTurnoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: 'Resumen de Turno',
      mostrarAtras: false,
      mostrarMenu: true,
      tabActiva: 0,
      accionesExtra: [
        IconButton(icon: const Icon(Icons.notifications_none,
          color: AppColors.texto), onPressed: () {}),
      ],
      cuerpo: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 15,
                color: AppColors.textoGris),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PERIODO', style: TextStyle(fontSize: 9,
                    letterSpacing: 1, color: AppColors.textoGris)),
                  Text('Hoy, 24 Mayo', style: TextStyle(fontSize: 13.5,
                    fontWeight: FontWeight.w600, color: AppColors.texto)),
                ],
              ),
              const Icon(Icons.keyboard_arrow_down, size: 18,
                color: AppColors.textoGris),
              const Spacer(),
              const PillEstado(texto: 'TURNO A',
                color: AppColors.azulOscuro, relleno: true),
            ],
          ),
          const SizedBox(height: 18),

          // ══ MÉTRICAS ══
          const Row(children: [
            Expanded(child: StatCard(icono: Icons.bar_chart,
              valor: '24', etiqueta: 'TOTAL ÓRDENES', nota: 'Turno Mañana')),
            SizedBox(width: 12),
            Expanded(child: StatCard(icono: Icons.warning_amber_rounded,
              valor: '08', etiqueta: 'PENDIENTES',
              nota: 'Requieren atención', color: AppColors.ambar)),
          ]),
          const SizedBox(height: 12),
          const Row(children: [
            Expanded(child: StatCard(icono: Icons.check_circle_outline,
              valor: '14', etiqueta: 'COMPLETADAS',
              nota: '92% de la meta', color: AppColors.verde)),
            SizedBox(width: 12),
            Expanded(child: StatCard(icono: Icons.error_outline,
              valor: '02', etiqueta: 'CRÍTICAS',
              nota: 'Acción inmediata', color: AppColors.rojo)),
          ]),
          const SizedBox(height: 18),

          // ══ AGENTE IA ══
          TarjetaOscura(
            icono: const CircleAvatar(radius: 22,
              backgroundColor: Colors.white24,
              child: Icon(Icons.auto_awesome, color: AppColors.naranja)),
            etiqueta: 'Análisis Predictivo PlantaPulse',
            titulo: 'Resumen del Agente IA',
            subtitulo: 'Se detectó un patrón de vibración inusual en la '
                'Turbina-04. Recomiendo priorizar la inspección preventiva '
                'antes del cambio de turno para evitar paradas no programadas.',
            extra: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.naranja,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Generar Reporte Detallado',
                    style: TextStyle(color: Colors.white, fontSize: 14,
                                     fontWeight: FontWeight.w600)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),

          // ══ POR VENCER ══
          SeccionHeader(
            icono: Icons.error_outline,
            titulo: 'ÓRDENES POR VENCER',
            accion: 'Urgente',
            colorAccion: AppColors.rojo,
            onAccion: () {},
          ),
          const FilaAlerta(icono: Icons.schedule,
            titulo: 'Fuga Hidráulica Prensa 05',
            descripcion: 'Planta A - Sector 2', hora: '15 min',
            codigo: 'OT-9021', color: AppColors.rojo, noLeida: true),
          const SizedBox(height: 10),
          const FilaAlerta(icono: Icons.schedule,
            titulo: 'Calibración Sensor Temp',
            descripcion: 'Línea de Envasado', hora: '45 min',
            codigo: 'OT-9024', color: AppColors.rojo),
          const SizedBox(height: 10),
          const FilaAlerta(icono: Icons.schedule,
            titulo: 'Revisión Motor Banda B',
            descripcion: 'Almacén Central', hora: '1h 20m',
            codigo: 'OT-9028', color: AppColors.ambar),

          const SizedBox(height: 14),
          const Center(child: Text('Ver todas las tareas pendientes  ⌄',
            style: TextStyle(fontSize: 12.5, color: AppColors.azul,
                             fontWeight: FontWeight.w600))),

          const SizedBox(height: 18),
          const TileAviso(
            icono: Icons.sync,
            titulo: 'Última Sincronización',
            subtitulo: 'Sistemas centrales actualizados hace 2 min. • CONECTADO',
            color: AppColors.verde,
          ),
          const SizedBox(height: 12),
          const TileAviso(
            icono: Icons.lightbulb_outline,
            titulo: 'Tip: Usa la validación por fotos para cerrar órdenes '
                    'más rápido',
            color: AppColors.textoGris,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}