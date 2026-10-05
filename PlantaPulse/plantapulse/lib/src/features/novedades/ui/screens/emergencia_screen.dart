// lib/src/features/novedades/ui/screens/emergencia_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/core.dart';

class EmergenciaScreen extends StatefulWidget {
  const EmergenciaScreen({super.key});
  @override
  State<EmergenciaScreen> createState() => _EmergenciaScreenState();
}

class _EmergenciaScreenState extends State<EmergenciaScreen> {
  final _descCtrl = TextEditingController();
  int _categoria = 0;
  final List<String> _fotos = ['adjunto1'];

  static const _categorias = ['Fuego / Incendio', 'Falla Eléctrica',
                              'Fuga de Líquidos', 'Falla Mecánica'];
  static const _iconos = [Icons.local_fire_department, Icons.bolt,
                          Icons.water_drop_outlined, Icons.build_outlined];

  @override
  void initState() {
    super.initState();
    _descCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _puedeEnviar => _descCtrl.text.trim().length >= 10;

  void _enviar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
          color: AppColors.rojo, size: 40),
        title: const Text('¿Confirmar alerta crítica?'),
        content: Text('Se notificará de inmediato a todos los supervisores '
            'de turno sobre: ${_categorias[_categoria]}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alerta enviada a supervisores'),
                  backgroundColor: AppColors.rojo));
              Navigator.pop(context);
            },
            child: const Text('ENVIAR',
              style: TextStyle(color: AppColors.rojo,
                               fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: 'Reporte de Emergencia',
      tabActiva: 1,
      cuerpo: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 14),

          const TileAviso(
            icono: Icons.error_outline,
            titulo: 'Utilice esta pantalla únicamente para incidentes que '
                    'requieran intervención inmediata.',
            color: AppColors.textoGris,
          ),
          const SizedBox(height: 18),

          const Row(children: [
            Icon(Icons.error_outline, color: AppColors.rojo, size: 22),
            SizedBox(width: 8),
            Text('Alerta Crítica',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold,
                               color: AppColors.rojo)),
          ]),
          const SizedBox(height: 4),
          const Text('PROTOCOLO DE ACCIÓN INMEDIATA',
            style: TextStyle(fontSize: 10, letterSpacing: 1.2,
                             color: AppColors.textoGris)),

          const SeccionHeader(titulo: 'Categoría del Incidente'),
          ChipsFila(
            opciones: _categorias,
            iconos: _iconos,
            envolver: true,                    // ← se acomodan en 2 filas
            colorActivo: AppColors.rojo,
            onCambio: (i) => setState(() => _categoria = i),
          ),

          SeccionHeader(
            titulo: 'Descripción del Hallazgo',
            accion: '${_descCtrl.text.length}/200',
            colorAccion: _descCtrl.text.length > 200
                ? AppColors.rojo : AppColors.textoGris,
          ),
          CampoTexto(
            label: '',
            hint: 'Detalle la situación, ubicación exacta y riesgos '
                  'inminentes...',
            lineas: 4,
            controller: _descCtrl,
          ),

          const SeccionHeader(titulo: 'Evidencia Visual'),
          GridFotos(
            urls: _fotos,
            columnas: 3,
            onAgregar: () => setState(() => _fotos.add('nueva')),
          ),

          const SizedBox(height: 16),
          const FilaOpcion(
            icono: Icons.place_outlined,
            titulo: 'Ubicación Detectada',
            subtitulo: 'Planta Norte • Sector A-04 (GPS: 19.43, -99.13)',
          ),
          const SizedBox(height: 12),
          const TileAviso(
            icono: Icons.info_outline,
            titulo: 'Asegure su propia integridad física antes de reportar.',
            color: AppColors.ambar,
          ),

          const SizedBox(height: 20),
          BotonAncho(
            texto: 'ENVIAR ALERTA AHORA',
            icono: Icons.send,
            estilo: EstiloBoton.peligro,
            onTap: _puedeEnviar ? _enviar : null,
          ),
          const SizedBox(height: 10),
          const Center(child: Text(
            'SE NOTIFICARÁ A TODOS LOS SUPERVISORES DE TURNO',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9.5, letterSpacing: 1,
                             color: AppColors.textoGris))),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}