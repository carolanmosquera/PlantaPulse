// lib/src/features/ordenes/ui/screens/detalle_orden_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../bloc/ordenes_bloc.dart';
import '../widgets/editar_orden_hoja.dart';
import '../../../../core/data/datos_demo.dart';

class DetalleOrdenScreen extends StatefulWidget {
  /// Llega por `arguments`. Se usa por su id para buscar la versión viva
  /// en el OrdenesBloc, y como respaldo si ya no está en la lista.
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
        id: 'local-${ahora.microsecondsSinceEpoch}',   // la base de datos dará el definitivo
        ordenId: widget.orden.id,
        autor: usuarioActualDemo,
        detalles: contenido,
        createdAt: ahora,
      ));
      _comentarioCtrl.clear();
    });

    FocusScope.of(context).unfocus();   // cierra el teclado
  }

  /// "Asignar técnico": cierra el ciclo de las órdenes sin asignar.
  /// Sin mensaje de éxito: la orden cambia sola cuando llega por el stream.
  Future<void> _asignarTecnico(Orden orden) async {
    final bloc = context.read<OrdenesBloc>();
    final avisos = ScaffoldMessenger.of(context);
    final List<Usuario> tecnicos;
    try {
      tecnicos = await context
          .read<ListarTecnicosDePlanta>()
          .ejecutar(orden.plantaId);
    } catch (e) {
      avisos.showSnackBar(SnackBar(
        backgroundColor: AppColors.rojo,
        content: Text(FalloApp.mensajeDe(e)),
      ));
      return;
    }
    if (!mounted) return;
    final eleccion = await SelectorBuscable.mostrar<Usuario>(
      context,
      titulo: 'Asignar técnico',
      opciones: tecnicos,
      textoDe: (u) => u.nombre,
      subtituloDe: (u) => u.especialidad,
      iconoDe: (_) => Icons.engineering_outlined,
      seleccionado: tecnicos.where((u) => u.uid == orden.asignadoAUid).firstOrNull,
      claveDe: (u) => u.uid,
      textoNinguno: 'Sin asignar',
    );
    if (eleccion == null) return;                       // cerró sin elegir
    if (eleccion.valor?.uid == orden.asignadoAUid) return;   // no cambió
    bloc.add(TecnicoAsignado(orden.id, eleccion.valor));
  }

  /// Menú de tres puntos. Dos acciones separadas: son dos momentos
  /// distintos (asignar es rutina; editar corrige la orden).
  Widget _menu(Orden orden) => PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (accion) => switch (accion) {
          'asignar' => _asignarTecnico(orden),
          _ => EditarOrdenHoja.mostrar(context, orden),
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'asignar', child: ListTile(
            leading: Icon(Icons.engineering_outlined),
            title: Text('Asignar técnico'),
            contentPadding: EdgeInsets.zero)),
          PopupMenuItem(value: 'editar', child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Editar orden'),
            contentPadding: EdgeInsets.zero)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    // Si la orden cambia en la base de datos, el detalle se entera
    return BlocConsumer<OrdenesBloc, OrdenesState>(
      // Solo los fallos con error explícito: el éxito se ve en la orden
      listenWhen: (antes, ahora) =>
          ahora.errorAccion != null && antes.errorAccion != ahora.errorAccion,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.rojo,
            content: Text(state.errorAccion!)),
      ),
      builder: (context, state) {
        final orden = state.ordenes
                .where((o) => o.id == widget.orden.id)
                .firstOrNull ??
            widget.orden;
        return _contenido(orden);
      },
    );
  }

  Widget _contenido(Orden orden) {
    final puedeEditar =
        context.watch<SesionBloc>().state.usuario?.rol.puedeOperar ?? false;
    return PantallaBase(
      titulo: 'Orden #${orden.codigo}',
      // Supervisor y admin tienen su menú; el resto ve el de siempre
      mostrarMenu: !puedeEditar,
      accionesExtra: puedeEditar ? [_menu(orden)] : null,
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
                        icono: orden.sinAsignar
                            ? Icons.person_off_outlined
                            : Icons.person_outline,
                        texto: 'Asignado a',
                        valor: orden.asignadoA?.nombre ?? 'Sin asignar',
                        atenuado: orden.sinAsignar,
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