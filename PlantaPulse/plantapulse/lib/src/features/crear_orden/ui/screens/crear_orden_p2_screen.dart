// lib/src/features/crear_orden/ui/screens/crear_orden_p2_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../bloc/crear_orden_bloc.dart';
import '../widgets/elegir_categoria.dart';

/// Segundo paso del asistente. Comparte el Bloc de P1 y devuelve el ID
/// publicado para cerrar ambos pasos y regresar a la pantalla de origen.
class CrearOrdenP2Screen extends StatefulWidget {
  const CrearOrdenP2Screen({super.key});

  @override
  State<CrearOrdenP2Screen> createState() => _CrearOrdenP2ScreenState();
}

class _CrearOrdenP2ScreenState extends State<CrearOrdenP2Screen> {
  final _obsCtrl = TextEditingController();
  final _tituloCtrl = TextEditingController();
  final _descTecCtrl = TextEditingController();

  // ALTA no estaba: la IA la sugiere, y sin chip el valor 'alta' se pintaba
  // como BAJA (indexOf daba -1)
  static const _prioridades = ['BAJA', 'MEDIA', 'ALTA', 'CRÍTICA'];
  static const _prioridadesModelo = [
    Prioridad.baja, Prioridad.media, Prioridad.alta, Prioridad.critica,
  ];
  static const _meses = ['enero','febrero','marzo','abril','mayo','junio',
    'julio','agosto','septiembre','octubre','noviembre','diciembre'];
  static const _dias = ['lunes','martes','miércoles','jueves','viernes',
    'sábado','domingo'];

  @override
  void initState() {
    super.initState();
    final bloc = context.read<CrearOrdenBloc>();
    _obsCtrl.text = bloc.state.observaciones;
    _obsCtrl.addListener(
        () => bloc.add(ObservacionesCambiadas(_obsCtrl.text)));
    // Lo que propuso la IA (o lo que ya se había escrito) llega prerrellenado
    // y sigue siendo editable
    _tituloCtrl.text = bloc.state.titulo;
    _tituloCtrl.addListener(
        () => bloc.add(TituloCambiado(_tituloCtrl.text)));
    _descTecCtrl.text = bloc.state.descripcionTecnica;
    _descTecCtrl.addListener(
        () => bloc.add(DescripcionTecnicaCambiada(_descTecCtrl.text)));
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    _tituloCtrl.dispose();
    _descTecCtrl.dispose();
    super.dispose();
  }

  /// La etiqueta de un campo, con la marca si lo propuso la IA.
  Widget _etiqueta(String texto, bool deIa) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Flexible(child: Text(texto,
              style: AppText.subtitulo.segunTema(context))),
          if (deIa) ...[const SizedBox(width: 8), const MarcaIa()],
        ]),
      );

  /// La IA propuso una categoría que la planta no tiene. No se crea sola:
  /// el supervisor la crea (con el nombre ya puesto) o la descarta.
  Widget _sugerenciaCategoria(String nombre) {
    final bloc = context.read<CrearOrdenBloc>();
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 4),
      decoration: BoxDecoration(
        color: AppColors.naranja.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.naranja.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.auto_awesome, size: 16, color: AppColors.naranja),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'La IA sugiere la categoría «$nombre», que no existe en '
                'esta planta.',
                style: TextStyle(fontSize: 12.5,
                    color: AppColors.texto.segunTema(context), height: 1.35)),
            ),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
              onPressed: () => bloc.add(const SugerenciaCategoriaDescartada()),
              child: const Text('Descartar'),
            ),
            TextButton(
              onPressed: () => crearCategoriaSugerida(context, bloc, nombre),
              child: const Text('Crear categoría'),
            ),
          ]),
        ],
      ),
    );
  }

  String _fechaTexto(DateTime f) =>
      '${_dias[f.weekday - 1]}, ${f.day} de '
      '${_meses[f.month - 1]} de ${f.year}';

  Future<void> _elegirFecha(DateTime actual) async {
    final bloc = context.read<CrearOrdenBloc>();
    final elegida = await showDatePicker(
      context: context,
      initialDate: actual,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!mounted || elegida == null) return;
    bloc.add(FechaLimiteCambiada(elegida));
  }

  /// Responsable: un técnico o "Sin asignar" (se asigna después desde
  /// el detalle de la orden).
  Future<void> _elegirTecnico(CrearOrdenState state) async {
    final bloc = context.read<CrearOrdenBloc>();
    final eleccion = await SelectorBuscable.mostrar<Usuario>(
      context,
      titulo: 'Técnico Responsable',
      opciones: state.tecnicos,
      textoDe: (u) => u.nombre,
      subtituloDe: (u) => u.especialidad,
      iconoDe: (_) => Icons.engineering_outlined,
      seleccionado: state.tecnico,
      claveDe: (u) => u.uid,
      textoNinguno: state.requiereTecnico ? null : 'Sin asignar',
    );
    if (eleccion == null) return;            // cerró la hoja sin elegir
    final tecnico = eleccion.valor;
    bloc.add(tecnico == null
        ? const TecnicoQuitado()
        : TecnicoSeleccionado(tecnico));
  }

  /// La hoja pregunta de dónde; la foto llega por el caso de uso. Si la
  /// cámara falla (p. ej. sin permiso), se avisa en vez de no hacer nada.
  Future<void> _agregarFoto() async {
    final bloc = context.read<CrearOrdenBloc>();
    final obtener = context.read<ObtenerFoto>();
    final avisos = ScaffoldMessenger.of(context);
    final origen = await elegirOrigenFoto(context,
        camara: OrigenFoto.camara, galeria: OrigenFoto.galeria);
    if (origen == null) return;
    try {
      final foto = await obtener.ejecutar(origen);
      if (foto != null) bloc.add(FotoHallazgoAgregada(foto.bytes, foto.extension));
    } catch (e) {
      avisos.showSnackBar(SnackBar(
        backgroundColor: AppColors.rojo,
        content: Text(FalloApp.mensajeDe(e)),
      ));
    }
  }

  void _publicar() {
    final supervisor = context.read<SesionBloc>().state.usuario;
    if (supervisor == null) return;
    context.read<CrearOrdenBloc>().add(OrdenPublicada(supervisor.ref));
  }

  void _alCambiarEstado(BuildContext context, CrearOrdenState state) {
    final mensajero = ScaffoldMessenger.of(context);
    if (state.status == EstadoCrearOrden.publicada) {
      Navigator.pop(context, state.ordenIdCreada);
      mensajero.showSnackBar(SnackBar(
        backgroundColor: AppColors.verde,
        content: Text('Orden ${state.codigoCreado} publicada'),
      ));
    } else if (state.status == EstadoCrearOrden.error) {
      mensajero.showSnackBar(SnackBar(
        backgroundColor: AppColors.rojo,
        content: Text(state.mensajeError ?? 'No se pudo publicar la orden.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CrearOrdenBloc, CrearOrdenState>(
      listenWhen: (antes, ahora) => antes.status != ahora.status,
      listener: _alCambiarEstado,
      builder: (context, state) {
        final equipo = state.equipo;

        final pantalla = PantallaBase(
          titulo: 'Nueva Orden: Paso 2',
          tabActiva: 0,
          mostrarAtras: !state.publicando,
          conNavegacion: !state.requiereTecnico && !state.publicando,
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
                  Text('PASO 2 DE 2',
                    style: TextStyle(fontSize: 10, letterSpacing: 1,
                                     color: AppColors.textoGris.segunTema(context))),
                ],
              ),
              const SizedBox(height: 16),

              TarjetaOscura(
                icono: const CircleAvatar(radius: 20,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.build, color: Colors.white, size: 20)),
                etiqueta: 'EQUIPO SELECCIONADO',
                titulo: equipo?.nombre ?? 'Sin equipo',
                subtitulo: 'Ubicación: '
                    '${equipo == null || equipo.zonaNombre.isEmpty ? "—" : equipo.zonaNombre}',
              ),

              // ══ DATOS DE LA ORDEN (KAN-92) ══
              if (state.errorIa != null) ...[
                const SizedBox(height: 12),
                TileAviso(
                  icono: Icons.error_outline,
                  titulo: state.errorIa!,
                  color: AppColors.rojo,
                ),
              ],
              const SeccionHeader(icono: Icons.info_outline,
                titulo: 'PROGRAMACIÓN Y PRIORIDAD'),
              TarjetaBlanca(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _etiqueta('Prioridad de la Intervención',
                        state.marcadoPorIa(CampoIa.prioridad)),
                    const SizedBox(height: 4),
                    ChipsFila(
                      opciones: _prioridades,
                      colorActivo: AppColors.naranja,
                      inicial: _prioridadesModelo.indexOf(state.prioridad)
                          .clamp(0, _prioridades.length - 1),
                      onCambio: (i) => context
                          .read<CrearOrdenBloc>()
                          .add(PrioridadCambiada(_prioridadesModelo[i])),
                    ),
                    const SizedBox(height: 18),
                    Text('Fecha de Intervención', style: AppText.subtitulo.segunTema(context)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _elegirFecha(state.fechaLimite),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borde.segunTema(context)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          Icon(Icons.calendar_today_outlined, size: 17,
                            color: AppColors.textoGris.segunTema(context)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _fechaTexto(state.fechaLimite),
                              style: TextStyle(
                                fontSize: 13.5,
                                color: AppColors.texto.segunTema(context),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ══ RESPONSABLE ══
                    CampoSeleccion(
                      label: 'Técnico Responsable',
                      icono: Icons.engineering_outlined,
                      valor: switch (state.tecnico) {
                        null => null,
                        final u when u.especialidad.isEmpty => u.nombre,
                        final u => '${u.nombre} • ${u.especialidad}',
                      },
                      vacio: state.requiereTecnico
                          ? 'Selecciona un técnico'
                          : 'Sin asignar',
                      onTap: () => _elegirTecnico(state),
                    ),
                  ],
                ),
              ),

              // Convertir una novedad no pasa por la IA: el título es la
              // descripción de la novedad, como antes
              if (!state.requiereTecnico) ...[
              const SeccionHeader(icono: Icons.edit_note,
                titulo: 'DATOS DE LA ORDEN'),
              TarjetaBlanca(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _etiqueta('Título', state.marcadoPorIa(CampoIa.titulo)),
                    CampoTexto(
                      label: '',
                      hint: 'Si lo dejas vacío, se usa tu nota del paso 1',
                      controller: _tituloCtrl,
                    ),
                    const SizedBox(height: 14),
                    _etiqueta('Descripción técnica',
                        state.marcadoPorIa(CampoIa.descripcion)),
                    CampoTexto(
                      label: '',
                      hint: 'Qué falla, dónde y qué hay que revisar...',
                      lineas: 3,
                      controller: _descTecCtrl,
                    ),
                    const SizedBox(height: 14),
                    _etiqueta('Categoría', state.marcadoPorIa(CampoIa.categoria)),
                    CampoSeleccion(
                      label: '',
                      icono: Icons.label_outline,
                      valor: state.categoria.isEmpty ? null : state.categoria,
                      vacio: 'Sin categoría',
                      onTap: () => elegirCategoria(
                          context, context.read<CrearOrdenBloc>()),
                    ),
                    if (state.categoriaSugeridaIa != null)
                      _sugerenciaCategoria(state.categoriaSugeridaIa!),
                  ],
                ),
              ),
              ],

              SeccionHeader(
                icono: Icons.photo_camera_outlined,
                titulo: 'EVIDENCIA Y NOTAS',
                accion: '${state.fotos.length}/$maxFotosPorReporte · OPCIONAL',
              ),
              // Las fotos se suben al publicar, antes de crear la orden:
              // si una falla, la orden no se crea
              CuadriculaFotosLocales(
                imagenes: [for (final f in state.fotos) f.foto.bytes],
                subidas: [for (final f in state.fotos) f.subida],
                puedeAgregar: state.puedeAgregarFoto,
                bloqueada: state.publicando,
                onAgregar: _agregarFoto,
                onQuitar: (i) => context
                    .read<CrearOrdenBloc>()
                    .add(FotoHallazgoQuitada(state.fotos[i].id)),
              ),
              const SizedBox(height: 16),

              Text('Observaciones Técnicas Adicionales',
                style: AppText.subtitulo.segunTema(context)),
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
              BotonAncho(
                texto: state.progresoTexto ??
                    (state.publicando ? 'PUBLICANDO...' : 'PUBLICAR ORDEN'),
                icono: Icons.arrow_forward,
                onTap: state.paso2Valido && !state.publicando ? _publicar : null,
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
        return PopScope(
          canPop: !state.publicando,
          child: AbsorbPointer(absorbing: state.publicando, child: pantalla),
        );
      },
    );
  }
}
