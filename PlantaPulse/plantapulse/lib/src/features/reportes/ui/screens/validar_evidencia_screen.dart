// lib/src/features/reportes/ui/screens/validar_evidencia_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/core.dart';

class ValidarEvidenciaScreen extends StatefulWidget {
  const ValidarEvidenciaScreen({super.key});
  @override
  State<ValidarEvidenciaScreen> createState() => _ValidarEvidenciaScreenState();
}

class _ValidarEvidenciaScreenState extends State<ValidarEvidenciaScreen> {
  final _obsCtrl = TextEditingController();

  static const _fotos = ['PARTE MECÁNICA', 'PANEL ELÉCTRICO',
                         'VÁLVULA HIDRÁULICA', 'MOTOR / ENGRANAJES'];

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  void _resolver(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: color));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: 'Validar Evidencia',
      mostrarMenu: true,
      tabActiva: 0,
      cuerpo: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 14),

          const Row(
            children: [
              Text('OT #2024-0892', style: TextStyle(fontSize: 11.5,
                letterSpacing: 0.5, color: AppColors.textoGris)),
              Spacer(),
              PillEstado(texto: 'POR VALIDAR', color: AppColors.ambar),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Mantenimiento Preventivo Compresor GA75',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                             color: AppColors.texto, height: 1.3)),

          const SeccionHeader(icono: Icons.photo_camera_outlined,
            titulo: 'Evidencia Fotográfica'),

          // Cuadrícula 2×2 con etiqueta bajo cada foto
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.15,
            children: _fotos.map((etiqueta) => Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.borde,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.image_outlined,
                    color: AppColors.textoGris, size: 34),
                ),
                Positioned(
                  left: 8, bottom: 8, right: 8,
                  child: Text(etiqueta,
                    style: const TextStyle(fontSize: 9, color: Colors.white,
                      fontWeight: FontWeight.w600, letterSpacing: 0.5,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black87)])),
                ),
                const Positioned(right: 8, bottom: 8,
                  child: Icon(Icons.open_in_full, size: 13,
                    color: Colors.white)),
              ],
            )).toList(),
          ),

          const SeccionHeader(icono: Icons.description_outlined,
            titulo: 'Resumen del Reporte'),
          TarjetaBlanca(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Documentación enviada por el técnico asignado',
                  style: AppText.gris),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.fondo,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Se realizó el cambio de filtros y limpieza de válvulas. '
                    'Se detectó un desgaste menor en el rodamiento secundario '
                    'que no compromete la operación actual, pero se recomienda '
                    'revisión en 30 días.',
                    style: TextStyle(fontSize: 13.5, height: 1.5,
                                     color: AppColors.texto)),
                ),
                const SizedBox(height: 16),
                const MetaRow(icono: Icons.person_outline, texto: 'TÉCNICO',
                  valor: 'Ing. Juan Pablo Arrieta'),
                const SizedBox(height: 12),
                const MetaRow(icono: Icons.calendar_today_outlined,
                  texto: 'FECHA DE EJECUCIÓN',
                  valor: '24 de Mayo, 2024 • 14:30'),
                const SizedBox(height: 12),
                const MetaRow(icono: Icons.build_outlined,
                  texto: 'EQUIPO INTERVENIDO',
                  valor: 'Compresor Industrial AC-882'),
              ],
            ),
          ),

          const SeccionHeader(icono: Icons.chat_bubble_outline,
            titulo: 'Observaciones del Supervisor'),
          CampoTexto(
            label: '',
            hint: 'Escriba comentarios adicionales o motivos de corrección...',
            lineas: 3,
            controller: _obsCtrl,
          ),
          const SizedBox(height: 6),
          const Text('Las observaciones serán visibles para el equipo técnico.',
            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic,
                             color: AppColors.textoGris)),

          const SizedBox(height: 20),
          BotonAncho(
            texto: 'APROBAR Y CERRAR ORDEN',
            icono: Icons.assignment_turned_in_outlined,
            onTap: () => _resolver('Orden aprobada y cerrada',
                                   AppColors.verde),
          ),
          const SizedBox(height: 12),
          BotonAncho(
            texto: 'SOLICITAR CORRECCIONES',
            icono: Icons.error_outline,
            estilo: EstiloBoton.peligro,
            onTap: () => _resolver('Se solicitaron correcciones',
                                   AppColors.rojo),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}