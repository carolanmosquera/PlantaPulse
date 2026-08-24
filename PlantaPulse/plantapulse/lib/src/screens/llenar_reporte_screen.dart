// lib/src/screens/llenar_reporte_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../components/widgets.dart';

class LlenarReporteScreen extends StatefulWidget {
  const LlenarReporteScreen({super.key});
  @override
  State<LlenarReporteScreen> createState() => _LlenarReporteScreenState();
}

class _LlenarReporteScreenState extends State<LlenarReporteScreen> {
  final _detallesCtrl = TextEditingController();
  int _estatus = 1;
  bool _incidenteCritico = false;
  final List<String> _fotos = ['f1', 'f2', 'f3'];

  static const _estatus_ = ['Pendiente', 'En Progreso', 'Crítico'];

  @override
  void initState() {
    super.initState();
    _detallesCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _detallesCtrl.dispose();
    super.dispose();
  }

  bool get _puedeEnviar => _detallesCtrl.text.trim().length >= 10;

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: 'Llenar reporte de avance',
      mostrarMenu: true,
      tabActiva: 0,
      cuerpo: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 14),

          const TarjetaOscura(
            icono: Icon(Icons.description_outlined, color: Colors.white,
              size: 26),
            titulo: 'Resumen de Intervención',
            subtitulo: 'ORDEN ID\n#WO-2024-0892\n\nEQUIPO\n'
                       'Compresor Atlas Copco GA75',
            extra: Row(children: [
              PillEstado(texto: 'PLANTA A', color: Colors.white70),
              SizedBox(width: 8),
              PillEstado(texto: 'SECTOR 04', color: Colors.white70),
            ]),
          ),

          const SeccionHeader(icono: Icons.schedule,
            titulo: 'ESTATUS DE AVANCE'),
          ChipsFila(
            opciones: _estatus_,
            iconos: const [Icons.schedule, Icons.check_circle_outline,
                           Icons.error_outline],
            colorActivo: AppColors.ambar,
            onCambio: (i) => setState(() => _estatus = i),
          ),

          SeccionHeader(
            icono: Icons.info_outline,
            titulo: 'DETALLES TÉCNICOS',
            accion: 'REQUERIDO',
            colorAccion: _puedeEnviar ? AppColors.textoGris : AppColors.rojo,
          ),
          CampoTexto(
            label: '',
            hint: 'Describa el trabajo realizado, hallazgos técnicos y '
                  'ajustes de parámetros...',
            lineas: 4,
            controller: _detallesCtrl,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${_detallesCtrl.text.length} caracteres',
              style: AppText.gris),
          ),

          SeccionHeader(
            icono: Icons.photo_camera_outlined,
            titulo: 'EVIDENCIA FOTOGRÁFICA',
            accion: 'AÑADIR FOTO',
            onAccion: () => setState(() => _fotos.add('nueva')),
          ),
          GridFotos(
            urls: _fotos,
            columnas: 3,
            permiteAgregar: false,
          ),

          const SizedBox(height: 16),
          FilaOpcion(
            icono: Icons.priority_high,
            titulo: 'Incidente Crítico',
            subtitulo: 'Notificar al supervisor de inmediato',
            color: _incidenteCritico ? AppColors.rojo : AppColors.textoGris,
            trailing: Switch(
              value: _incidenteCritico,
              activeColor: AppColors.rojo,
              onChanged: (v) => setState(() => _incidenteCritico = v),
            ),
          ),

          const SizedBox(height: 20),
          BotonAncho(
            texto: 'ENVIAR REPORTE',
            icono: Icons.arrow_forward,
            onTap: _puedeEnviar
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reporte sincronizado'),
                        backgroundColor: AppColors.verde));
                    Navigator.pop(context);
                  }
                : null,
          ),
          const SizedBox(height: 10),
          const Center(child: Text(
            'Al enviar, el registro se sincronizará con el sistema central '
            'de PlantaPulse.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textoGris))),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}