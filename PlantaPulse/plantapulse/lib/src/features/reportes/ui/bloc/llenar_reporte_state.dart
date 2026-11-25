// lib/src/features/reportes/ui/bloc/llenar_reporte_state.dart
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/evidencia.dart';
import '../../../../core/domain/entities/foto_pendiente.dart';
import '../../../../core/domain/entities/reporte.dart';

// FotoPendiente vive en core (también la usa crear orden)
export '../../../../core/domain/entities/foto_pendiente.dart';

/// enCola: sin conexión, el reporte quedó guardado en el teléfono y se
/// enviará solo (KAN-98). Para la pantalla es un final, como publicado.
enum EstadoLlenarReporte { editando, publicando, publicado, enCola, error }

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

  // Asistente de IA (KAN-93)
  /// Esperando al asistente: el botón se deshabilita y el campo se bloquea.
  final bool redactando;

  /// El técnico usó el asistente: se guarda generado_por_ia.
  final bool generadoPorIa;

  /// Lo que devolvió la IA, para marcar el texto mientras nadie lo cambie.
  final String? textoIa;

  /// El asistente falló: aviso, y el técnico escribe a mano.
  final String? errorIa;

  const LlenarReporteState({
    this.status = EstadoLlenarReporte.editando,
    this.detalles = '',
    this.estadoTrabajo = EstadoTrabajo.enProgreso,
    this.esAlertaCritica = false,
    this.fotos = const [],
    this.subiendo = 0,
    this.totalSubir = 0,
    this.mensajeError,
    this.redactando = false,
    this.generadoPorIa = false,
    this.textoIa,
    this.errorIa,
  });

  /// Mínimo de palabras para pedir una redacción: con el campo vacío no
  /// hay nada que redactar y se gastaría cuota.
  static const palabrasParaRedactar = 2;

  int get _palabras =>
      detalles.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).length;

  bool get puedeRedactar =>
      _palabras >= palabrasParaRedactar && !redactando && !publicando;

  /// El texto del campo es tal cual lo devolvió la IA.
  bool get textoDeIa => textoIa != null && detalles == textoIa;

  bool get publicando => status == EstadoLlenarReporte.publicando;

  /// Como la descripción de la orden: al menos 10 caracteres. Las fotos
  /// son opcionales ("bloqueado esperando repuesto" no tiene qué fotografiar).
  bool get valido => detalles.trim().length >= 10;

  /// La base rechaza la foto 31: la UI no deja llegar ahí.
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
    bool? redactando,
    bool? generadoPorIa,
    String? textoIa,
    String? errorIa,
    bool limpiarError = false,
    bool limpiarErrorIa = false,
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
        redactando: redactando ?? this.redactando,
        generadoPorIa: generadoPorIa ?? this.generadoPorIa,
        textoIa: textoIa ?? this.textoIa,
        errorIa: limpiarErrorIa ? null : (errorIa ?? this.errorIa),
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
        redactando,
        generadoPorIa,
        textoIa,
        errorIa,
      ];
}
