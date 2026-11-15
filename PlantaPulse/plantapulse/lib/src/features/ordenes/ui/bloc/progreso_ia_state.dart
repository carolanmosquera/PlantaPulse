// lib/src/features/ordenes/ui/bloc/progreso_ia_state.dart
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/progreso_orden_ia.dart';

enum EstadoProgresoIa { inicial, calculando, listo, error }

class ProgresoIaState extends Equatable {
  final EstadoProgresoIa status;

  /// El último cálculo. Se conserva si un recálculo falla: sigue siendo
  /// la mejor estimación que hay.
  final ProgresoOrdenIa? progreso;

  /// Cuántos reportes leyó la IA en ese cálculo: si llegan más, la
  /// pantalla avisa que la estimación quedó vieja.
  final int reportesAnalizados;

  final String? mensajeError;

  const ProgresoIaState({
    this.status = EstadoProgresoIa.inicial,
    this.progreso,
    this.reportesAnalizados = 0,
    this.mensajeError,
  });

  bool get calculando => status == EstadoProgresoIa.calculando;

  ProgresoIaState copyWith({
    EstadoProgresoIa? status,
    ProgresoOrdenIa? progreso,
    int? reportesAnalizados,
    String? mensajeError,
    bool limpiarError = false,
  }) =>
      ProgresoIaState(
        status: status ?? this.status,
        progreso: progreso ?? this.progreso,
        reportesAnalizados: reportesAnalizados ?? this.reportesAnalizados,
        mensajeError: limpiarError ? null : (mensajeError ?? this.mensajeError),
      );

  @override
  List<Object?> get props => [
        status,
        progreso?.porcentaje,
        progreso?.resumen,
        progreso?.falta,
        reportesAnalizados,
        mensajeError,
      ];
}
