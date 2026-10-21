// lib/src/features/ordenes/ui/screens/detalle_orden_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../../domain/usecases/editar_orden.dart';
import '../bloc/ordenes_bloc.dart';
import '../widgets/editar_orden_hoja.dart';

class DetalleOrdenScreen extends StatefulWidget {
  /// Llega por `arguments`. Se usa por su id para buscar la versión viva
  /// en el OrdenesBloc, y como respaldo si ya no está en la lista.
  final Orden orden;

  const DetalleOrdenScreen({super.key, required this.orden});

  @override
  State<DetalleOrdenScreen> createState() => _DetalleOrdenScreenState();
}

class _DetalleOrdenScreenState extends State<DetalleOrdenScreen> {
  // Los reportes llegan por stream, en orden cronológico. Se abre una vez:
  // cada redibujado no debe abrir otra suscripción.
  late final Stream<List<Reporte>> _reportes = context
      .read<ObservarReportesDeOrden>()
      .ejecutar(widget.orden.id);

  /// "Asignar técnico": cierra el ciclo de las órdenes sin asignar.
  /// Sin mensaje de éxito: la orden cambia sola cuando llega por el stream.
  Future<void> _asignarTecnico(Orden orden) async {
    final bloc = context.read<OrdenesBloc>();
    final avisos = ScaffoldMessenger.of(context);
    final List<Usuario> tecnicos;
    try {
      tecnicos = await context.read<ListarTecnicosDePlanta>().ejecutar(
        orden.plantaId,
      );
    } catch (e) {
      avisos.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.rojo,
          content: Text(FalloApp.mensajeDe(e)),
        ),
      );
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
      seleccionado: tecnicos
          .where((u) => u.uid == orden.asignadoAUid)
          .firstOrNull,
      claveDe: (u) => u.uid,
      textoNinguno: 'Sin asignar',
    );
    if (eleccion == null) return; // cerró sin elegir
    if (eleccion.valor?.uid == orden.asignadoAUid) return; // no cambió
    bloc.add(TecnicoAsignado(orden.id, eleccion.valor));
  }

  /// "Eliminar orden": solo para órdenes creadas por equivocación.
  ///
  /// Va directo al caso de uso (no por el Bloc) porque aquí sí hace falta
  /// saber el resultado: si sale bien hay que salir del detalle. Y el
  /// mensaje de éxito es fiable: la función del servidor devuelve error
  /// explícito si no pudo eliminarla, nunca falla en silencio.
  Future<void> _eliminar(Orden orden) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar la orden ${orden.codigo}?'),
        content: const Text(
          'Úsalo solo si se creó por equivocación. Dejará de verse en el '
          'feed y en Mis Tareas, pero queda registrado quién la eliminó y '
          'cuándo.\n\nSolo se puede eliminar una orden pendiente, sin '
          'reportes ni alertas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.rojo),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    final eliminar = context.read<EliminarOrden>();
    final navegador = Navigator.of(context);
    final avisos = ScaffoldMessenger.of(context);
    try {
      await eliminar.ejecutar(orden.id);
      navegador.pop(); // la orden ya no existe para la app: fuera del detalle
      avisos.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.verde,
          content: Text('Orden ${orden.codigo} eliminada'),
        ),
      );
    } catch (e) {
      // El motivo exacto viene del servidor: "tiene reportes", "ya empezó"...
      avisos.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.rojo,
          content: Text(FalloApp.mensajeDe(e)),
        ),
      );
    }
  }

  /// Acciones de supervisor y admin. "Editar" va a la vista como lápiz:
  /// escondido en el menú de tres puntos no se encontraba.
  List<Widget> _acciones(Orden orden) => [
    IconButton(
      tooltip: 'Editar orden',
      icon: const Icon(Icons.edit_outlined),
      onPressed: () => EditarOrdenHoja.mostrar(context, orden),
    ),
    PopupMenuButton<String>(
      tooltip: 'Más acciones',
      icon: const Icon(Icons.more_vert),
      onSelected: (accion) => switch (accion) {
        'asignar' => _asignarTecnico(orden),
        'eliminar' => _eliminar(orden),
        _ => EditarOrdenHoja.mostrar(context, orden),
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'asignar',
          child: ListTile(
            leading: Icon(Icons.engineering_outlined),
            title: Text('Asignar técnico'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'editar',
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Editar orden'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        // Solo se ofrece si puede funcionar; el servidor revisa el resto
        if (orden.puedeEliminarse)
          const PopupMenuItem(
            value: 'eliminar',
            child: ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.rojo),
              title: Text(
                'Eliminar orden',
                style: TextStyle(color: AppColors.rojo),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Si la orden cambia en la base de datos, el detalle se entera
    return BlocConsumer<OrdenesBloc, OrdenesState>(
      // Solo los fallos con error explícito: el éxito se ve en la orden
      listenWhen: (antes, ahora) =>
          ahora.errorAccion != null && antes.errorAccion != ahora.errorAccion,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.rojo,
          content: Text(state.errorAccion!),
        ),
      ),
      builder: (context, state) {
        final orden =
            state.ordenes.where((o) => o.id == widget.orden.id).firstOrNull ??
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
      // Supervisor y admin tienen sus acciones; el resto ve el menú de siempre
      mostrarMenu: !puedeEditar,
      accionesExtra: puedeEditar ? _acciones(orden) : null,
      conNavegacion: true,
      tabActiva: 0,
      barraInferiorFija: _barraAcciones(orden),
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
                Text(
                  orden.titulo,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.texto,
                    height: 1.3,
                  ),
                ),
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
                    child: Text(
                      orden.descripcion,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.texto,
                        height: 1.5,
                      ),
                    ),
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

          // ══ EVIDENCIA DEL HALLAZGO (fotos tomadas al crear la orden) ══
          if (orden.evidencias.isNotEmpty) ...[
            SeccionHeader(
              icono: Icons.photo_camera_outlined,
              titulo: 'EVIDENCIA DEL HALLAZGO',
              accion: '${orden.evidencias.length}',
            ),
            GaleriaFotos(urls: [
              for (final e in orden.evidencias)
                context.read<UrlDeEvidencia>().ejecutar(e.ruta),
            ]),
          ],

          // ══ OBSERVACIONES DEL SUPERVISOR ══
          // Al devolver la orden, el técnico tiene que ver qué corregir
          if (orden.observacionesSupervisor != null) ...[
            const SizedBox(height: 12),
            TileAviso(
              icono: Icons.rate_review_outlined,
              titulo: orden.estado == EstadoOrden.completada
                  ? 'Observaciones del supervisor'
                  : 'Correcciones solicitadas',
              subtitulo: orden.observacionesSupervisor,
              color: orden.estado == EstadoOrden.completada
                  ? AppColors.verde
                  : AppColors.ambar,
            ),
          ],
          if (orden.estado == EstadoOrden.completada &&
              orden.validadaPor != null) ...[
            const SizedBox(height: 12),
            MetaRow(
              icono: Icons.verified_outlined,
              texto: 'Validada y cerrada por',
              valor: orden.fechaCierre == null
                  ? orden.validadaPor!.nombre
                  : '${orden.validadaPor!.nombre} · ${fechaCorta(orden.fechaCierre!)}',
            ),
          ],

          // ══ REPORTES DE AVANCE ══
          StreamBuilder<List<Reporte>>(
            stream: _reportes,
            builder: (context, snap) {
              final reportes = snap.data ?? const <Reporte>[];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SeccionHeader(
                    icono: Icons.history,
                    titulo: 'REPORTES DE AVANCE',
                    accion: reportes.isEmpty ? null : '${reportes.length}',
                  ),
                  if (snap.hasError)
                    TileAviso(
                      icono: Icons.cloud_off,
                      titulo: FalloApp.mensajeDe(snap.error!),
                      color: AppColors.rojo,
                    )
                  else if (!snap.hasData)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (reportes.isEmpty)
                    const TileAviso(
                      icono: Icons.forum_outlined,
                      titulo: 'Aún no hay reportes de avance',
                      color: AppColors.textoGris,
                    )
                  else
                    for (final r in reportes) _TarjetaReporte(reporte: r),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // ══ EQUIPO ══
          if (orden.equipoNombre != null)
            FilaOpcion(
              icono: Icons.build_outlined,
              titulo: 'EQUIPO: ${orden.equipoNombre}',
              onTap: () {},
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ══════════ Barra fija inferior ══════════

  /// La acción que toca según quién mira y en qué estado está la orden:
  /// validar (supervisor/admin, orden en "validando") o reportar avance
  /// (técnico asignado o supervisor/admin, orden abierta).
  Widget? _barraAcciones(Orden orden) {
    final usuario = context.watch<SesionBloc>().state.usuario;
    if (usuario == null || orden.eliminada) return null;
    final opera = usuario.rol.puedeOperar;

    final Widget boton;
    if (opera && orden.estado == EstadoOrden.validando) {
      boton = BotonAncho(
        texto: 'VALIDAR EVIDENCIA',
        icono: Icons.fact_check_outlined,
        color: AppColors.verde,
        onTap: () =>
            Navigator.pushNamed(context, Rutas.validar, arguments: orden),
      );
    } else if (orden.estado.estaAbierta &&
        (opera || orden.asignadoAUid == usuario.uid)) {
      boton = BotonAncho(
        texto: 'LLENAR REPORTE DE AVANCE',
        icono: Icons.edit_note,
        onTap: () =>
            Navigator.pushNamed(context, Rutas.llenarReporte, arguments: orden),
      );
    } else {
      return null;
    }
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: boton,
    );
  }
}

/// Un reporte: autor, hora relativa, estado del trabajo, texto y fotos.
/// Si es alerta crítica, lleva la barra izquierda roja y la etiqueta.
class _TarjetaReporte extends StatelessWidget {
  final Reporte reporte;

  const _TarjetaReporte({required this.reporte});

  @override
  Widget build(BuildContext context) {
    final urlDe = context.read<UrlDeEvidencia>();
    final r = reporte;
    final colorEstado = switch (r.estadoTrabajo) {
      EstadoTrabajo.resuelto => AppColors.verde,
      EstadoTrabajo.bloqueado => AppColors.rojo,
      _ => AppColors.ambar,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borde),
      ),
      // La barra roja va en un Stack y no en un Row con IntrinsicHeight:
      // la cuadrícula de fotos no deja calcular alturas intrínsecas y la
      // pantalla reventaba en cuanto un reporte traía fotos.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          children: [
            if (r.esAlertaCritica)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 4, color: AppColors.rojo),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                r.esAlertaCritica ? 18 : 14,
                14,
                14,
                14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.azul,
                        child: Text(
                          r.autor.inicial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.autor.nombre,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.texto,
                              ),
                            ),
                            Text(haceCuanto(r.createdAt), style: AppText.gris),
                          ],
                        ),
                      ),
                      PillEstado(
                        texto: r.estadoTrabajo.etiqueta,
                        color: colorEstado,
                      ),
                    ],
                  ),
                  if (r.esAlertaCritica) ...[
                    const SizedBox(height: 8),
                    const PillEstado(
                      texto: 'Alerta crítica',
                      color: AppColors.rojo,
                      relleno: true,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    r.detalles,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.texto,
                      height: 1.45,
                    ),
                  ),
                  if (r.evidencias.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    GaleriaFotos(
                      urls: [
                        for (final e in r.evidencias) urlDe.ejecutar(e.ruta),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
