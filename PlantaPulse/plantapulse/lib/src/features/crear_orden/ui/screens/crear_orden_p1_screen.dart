// lib/src/features/crear_orden/ui/screens/crear_orden_p1_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../../../novedades/domain/repositories/novedad_repositorio.dart';
import '../../domain/usecases/crear_orden_casos.dart';
import '../bloc/crear_orden_bloc.dart';
import '../widgets/alta_equipo_hoja.dart';
import '../widgets/detalle_equipo_hoja.dart';
import '../widgets/elegir_categoria.dart';
import 'crear_orden_p2_screen.dart';

/// Primer paso del asistente. Crea el CrearOrdenBloc, que vive solo
/// mientras el asistente esté abierto y se comparte con P2.
class CrearOrdenP1Screen extends StatelessWidget {
  final Novedad? novedad;

  const CrearOrdenP1Screen({super.key, this.novedad});

  @override
  Widget build(BuildContext context) {
    final plantaId = context.read<SesionBloc>().state.usuario?.plantaId ?? '';
    final origen = novedad;
    return BlocProvider<CrearOrdenBloc>(
      create: (context) => CrearOrdenBloc(
        listarCategorias: context.read<ListarCategoriasDePlanta>(),
        listarEquipos: context.read<ListarEquiposDePlanta>(),
        listarTecnicos: context.read<ListarTecnicosDePlanta>(),
        publicarOrden: context.read<PublicarOrden>(),
        nuevoIdDeOrden: context.read<NuevoIdDeOrden>(),
        subirEvidencia: context.read<SubirEvidencia>(),
        estructurarNota: context.read<EstructurarNota>(),
        descripcionInicial: origen?.descripcion ?? '',
        publicarConversion: origen == null
            ? null
            : (orden) =>
                context.read<NovedadRepositorio>().convertir(origen.id, orden),
      )..add(CrearOrdenIniciada(plantaId)),
      child: const _CrearOrdenP1Vista(),
    );
  }
}

class _CrearOrdenP1Vista extends StatefulWidget {
  const _CrearOrdenP1Vista();
  @override
  State<_CrearOrdenP1Vista> createState() => _CrearOrdenP1VistaState();
}

class _CrearOrdenP1VistaState extends State<_CrearOrdenP1Vista> {
  final _descCtrl = TextEditingController();

  // La lista de equipos se queda en una ventana de 5 filas con su propio
  // scroll: con muchos equipos ya no empuja todo lo demás hacia abajo.
  static const _altoFila = 76.0;
  static const _filasVisibles = 5;
  final _listaEquipos = ScrollController();

  @override
  void initState() {
    super.initState();
    final bloc = context.read<CrearOrdenBloc>();
    _descCtrl.text = bloc.state.descripcion;
    _descCtrl.addListener(
        () => bloc.add(DescripcionCambiada(_descCtrl.text)));
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _listaEquipos.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    final bloc = context.read<CrearOrdenBloc>();
    final ordenId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const CrearOrdenP2Screen(),
        ),
      ),
    );
    if (!mounted || ordenId == null) return;
    Navigator.pop(context, ordenId);
  }

  /// La lupa de la categoría: buscar entre todas o crear una nueva.
  Future<void> _buscarCategoria() =>
      elegirCategoria(context, context.read<CrearOrdenBloc>());

  /// KAN-92: la IA estructura la nota; al terminar (bien o mal) se navega
  /// a P2 desde el listener.
  void _estructurar() =>
      context.read<CrearOrdenBloc>().add(const NotaEstructurada());

  void _alCambiar(BuildContext context, CrearOrdenState antes,
      CrearOrdenState ahora) {
    if (antes.equipo?.id != ahora.equipo?.id) _mostrarEquipoElegido(ahora);
    // Bien o mal, se sigue a P2. Si falló, P2 muestra el error en rojo
    // arriba (un SnackBar taparía el botón de publicar) y se llena a mano.
    if (antes.estructurando && !ahora.estructurando) _continuar();
  }

  /// "BUSCAR TODOS": el selector es el "ver todos" de equipos recientes.
  Future<void> _buscarEquipo() async {
    final bloc = context.read<CrearOrdenBloc>();
    final state = bloc.state;
    final eleccion = await SelectorBuscable.mostrar<Equipo>(
      context,
      titulo: 'Equipos de la planta',
      opciones: state.equipos,
      textoDe: (e) => e.nombre,
      subtituloDe: _subtituloEquipo,     // así se busca también por serial
      iconoDe: (_) => Icons.build_outlined,
      seleccionado: state.equipo,
      claveDe: (e) => e.id,
      textoCrear: 'Registrar equipo nuevo',
      alCrear: (ctx) => AltaEquipoHoja.mostrar(ctx, plantaId: state.plantaId),
    );
    final equipo = eleccion?.valor;
    if (equipo == null) return;
    bloc.add(bloc.state.equipos.any((e) => e.id == equipo.id)
        ? EquipoSeleccionado(equipo)
        : EquipoAgregado(equipo));
  }

  static String _subtituloEquipo(Equipo e) =>
      e.serial.isEmpty ? e.zonaNombre : '${e.zonaNombre} • ${e.serial}';

  void _mostrarEquipoElegido(CrearOrdenState state) {
    final i = state.equipos.indexWhere((e) => e.id == state.equipo?.id);
    if (i < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listaEquipos.hasClients) return;
      final destino = (i * _altoFila - _altoFila)    // una fila de contexto arriba
          .clamp(0.0, _listaEquipos.position.maxScrollExtent);
      _listaEquipos.animateTo(destino,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  /// La ficha del equipo, con editar y dar de baja.
  void _verEquipo(Equipo equipo) {
    final bloc = context.read<CrearOrdenBloc>();
    DetalleEquipoHoja.mostrar(
      context,
      equipo: equipo,
      alEditar: (e) => bloc.add(EquipoActualizado(e)),
      alDarDeBaja: (id) => bloc.add(EquipoDadoDeBaja(id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // BlocConsumer no da el estado anterior al listener: se guarda aquí
    var anterior = context.read<CrearOrdenBloc>().state;
    return BlocConsumer<CrearOrdenBloc, CrearOrdenState>(
      listenWhen: (antes, ahora) {
        anterior = antes;
        return antes.equipo?.id != ahora.equipo?.id ||
            antes.estructurando != ahora.estructurando;
      },
      listener: (context, state) => _alCambiar(context, anterior, state),
      builder: (context, state) {
        final largo = state.largoDescripcion;
        final minimo = state.minimoDescripcion;
        final cargando = state.status == EstadoCrearOrden.cargando;

        return PantallaBase(
          titulo: state.requiereTecnico ? 'Convertir en orden' : 'Crear Nueva Orden',
          tabActiva: 0,
          conNavegacion: !state.requiereTecnico,
          cuerpo: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 14),

              // ══ PROGRESO ══
              Row(
                children: [
                  const PillEstado(texto: 'PASO 1 DE 2', color: AppColors.azulOscuro,
                    relleno: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: 0.5, minHeight: 4,
                        backgroundColor: AppColors.borde.segunTema(context),
                        color: AppColors.azul,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text('¿Cuál es el problema?',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold,
                                color: AppColors.texto.segunTema(context))),
              const SizedBox(height: 8),
              Text(
                'Describe el hallazgo o falla técnica. Puedes usar el dictado '
                'por voz para mayor rapidez.',
                style: TextStyle(fontSize: 13.5, color: AppColors.textoGris.segunTema(context),
                                height: 1.4)),
              const SizedBox(height: 16),

              // ══ DESCRIPCIÓN ══
              CampoTexto(
                label: '',
                hint: 'Ej: Se detectó una fuga de aceite en el sello mecánico '
                      'del motor principal, temperatura elevada...',
                lineas: 4,
                controller: _descCtrl,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 13,
                    color: largo >= minimo ? AppColors.textoGris.segunTema(context) : AppColors.rojo.segunTema(context)),
                  const SizedBox(width: 6),
                  Text('Mínimo $minimo caracteres',
                    style: TextStyle(fontSize: 11.5,
                      color: state.descripcion.isNotEmpty && largo < minimo
                          ? AppColors.rojo.segunTema(context) : AppColors.textoGris.segunTema(context))),
                  const Spacer(),
                  Container(
                    width: 42, height: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.naranja, shape: BoxShape.circle),
                    child: const Icon(Icons.mic, color: Colors.white, size: 20),
                  ),
                ],
              ),

              // ══ CATEGORÍA ══
              SeccionHeader(titulo: 'CATEGORÍA INICIAL',
                accion: 'Obligatorio',
                iconoAccion: Icons.search,
                onAccion: cargando ? null : _buscarCategoria),
              if (cargando)
                const SizedBox(height: 44)
              else if (state.categorias.isEmpty)
                TileAviso(
                  icono: Icons.label_outline,
                  titulo: 'Esta planta aún no tiene categorías',
                  subtitulo: 'Toca la lupa para crear la primera.',
                  color: AppColors.textoGris.segunTema(context),
                )
              else
                ChipsFila(
                  opciones: [for (final c in state.categorias) c.nombre],
                  iconos: [for (final c in state.categorias) iconoDeCategoria(c.icono)],
                  // indexWhere da -1 si no la encuentra: ChipsFila no marcaría nada
                  inicial: state.categorias
                      .indexWhere((c) => c.nombre == state.categoria)
                      .clamp(0, state.categorias.length - 1),
                  // Se desliza de borde a borde: se nota que hay más chips
                  sangria: 16,
                  onCambio: (i) => context
                      .read<CrearOrdenBloc>()
                      .add(CategoriaCambiada(state.categorias[i].nombre)),
                ),

              // ══ EQUIPOS ══
              SeccionHeader(
                icono: Icons.history,
                titulo: 'EQUIPOS RECIENTES',
                accion: 'BUSCAR TODOS',
                onAccion: cargando ? null : _buscarEquipo,
              ),
              if (cargando)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.equipos.isEmpty)
                TileAviso(
                  icono: Icons.precision_manufacturing_outlined,
                  titulo: state.mensajeError ??
                      'No hay equipos activos en esta planta',
                  color: state.mensajeError != null
                      ? AppColors.rojo : AppColors.textoGris.segunTema(context),
                )
              else ...[
                ConstrainedBox(
                  constraints: const BoxConstraints(
                      maxHeight: _altoFila * _filasVisibles),
                  child: Scrollbar(
                    controller: _listaEquipos,
                    thumbVisibility: state.equipos.length > _filasVisibles,
                    child: ListView.builder(
                      controller: _listaEquipos,
                      shrinkWrap: true,       // con menos de 5 no deja hueco
                      padding: EdgeInsets.zero,
                      itemCount: state.equipos.length,
                      itemBuilder: (context, i) =>
                          _equipo(state.equipos[i], state.equipo),
                    ),
                  ),
                ),
                if (state.equipos.length > _filasVisibles)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${state.equipos.length} equipos · desliza la lista o '
                      'usa BUSCAR TODOS',
                      style: AppText.gris.segunTema(context)),
                  ),
              ],

              const SizedBox(height: 20),
              if (!state.requiereTecnico) ...[
                Center(child: Text('PLANTAPULSE INDUSTRIAL CORE V3.4',
                  style: TextStyle(fontSize: 9.5, color: AppColors.textoGris.segunTema(context),
                                  letterSpacing: 1.5))),
                const SizedBox(height: 16),
              ],
              if (state.requiereTecnico)
                // Convertir una novedad: el texto ya lo escribió quien la
                // reportó, así que se sigue directo, sin asistente
                BotonAncho(
                  texto: 'Continuar',
                  icono: Icons.arrow_forward,
                  onTap: state.paso1Valido ? _continuar : null,
                )
              else ...[
                // La primera llamada puede tardar varios segundos (arranque
                // en frío): el botón se deshabilita y dice que está trabajando
                BotonAncho(
                  texto: state.estructurando
                      ? 'Estructurando...'
                      : 'Estructurar con IA',
                  icono: state.estructurando
                      ? Icons.hourglass_top
                      : Icons.auto_awesome,
                  onTap: state.paso1Valido && !state.estructurando
                      ? _estructurar
                      : null,
                ),
                if (state.estructurando) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: AppColors.borde.segunTema(context),
                    color: AppColors.naranja,
                  ),
                ],
                const SizedBox(height: 8),
                Center(child: Text(
                  'La IA propondrá título, descripción, categoría y prioridad. '
                  'Podrás corregirlos en el paso 2.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11,
                      color: AppColors.textoGris.segunTema(context)))),
                // Sin IA también se puede: no gasta cuota y sirve cuando el
                // asistente no está disponible
                Center(
                  child: TextButton(
                    onPressed: state.paso1Valido && !state.estructurando
                        ? _continuar
                        : null,
                    child: const Text('Continuar sin IA'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _equipo(Equipo equipo, Equipo? elegido) {
    final seleccionado = elegido?.id == equipo.id;
    return FilaOpcion(
      icono: Icons.build_outlined,
      titulo: equipo.nombre,
      subtitulo: _subtituloEquipo(equipo),
      color: seleccionado ? AppColors.azul : AppColors.textoGris.segunTema(context),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // La ficha del equipo: ver, editar o dar de baja
          InkWell(
            onTap: () => _verEquipo(equipo),
            customBorder: const CircleBorder(),
            child: Tooltip(
              message: 'Ver detalle del equipo',
              child: Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.info_outline, size: 20,
                    color: AppColors.textoGris.segunTema(context)),
              ),
            ),
          ),
          Icon(
            seleccionado ? Icons.check_circle : Icons.chevron_right,
            color: seleccionado ? AppColors.verde.segunTema(context) : AppColors.textoGris.segunTema(context),
            size: seleccionado ? 22 : 20,
          ),
        ],
      ),
      onTap: () =>
          context.read<CrearOrdenBloc>().add(EquipoSeleccionado(equipo)),
    );
  }
}
