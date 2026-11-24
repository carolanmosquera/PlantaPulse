// lib/src/features/ordenes/ui/bloc/progreso_ia_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/usecases/ia.dart';
import '../../../../core/errors/fallos.dart';
import 'progreso_ia_event.dart';
import 'progreso_ia_state.dart';

export 'progreso_ia_event.dart';
export 'progreso_ia_state.dart';

/// "Calcular progreso" del detalle de la orden. Vive con la tarjeta: al
/// salir del detalle se pierde, y es a propósito (no se guarda en la base;
/// es una sugerencia del momento).
///
/// Sin reintentos automáticos: cada cálculo gasta cuota.
class ProgresoIaBloc extends Bloc<ProgresoIaEvent, ProgresoIaState> {
  final CalcularProgreso _calcularProgreso;

  ProgresoIaBloc({required this._calcularProgreso})
      : super(const ProgresoIaState()) {
    on<ProgresoSolicitado>(_alSolicitar);
  }

  Future<void> _alSolicitar(
    ProgresoSolicitado e,
    Emitter<ProgresoIaState> emit,
  ) async {
    // Un segundo toque mientras piensa no lanza otra llamada, y sin
    // reportes no hay nada que estimar
    if (state.calculando || e.reportes.isEmpty) return;
    emit(state.copyWith(
        status: EstadoProgresoIa.calculando, limpiarError: true));
    try {
      final progreso = await _calcularProgreso.ejecutar(
          orden: e.orden, reportes: e.reportes);
      emit(state.copyWith(
        status: EstadoProgresoIa.listo,
        progreso: progreso,
        reportesAnalizados: e.reportes.length,
      ));
    } catch (err) {
      emit(state.copyWith(
        status: EstadoProgresoIa.error,
        mensajeError:
            'No se pudo calcular el progreso: ${FalloApp.mensajeDe(err)}',
      ));
    }
  }
}
