// lib/src/screens/crear_orden_p2_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/orden.dart';
import '../models/borrador_orden.dart';
import '../models/datos_demo.dart';
import '../components/widgets.dart';

class CrearOrdenP2Screen extends StatefulWidget {
  final BorradorOrden borrador;
  const CrearOrdenP2Screen({super.key, required this.borrador});

  @override
  State<CrearOrdenP2Screen> createState() => _CrearOrdenP2ScreenState();
}

class _CrearOrdenP2ScreenState extends State<CrearOrdenP2Screen> {
  final _obsCtrl = TextEditingController();
  int _prioridad = 1;                  // 0 baja, 1 media, 2 crítica
  DateTime _fecha = DateTime.now().add(const Duration(days: 1));
  final List<String> _fotos = ['hallazgo1'];

  static const _prioridades = ['BAJA', 'MEDIA', 'CRÍTICA'];
  static const _prioridadesModelo = [
    Prioridad.baja, Prioridad.media, Prioridad.critica,
  ];
  static const _meses = ['enero','febrero','marzo','abril','mayo','junio',
    'julio','agosto','septiembre','octubre','noviembre','diciembre'];
  static const _dias = ['lunes','martes','miércoles','jueves','viernes',
    'sábado','domingo'];

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  String get _fechaTexto =>
      '${_dias[_fecha.weekday - 1]}, ${_fecha.day} de '
      '${_meses[_fecha.month - 1]} de ${_fecha.year}';

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!mounted || elegida == null) return;
    setState(() => _fecha = elegida);
  }

  void _publicar() {
    final b = widget.borrador;
    final ahora = DateTime.now();
    final codigo = 'WO-${ahora.year}-${ahora.millisecondsSinceEpoch % 10000}';

    final orden = Orden(
      id: codigo,                       // provisional: Firestore dará el definitivo
      codigo: codigo,
      plantaId: plantaDemoId,
      titulo: b.descripcion,
      descripcion: _obsCtrl.text.trim(),
      categoria: b.categoria,
      zonaNombre: b.equipoCodigo ?? '',
      equipoNombre: b.equipoNombre,
      creadoPor: usuarioActualDemo,
      asignadoA: usuarioActualDemo,     // toda orden nace con responsable
      asignadoAUid: usuarioActualDemo.uid,
      estado: _prioridad == 2 ? EstadoOrden.critica : EstadoOrden.pendiente,
      prioridad: _prioridadesModelo[_prioridad],
      createdAt: ahora,
      // El selector solo da el día: la orden vence al terminar ese día
      fechaLimite: DateTime(_fecha.year, _fecha.month, _fecha.day, 23, 59),
      ultimaActividad: ahora,
    );

    Navigator.pop(context, orden);
  }

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: 'Nueva Orden: Paso 2',
      tabActiva: 0,
      cuerpo: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(child: Container(height: 4, color: AppColors.verde)),
              const SizedBox(width: 6),
              Expanded(child: Container(height: 4, color: AppColors.verde)),
              const SizedBox(width: 12),
              const Text('PASO 2 DE 2',
                style: TextStyle(fontSize: 10, letterSpacing: 1,
                                 color: AppColors.textoGris)),
            ],
          ),
          const SizedBox(height: 16),

          TarjetaOscura(
            icono: const CircleAvatar(radius: 20,
              backgroundColor: Colors.white24,
              child: Icon(Icons.build, color: Colors.white, size: 20)),
            etiqueta: 'EQUIPO SELECCIONADO',
            titulo: widget.borrador.equipoNombre ?? 'Sin equipo',
            subtitulo: 'Ubicación: ${widget.borrador.equipoCodigo ?? "—"}',
          ),

          const SeccionHeader(icono: Icons.info_outline,
            titulo: 'PROGRAMACIÓN Y PRIORIDAD'),
          TarjetaBlanca(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Prioridad de la Intervención',
                  style: AppText.subtitulo),
                const SizedBox(height: 12),
                ChipsFila(
                  opciones: _prioridades,
                  colorActivo: AppColors.naranja,
                  onCambio: (i) => setState(() => _prioridad = i),
                ),
                const SizedBox(height: 18),
                const Text('Fecha de Intervención', style: AppText.subtitulo),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _elegirFecha,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borde),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined, size: 17,
                        color: AppColors.textoGris),
                      const SizedBox(width: 10),
                      Text(_fechaTexto,
                        style: const TextStyle(fontSize: 13.5,
                                               color: AppColors.texto)),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          SeccionHeader(
            icono: Icons.photo_camera_outlined,
            titulo: 'EVIDENCIA Y NOTAS',
            accion: '${_fotos.length} Adjuntos',
          ),
          GridFotos(
            urls: _fotos,
            columnas: 2,
            onAgregar: () => setState(() => _fotos.add('nueva')),
          ),
          const SizedBox(height: 16),

          const Text('Observaciones Técnicas Adicionales',
            style: AppText.subtitulo),
          const SizedBox(height: 10),
          CampoTexto(
            label: '',
            hint: 'Describa ruidos inusuales, fugas o comportamientos fuera '
                  'de lo normal observados en el equipo...',
            lineas: 3,
            controller: _obsCtrl,
          ),

          const SizedBox(height: 16),
          const TileAviso(
            icono: Icons.cloud_upload_outlined,
            titulo: 'Preparado para Sincronización',
            subtitulo: 'Al publicar, la orden se registrará en el servidor '
                       'central y se notificará al equipo de guardia.',
            color: AppColors.azul,
          ),

          const SizedBox(height: 20),
          BotonAncho(texto: 'PUBLICAR ORDEN',
            icono: Icons.arrow_forward, onTap: _publicar),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}