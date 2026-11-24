// lib/src/features/ordenes/ui/bloc/progreso_ia_event.dart
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/orden.dart';
import '../../../../core/domain/entities/reporte.dart';

sealed class ProgresoIaEvent extends Equatable {
  const ProgresoIaEvent();

  @override
  List<Object?> get props => [];
}

/// "CALCULAR PROGRESO" (o "Recalcular"): la orden y los reportes que el
/// supervisor está viendo en ese momento.
class ProgresoSolicitado extends ProgresoIaEvent {
  final Orden orden;
  final List<Reporte> reportes;

  const ProgresoSolicitado({required this.orden, required this.reportes});

  @override
  List<Object?> get props => [orden.id, reportes.length];
}
