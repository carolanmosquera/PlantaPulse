// lib/src/features/crear_orden/ui/screens/crear_orden_p1_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../../domain/usecases/crear_orden_casos.dart';
import '../bloc/crear_orden_bloc.dart';
import '../widgets/alta_categoria_hoja.dart';
import '../widgets/alta_equipo_hoja.dart';
import '../widgets/detalle_equipo_hoja.dart';
import 'crear_orden_p2_screen.dart';

/// Primer paso del asistente. Crea el CrearOrdenBloc, que vive solo
/// mientras el asistente esté abierto y se comparte con P2.
class CrearOrdenP1Screen extends StatelessWidget {
  const CrearOrdenP1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final plantaId = context.read<SesionBloc>().state.usuario?.plantaId ?? '';
    return BlocProvider<CrearOrdenBloc>(
      create: (context) => CrearOrdenBloc(
        listarCategorias: context.read<ListarCategoriasDePlanta>(),
        listarEquipos: context.read<ListarEquiposDePlanta>(),
        listarTecnicos: context.read<ListarTecnicosDePlanta>(),
        publicarOrden: context.read<PublicarOrden>(),
        nuevoIdDeOrden: context.read<NuevoIdDeOrden>(),
        subirEvidencia: context.read<SubirEvidencia>(),
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
    _descCtrl.addListener(
        () => bloc.add(DescripcionCambiada(_descCtrl.text)));
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _listaEquipos.dispose();
    super.dispose();
  }

  void _continuar() {
    final bloc = context.read<CrearOrdenBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const CrearOrdenP2Screen(),
        ),
      ),
    );
  }

  /// La lupa de la categoría: buscar entre todas o crear una nueva.
  Future<void> _buscarCategoria() async {
    final bloc = context.read<CrearOrdenBloc>();
    final usuario = context.read<SesionBloc>().state.usuario;
    final state = bloc.state;
    final eleccion = await SelectorBuscable.mostrar<Categoria>(
      context,
      titulo: 'Categoría',
      opciones: state.categorias,
      textoDe: (c) => c.nombre,
      iconoDe: (c) => iconoDeCategoria(c.icono),
      seleccionado:
          state.categorias.where((c) => c.nombre == state.categoria).firstOrNull,
      claveDe: (c) => c.id,
      textoCrear: usuario == null ? null : 'Crear categoría',
      alCrear: usuario == null
          ? null
          : (ctx) => AltaCategoriaHoja.mostrar(ctx,
              plantaId: state.plantaId, creadaPor: usuario.ref),
    );
    final categoria = eleccion?.valor;
    if (categoria == null) return;
    // Una recién creada aún no está en el catálogo: se añade y se marca
    bloc.add(bloc.state.categorias.any((c) => c.id == categoria.id)
        ? CategoriaCambiada(categoria.nombre)
        : CategoriaAgregada(categoria));
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
    return BlocConsumer<CrearOrdenBloc, CrearOrdenState>(
      listenWhen: (antes, ahora) => antes.equipo?.id != ahora.equipo?.id,
      listener: (context, state) => _mostrarEquipoElegido(state),
      builder: (context, state) {
        final largo = state.descripcion.trim().length;
        final cargando = state.status == EstadoCrearOrden.cargando;

        return PantallaBase(
          titulo: 'Crear Nueva Orden',
          tabActiva: 0,
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
                      child: const LinearProgressIndicator(
                        value: 0.5, minHeight: 4,
                        backgroundColor: AppColors.borde,
                        color: AppColors.azul,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text('¿Cuál es el problema?',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold,
                                color: AppColors.texto)),
              const SizedBox(height: 8),
              const Text(
                'Describe el hallazgo o falla técnica. Puedes usar el dictado '
                'por voz para mayor rapidez.',
                style: TextStyle(fontSize: 13.5, color: AppColors.textoGris,
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
                    color: largo >= 10 ? AppColors.textoGris : AppColors.rojo),
                  const SizedBox(width: 6),
                  Text('Mínimo 10 caracteres',
                    style: TextStyle(fontSize: 11.5,
                      color: state.descripcion.isNotEmpty && largo < 10
                          ? AppColors.rojo : AppColors.textoGris)),
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
                const TileAviso(
                  icono: Icons.label_outline,
                  titulo: 'Esta planta aún no tiene categorías',
                  subtitulo: 'Toca la lupa para crear la primera.',
                  color: AppColors.textoGris,
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
                      ? AppColors.rojo : AppColors.textoGris,
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
                      style: AppText.gris),
                  ),
              ],

              const SizedBox(height: 20),
              const Center(child: Text('PLANTAPULSE INDUSTRIAL CORE V3.4',
                style: TextStyle(fontSize: 9.5, color: AppColors.textoGris,
                                letterSpacing: 1.5))),
              const SizedBox(height: 16),

              // La IA es otra tajada: por ahora solo avanza a P2
              BotonAncho(
                texto: 'Estructurar con IA',
                icono: Icons.auto_awesome,
                onTap: state.paso1Valido ? _continuar : null,
              ),
              const SizedBox(height: 8),
              const Center(child: Text(
                'La IA analizará tu reporte para sugerir equipo, prioridad y tags.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textoGris))),
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
      color: seleccionado ? AppColors.azul : AppColors.textoGris,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // La ficha del equipo: ver, editar o dar de baja
          InkWell(
            onTap: () => _verEquipo(equipo),
            customBorder: const CircleBorder(),
            child: Tooltip(
              message: 'Ver detalle del equipo',
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.info_outline, size: 20,
                    color: AppColors.textoGris),
              ),
            ),
          ),
          Icon(
            seleccionado ? Icons.check_circle : Icons.chevron_right,
            color: seleccionado ? AppColors.verde : AppColors.textoGris,
            size: seleccionado ? 22 : 20,
          ),
        ],
      ),
      onTap: () =>
          context.read<CrearOrdenBloc>().add(EquipoSeleccionado(equipo)),
    );
  }
}
