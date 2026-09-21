// lib/src/screens/llenar_reporte_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/datos_demo.dart';
import '../models/evidencia.dart';
import '../models/orden.dart';
import '../models/reporte.dart';
import '../components/widgets.dart';

class LlenarReporteScreen extends StatefulWidget {
  /// Orden a la que pertenece el reporte. Si no llega, usa la de demo.
  final Orden? orden;

  const LlenarReporteScreen({super.key, this.orden});

  @override
  State<LlenarReporteScreen> createState() => _LlenarReporteScreenState();
}

class _LlenarReporteScreenState extends State<LlenarReporteScreen> {
  final _detallesCtrl = TextEditingController();
  EstadoTrabajo _estado = EstadoTrabajo.enProgreso;
  bool _incidenteCritico = false;
  final List<String> _fotos = ['f1', 'f2', 'f3'];

  static const _estados = EstadoTrabajo.values;
  static const _iconosEstado = [
    Icons.schedule,               // pendiente
    Icons.play_circle_outline,    // en progreso
    Icons.block,                  // bloqueado
    Icons.check_circle_outline,   // resuelto
  ];

  Orden get _orden => widget.orden ?? ordenDetalleDemo;

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

  bool get _puedeAgregarFoto => _fotos.length < maxFotosPorReporte;

  /// Cada foto ocupa una de las cuatro posiciones fijas del modelo
  List<Evidencia> get _evidencias => [
        for (var i = 0; i < _fotos.length && i < maxFotosPorReporte; i++)
          Evidencia(
            posicion: PosicionFoto.values[i],
            url: _fotos[i],
            thumbUrl: _fotos[i],
            publicId: 'demo/${_fotos[i]}',
            tomadaEn: DateTime.now(),
          ),
      ];

  void _enviar() {
    final ahora = DateTime.now();
    final reporte = Reporte(
      id: 'local-${ahora.microsecondsSinceEpoch}',   // Firestore dará el definitivo
      ordenId: _orden.id,
      autor: usuarioActualDemo,
      detalles: _detallesCtrl.text.trim(),
      estadoTrabajo: _estado,
      evidencias: _evidencias,
      esAlertaCritica: _incidenteCritico,
      createdAt: ahora,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reporte sincronizado'),
        backgroundColor: AppColors.verde));
    Navigator.pop(context, reporte);
  }

  @override
  Widget build(BuildContext context) {
    final orden = _orden;

    return PantallaBase(
      titulo: 'Llenar reporte de avance',
      mostrarMenu: true,
      tabActiva: 0,
      cuerpo: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 14),

          TarjetaOscura(
            icono: const Icon(Icons.description_outlined, color: Colors.white,
              size: 26),
            titulo: 'Resumen de Intervención',
            subtitulo: 'ORDEN ID\n#${orden.codigo}\n\nEQUIPO\n'
                       '${orden.equipoNombre ?? orden.titulo}',
            extra: orden.zonaNombre.isEmpty
                ? null
                : Row(children: [
                    PillEstado(texto: orden.zonaNombre, color: Colors.white70),
                  ]),
          ),

          const SeccionHeader(icono: Icons.schedule,
            titulo: 'ESTATUS DE AVANCE'),
          ChipsFila(
            opciones: [for (final e in _estados) e.etiqueta],
            iconos: _iconosEstado,
            colorActivo: AppColors.ambar,
            inicial: _estados.indexOf(_estado),
            onCambio: (i) => setState(() => _estado = _estados[i]),
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
            accion: 'AÑADIR FOTO (${_fotos.length}/$maxFotosPorReporte)',
            onAccion: _puedeAgregarFoto
                ? () => setState(() => _fotos.add('nueva'))
                : null,
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
            onTap: _puedeEnviar ? _enviar : null,
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
