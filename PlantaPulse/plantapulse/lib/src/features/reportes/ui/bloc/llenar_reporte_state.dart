// lib/src/features/reportes/ui/bloc/llenar_reporte_state.dart
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/evidencia.dart';
import '../../../../core/domain/entities/foto_pendiente.dart';
import '../../../../core/domain/entities/reporte.dart';

// FotoPendiente vive en core (también la usa crear orden)
export '../../../../core/domain/entities/foto_pendiente.dart';

enum EstadoLlenarReporte { editando, publicando, publicado, error }

class LlenarReporteState extends Equatable {
  final EstadoLlenarReporte status;
  final String detalles;
  final EstadoTrabajo estadoTrabajo;
  final bool esAlertaCritica;
  final List<FotoPendiente> fotos;

  /// Progreso de la subida: "Subiendo [subiendo] de [totalSubir]".
  final int subiendo;
  final int totalSubir;

  final String? mensajeError;

  const LlenarReporteState({
    this.status = EstadoLlenarReporte.editando,
    this.detalles = '',
    this.estadoTrabajo = EstadoTrabajo.enProgreso,
    this.esAlertaCritica = false,
    this.fotos = const [],
    this.subiendo = 0,
    this.totalSubir = 0,
    this.mensajeError,
  });

  bool get publicando => status == EstadoLlenarReporte.publicando;

  /// Como la descripción de la orden: al menos 10 caracteres. Las fotos
  /// son opcionales ("bloqueado esperando repuesto" no tiene qué fotografiar).
  bool get valido => detalles.trim().length >= 10;

  /// La base rechaza la quinta foto: la UI no deja llegar ahí.
  bool get puedeAgregarFoto =>
      fotos.length < maxFotosPorReporte && !publicando;

  String? get progresoTexto => publicando && totalSubir > 0
      ? 'Subiendo $subiendo de $totalSubir'
      : null;

  LlenarReporteState copyWith({
    EstadoLlenarReporte? status,
    String? detalles,
    EstadoTrabajo? estadoTrabajo,
    bool? esAlertaCritica,
    List<FotoPendiente>? fotos,
    int? subiendo,
    int? totalSubir,
    String? mensajeError,
    bool limpiarError = false,
  }) =>
      LlenarReporteState(
        status: status ?? this.status,
        detalles: detalles ?? this.detalles,
        estadoTrabajo: estadoTrabajo ?? this.estadoTrabajo,
        esAlertaCritica: esAlertaCritica ?? this.esAlertaCritica,
        fotos: fotos ?? this.fotos,
        subiendo: subiendo ?? this.subiendo,
        totalSubir: totalSubir ?? this.totalSubir,
        mensajeError: limpiarError ? null : (mensajeError ?? this.mensajeError),
      );

  @override
  List<Object?> get props => [
        status,
        detalles,
        estadoTrabajo,
        esAlertaCritica,
        fotos,
        subiendo,
        totalSubir,
        mensajeError,
      ];
}
