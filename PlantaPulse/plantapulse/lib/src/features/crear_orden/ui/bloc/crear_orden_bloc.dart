// lib/src/features/crear_orden/ui/bloc/crear_orden_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/entities/categoria.dart';
import '../../../../core/domain/entities/equipo.dart';
import '../../../../core/domain/entities/orden.dart';
import '../../../../core/domain/entities/usuario.dart';
import '../../../../core/domain/usecases/catalogos.dart';
import '../../domain/usecases/crear_orden_casos.dart';
import 'crear_orden_event.dart';
import 'crear_orden_state.dart';

export 'crear_orden_event.dart';
export 'crear_orden_state.dart';

/// Vive solo mientras dura el asistente (P1 → P2): lo crea P1 y se
/// destruye al cerrarlo. Reemplaza al antiguo BorradorOrden.
///
/// Las altas de categoría y equipo NO pasan por aquí: las hace su
/// formulario, que necesita el resultado en el momento para mostrar un
/// nombre o serial repetido dentro de la hoja. Al terminar, el formulario
/// avisa con CategoriaAgregada / EquipoAgregado.
class CrearOrdenBloc extends Bloc<CrearOrdenEvent, CrearOrdenState> {
  final ListarCategoriasDePlanta _listarCategorias;
  final ListarEquiposDePlanta _listarEquipos;
  final ListarTecnicosDePlanta _listarTecnicos;
  final PublicarOrden _publicarOrden;

  CrearOrdenBloc({
    required this._listarCategorias,
    required this._listarEquipos,
    required this._listarTecnicos,
    required this._publicarOrden,
  }) : super(CrearOrdenState.inicial()) {
    on<CrearOrdenIniciada>(_alIniciar);
    on<DescripcionCambiada>(
        (e, emit) => emit(state.copyWith(descripcion: e.texto)));
    on<CategoriaCambiada>(
        (e, emit) => emit(state.copyWith(categoria: e.categoria)));
    on<EquipoSeleccionado>(
        (e, emit) => emit(state.copyWith(equipo: e.equipo)));
    on<PrioridadCambiada>(
        (e, emit) => emit(state.copyWith(prioridad: e.prioridad)));
    on<FechaLimiteCambiada>(
        (e, emit) => emit(state.copyWith(fechaLimite: e.fecha)));
    on<TecnicoSeleccionado>(
        (e, emit) => emit(state.copyWith(tecnico: e.tecnico)));
    on<TecnicoQuitado>(
        (e, emit) => emit(state.copyWith(limpiarTecnico: true)));
    on<CategoriaAgregada>(_alAgregarCategoria);
    on<EquipoAgregado>(_alAgregarEquipo);
    on<ObservacionesCambiadas>(
        (e, emit) => emit(state.copyWith(observaciones: e.texto)));
    on<OrdenPublicada>(_alPublicar);
  }

  Future<void> _alIniciar(
    CrearOrdenIniciada e,
    Emitter<CrearOrdenState> emit,
  ) async {
    emit(state.copyWith(
      status: EstadoCrearOrden.cargando,
      plantaId: e.plantaId,
      limpiarError: true,
    ));
    try {
      // En paralelo: los tres catálogos no dependen uno del otro
      final (categorias, equipos, tecnicos) = await (
        _listarCategorias.ejecutar(e.plantaId),
        _listarEquipos.ejecutar(e.plantaId),
        _listarTecnicos.ejecutar(e.plantaId),
      ).wait;
      emit(state.copyWith(
        status: EstadoCrearOrden.listo,
        categorias: categorias,
        equipos: equipos,
        tecnicos: tecnicos,
        // El asistente arranca con un chip marcado, como antes
        categoria: state.categoria.isEmpty && categorias.isNotEmpty
            ? categorias.first.nombre
            : null,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: EstadoCrearOrden.error,
        mensajeError: 'No se pudieron cargar las categorías, equipos y técnicos.',
      ));
    }
  }

  void _alAgregarCategoria(CategoriaAgregada e, Emitter<CrearOrdenState> emit) {
    final lista = [
      for (final c in state.categorias)
        if (c.id != e.categoria.id) c,
      e.categoria,
    ]..sort(_porNombre<Categoria>((c) => c.nombre));
    emit(state.copyWith(categorias: lista, categoria: e.categoria.nombre));
  }

  void _alAgregarEquipo(EquipoAgregado e, Emitter<CrearOrdenState> emit) {
    final lista = [
      for (final x in state.equipos)
        if (x.id != e.equipo.id) x,
      e.equipo,
    ]..sort(_porNombre<Equipo>((x) => x.nombre));
    emit(state.copyWith(equipos: lista, equipo: e.equipo));
  }

  /// Mismo orden que trae la base (por nombre, sin distinguir mayúsculas):
  /// así lo recién creado queda donde estará al reabrir el asistente.
  static int Function(T, T) _porNombre<T>(String Function(T) nombre) =>
      (a, b) => nombre(a).toLowerCase().compareTo(nombre(b).toLowerCase());

  Future<void> _alPublicar(
    OrdenPublicada e,
    Emitter<CrearOrdenState> emit,
  ) async {
    final equipo = state.equipo;
    final tecnico = state.tecnico;      // null = la orden nace sin asignar
    if (!state.paso2Valido || equipo == null) return;

    emit(state.copyWith(status: EstadoCrearOrden.publicando, limpiarError: true));

    final ahora = DateTime.now();
    final sufijo =
        (ahora.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    final codigo = 'WO-${ahora.year}-$sufijo';
    final f = state.fechaLimite;

    final orden = Orden(
      id: '',                              // lo genera la base de datos
      codigo: codigo,
      plantaId: state.plantaId,
      titulo: state.descripcion.trim(),
      descripcion: state.observaciones.trim(),
      categoria: state.categoria,
      // La ubicación sale del equipo, no de su código
      zonaId: equipo.zonaId,
      zonaNombre: equipo.zonaNombre,
      equipoId: equipo.id,
      equipoNombre: equipo.nombre,
      creadoPor: e.creadoPor,
      // El responsable es el técnico elegido, no quien la crea.
      // Sin técnico, los dos van null: se asigna después desde el detalle.
      asignadoA: tecnico == null ? null : UsuarioRef.desdeUsuario(tecnico),
      asignadoAUid: tecnico?.uid,
      // Toda orden nace pendiente: la prioridad crítica NO es un estado
      estado: EstadoOrden.pendiente,
      prioridad: state.prioridad,
      createdAt: ahora,                    // el repositorio pone la del servidor
      fechaLimite: DateTime(f.year, f.month, f.day, 23, 59),
      ultimaActividad: ahora,
      portadaUrl: null,
      totalReportes: 0,
      totalAlertas: 0,
    );

    try {
      final id = await _publicarOrden.ejecutar(orden);
      emit(state.copyWith(
        status: EstadoCrearOrden.publicada,
        ordenIdCreada: id,
        codigoCreado: codigo,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: EstadoCrearOrden.error,
        mensajeError: 'No se pudo publicar la orden. Intenta de nuevo.',
      ));
    }
  }
}
