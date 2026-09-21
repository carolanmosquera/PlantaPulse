// lib/src/screens/detalle_orden_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/datos_demo.dart';
import '../models/firestore_helpers.dart';
import '../models/orden.dart';
import '../models/reporte.dart';
import '../components/widgets.dart';

class DetalleOrdenScreen extends StatefulWidget {
  final Orden orden;

  const DetalleOrdenScreen({super.key, required this.orden});

  @override
  State<DetalleOrdenScreen> createState() => _DetalleOrdenScreenState();
}

class _DetalleOrdenScreenState extends State<DetalleOrdenScreen> {
  final _comentarioCtrl = TextEditingController();

  // Los avances de la orden viven en su subcolección 'reportes'.
  // El timeline y la evidencia se arman a partir de ellos.
  late List<Reporte> _reportes;
  late List<String> _fotos;

  @override
  void initState() {
    super.initState();
    _reportes = List.of(reportesDemo[widget.orden.id] ?? const <Reporte>[]);
    _fotos = [
      for (final r in _reportes)
        for (final e in r.evidencias) e.thumbUrl,
    ];
    _comentarioCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  void _enviarComentario() {
    final contenido = _comentarioCtrl.text.trim();
    if (contenido.isEmpty) return;

    final ahora = DateTime.now();
    setState(() {
      _reportes.add(Reporte(
        id: 'local-${ahora.microsecondsSinceEpoch}',   // Firestore dará el definitivo
        ordenId: widget.orden.id,
        autor: usuarioActualDemo,
        detalles: contenido,
        createdAt: ahora,
      ));
      _comentarioCtrl.clear();
    });

    FocusScope.of(context).unfocus();   // cierra el teclado
  }

  @override
  Widget build(BuildContext context) {
    final orden = widget.orden;

    return PantallaBase(
      titulo: 'Orden #${orden.codigo}',
      mostrarMenu: true,
      conNavegacion: true,
      tabActiva: 0,
      barraInferiorFija: _barraComentario(),
      cuerpo: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 12),

          // ══ BANNER DE ESTADO ══
          TarjetaOscura(
            etiqueta: 'ESTADO ACTUAL',
            titulo: orden.estado.etiqueta,
            extra: PillEstado(
              texto: 'Prioridad ${orden.prioridadTexto}',
              color: orden.prioridad.color,
            ),
          ),
          const SizedBox(height: 16),

          // ══ FICHA PRINCIPAL ══
          TarjetaBlanca(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(orden.titulo,
                  style: const TextStyle(fontSize: 20,
                                         fontWeight: FontWeight.bold,
                                         color: AppColors.texto,
                                         height: 1.3)),
                const SizedBox(height: 8),
                MetaRow(icono: Icons.place_outlined, texto: orden.ubicacion),
                const SizedBox(height: 14),

                // Descripción sobre fondo tenue
                if (orden.descripcion.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.fondo,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(orden.descripcion,
                      style: const TextStyle(fontSize: 14,
                                             color: AppColors.texto,
                                             height: 1.5)),
                  ),

                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: MetaRow(
                        icono: Icons.person_outline,
                        texto: 'Asignado a',
                        valor: orden.asignadoA.nombre,
                      ),
                    ),
                    Expanded(
                      child: MetaRow(
                        icono: Icons.calendar_today_outlined,
                        texto: 'Creado',
                        valor: fechaCorta(orden.createdAt),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ══ EVIDENCIA ══
          SeccionHeader(
            icono: Icons.photo_camera_outlined,
            titulo: 'EVIDENCIA FOTOGRÁFICA',
            accion: 'Añadir',
            onAccion: () => setState(() => _fotos.add('nueva')),
          ),
          GridFotos(
            urls: _fotos,
            columnas: 2,
            permiteAgregar: false,
            onAgregar: () => setState(() => _fotos.add('nueva')),
          ),

          // ══ TIMELINE ══
          const SeccionHeader(
            icono: Icons.history,
            titulo: 'REGISTRO DE ACTIVIDADES',
          ),
          TarjetaBlanca(
            child: Column(
              children: List.generate(_reportes.length, (i) {
                final r = _reportes[i];
                return PasoTimeline(
                  titulo: r.detalles,
                  subtitulo: 'Téc: ${r.autor.nombre}',
                  hora: r.horaTexto,
                  completado: r.estadoTrabajo != EstadoTrabajo.bloqueado,
                  esUltimo: i == _reportes.length - 1,
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // ══ EQUIPO ══
          if (orden.equipoNombre != null)
            FilaOpcion(
              icono: Icons.build_outlined,
              titulo: 'EQUIPO: ${orden.equipoNombre}',
              // Serial y modelo no viajan en la orden: salen del documento del equipo
              subtitulo: equipoDemoPorId(orden.equipoId)?.subtitulo,
              onTap: () {},
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ══════════ Barra fija inferior ══════════
  Widget _barraComentario() {
    final hayTexto = _comentarioCtrl.text.trim().isNotEmpty;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borde),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 12,
                             color: AppColors.textoGris),
                        SizedBox(width: 6),
                        Text('REPORTAR HALLAZGO',
                          style: TextStyle(fontSize: 9,
                                           letterSpacing: 0.8,
                                           color: AppColors.textoGris)),
                      ],
                    ),
                  ),
                  TextField(
                    controller: _comentarioCtrl,
                    maxLines: 2,
                    minLines: 1,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Escribe un comentario o actualización...',
                      hintStyle: TextStyle(fontSize: 14,
                                           color: AppColors.textoGris),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: hayTexto ? _enviarComentario : null,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: hayTexto ? AppColors.azul : AppColors.gris,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, color: Colors.white, size: 18),
                  SizedBox(height: 2),
                  Text('ENVIAR', style: TextStyle(color: Colors.white,
                                                  fontSize: 8,
                                                  letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}