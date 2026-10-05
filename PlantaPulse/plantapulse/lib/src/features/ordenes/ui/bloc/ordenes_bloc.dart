// lib/src/features/ordenes/ui/bloc/ordenes_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/entities/orden.dart';
import '../../../../core/errors/fallos.dart';
import '../../domain/usecases/observar_ordenes.dart';
import 'ordenes_event.dart';
import 'ordenes_state.dart';

export 'ordenes_event.dart';
export 'ordenes_state.dart';

/// Mantiene viva UNA suscripción a la base de datos (feed o mis tareas) y
/// convierte cada emisión del stream en un evento interno.
class OrdenesBloc extends Bloc<OrdenesEvent, OrdenesState> {
  final ObservarOrdenesDePlanta _observarOrdenesDePlanta;
  final ObservarMisTareas _observarMisTareas;
  StreamSubscription<List<Orden>>? _suscripcion;

  OrdenesBloc({
    required this._observarOrdenesDePlanta,
    required this._observarMisTareas,
  }) : super(const OrdenesState()) {
    on<OrdenesSuscritas>((e, emit) => _suscribir(
        emit, () => _observarOrdenesDePlanta.ejecutar(e.plantaId)));
    on<MisTareasSuscritas>((e, emit) => _suscribir(
        emit,
        () => _observarMisTareas.ejecutar(uid: e.uid, plantaId: e.plantaId)));
    on<OrdenesRecibidas>(_alRecibir);
    on<OrdenesFallaron>(_alFallar);
    on<FiltroCambiado>(
        (e, emit) => emit(state.copyWith(filtro: e.indice)));
    on<BusquedaCambiada>(
        (e, emit) => emit(state.copyWith(busqueda: e.texto)));
  }

  /// Feed y mis tareas comparten este Bloc. Al cambiar de consulta se
  /// vacía la lista: si no, mis tareas mostraría un instante las órdenes
  /// de toda la planta que dejó el feed (y al revés).
  ///
  /// Es síncrono a propósito: la cancelación no se espera, así ninguna
  /// emisión de la consulta vieja se cuela entre cancelar y suscribir.
  void _suscribir(
    Emitter<OrdenesState> emit,
    Stream<List<Orden>> Function() consulta,
  ) {
    final anterior = _suscripcion;
    if (anterior != null) unawaited(anterior.cancel());
    emit(state.copyWith(
      status: EstadoOrdenes.cargando,
      ordenes: const [],
      limpiarError: true,
    ));
    _suscripcion = consulta().listen(
      (lista) => add(OrdenesRecibidas(lista)),
      onError: (Object e) => add(OrdenesFallaron(_mensajeDe(e))),
    );
  }

  void _alRecibir(OrdenesRecibidas e, Emitter<OrdenesState> emit) {
    emit(state.copyWith(
      status: EstadoOrdenes.listo,
      ordenes: e.ordenes,
      limpiarError: true,
    ));
  }

  /// `ordenes` NO se toca: lo que el usuario ya veía no se borra por
  /// un fallo de red.
  void _alFallar(OrdenesFallaron e, Emitter<OrdenesState> emit) {
    emit(state.copyWith(status: EstadoOrdenes.error, mensajeError: e.mensaje));
  }

  /// El repositorio ya traduce los errores del SDK a FalloApp con el
  /// mensaje adecuado (permisos, índice, sin conexión).
  static String _mensajeDe(Object e) =>
      e is FalloApp ? e.mensaje : 'No se pudieron actualizar las órdenes.';

  /// Sin esto la suscripción sigue viva después de destruir el Bloc:
  /// fuga de memoria y lecturas de la base de datos que nadie usa.
  @override
  Future<void> close() async {
    await _suscripcion?.cancel();
    _suscripcion = null;
    return super.close();
  }
}
