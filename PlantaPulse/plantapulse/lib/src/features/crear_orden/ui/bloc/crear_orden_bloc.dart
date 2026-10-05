// lib/src/features/crear_orden/ui/bloc/crear_orden_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/entities/orden.dart';
import '../../../../core/domain/entities/usuario.dart';
import '../../domain/usecases/crear_orden_casos.dart';
import 'crear_orden_event.dart';
import 'crear_orden_state.dart';

export 'crear_orden_event.dart';
export 'crear_orden_state.dart';

/// Vive solo mientras dura el asistente (P1 → P2): lo crea P1 y se
/// destruye al cerrarlo. Reemplaza al antiguo BorradorOrden.
class CrearOrdenBloc extends Bloc<CrearOrdenEvent, CrearOrdenState> {
  final ListarEquiposDePlanta _listarEquipos;
  final ListarTecnicosDePlanta _listarTecnicos;
  final PublicarOrden _publicarOrden;

  CrearOrdenBloc({
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
      // En paralelo: los dos selectores no dependen uno del otro
      final (equipos, tecnicos) = await (
        _listarEquipos.ejecutar(e.plantaId),
        _listarTecnicos.ejecutar(e.plantaId),
      ).wait;
      emit(state.copyWith(
        status: EstadoCrearOrden.listo,
        equipos: equipos,
        tecnicos: tecnicos,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: EstadoCrearOrden.error,
        mensajeError: 'No se pudieron cargar los equipos y técnicos.',
      ));
    }
  }

  Future<void> _alPublicar(
    OrdenPublicada e,
    Emitter<CrearOrdenState> emit,
  ) async {
    final equipo = state.equipo;
    final tecnico = state.tecnico;
    if (!state.paso2Valido || equipo == null || tecnico == null) return;

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
      // El responsable es el técnico elegido, no quien la crea
      asignadoA: UsuarioRef.desdeUsuario(tecnico),
      asignadoAUid: tecnico.uid,
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
