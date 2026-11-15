// lib/src/features/reportes/ui/bloc/llenar_reporte_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/entities/evidencia.dart';
import '../../../../core/domain/entities/foto_elegida.dart';
import '../../../../core/domain/entities/reporte.dart';
import '../../../../core/domain/usecases/evidencias.dart';
import '../../../../core/domain/usecases/ia.dart';
import '../../../../core/errors/fallos.dart';
import '../../domain/usecases/reportes_casos.dart';
import 'llenar_reporte_event.dart';
import 'llenar_reporte_state.dart';

export 'llenar_reporte_event.dart';
export 'llenar_reporte_state.dart';

/// Vive mientras la pantalla de llenar reporte está abierta.
///
/// Publicar ocurre en dos fases, y el orden importa:
///   1. Subir las fotos una por una (con progreso). Cada subida da una ruta.
///   2. Insertar el reporte con las rutas ya resueltas.
/// Si falla una subida, NO se inserta nada y las fotos ya subidas conservan
/// su ruta: el reintento no las vuelve a subir.
///
/// Este Bloc no recibe nada que actualice la orden, y es a propósito: el
/// trigger al_publicar_reporte lo hace en el servidor.
class LlenarReporteBloc extends Bloc<LlenarReporteEvent, LlenarReporteState> {
  final SubirEvidencia _subirEvidencia;
  final PublicarReporte _publicarReporte;
  final RedactarReporte _redactarReporte;
  final String ordenId;
  final String plantaId;

  /// Nombre del equipo de la orden: contexto para que la IA redacte.
  final String equipo;
  int _siguienteFoto = 0;

  LlenarReporteBloc({
    required this._subirEvidencia,
    required this._publicarReporte,
    required this._redactarReporte,
    required this.ordenId,
    required this.plantaId,
    this.equipo = '',
  }) : super(const LlenarReporteState()) {
    on<DetallesRedactados>(_alRedactar);
    on<DetallesCambiados>(
        (e, emit) => emit(state.copyWith(detalles: e.texto)));
    on<EstadoTrabajoCambiado>(
        (e, emit) => emit(state.copyWith(estadoTrabajo: e.estado)));
    on<AlertaCriticaCambiada>(
        (e, emit) => emit(state.copyWith(esAlertaCritica: e.activa)));
    on<FotoAgregada>(_alAgregarFoto);
    on<FotoQuitada>(_alQuitarFoto);
    on<ReportePublicado>(_alPublicar);
  }

  /// KAN-93. El técnico firma el reporte: la IA solo le ahorra escribir.
  /// Sin reintentos automáticos; si falla, el texto se queda como estaba.
  Future<void> _alRedactar(
    DetallesRedactados e,
    Emitter<LlenarReporteState> emit,
  ) async {
    if (!state.puedeRedactar) return;      // vacío: nada que redactar
    emit(state.copyWith(redactando: true, limpiarErrorIa: true));
    try {
      final texto = await _redactarReporte.ejecutar(
          notas: state.detalles, equipo: equipo);
      emit(state.copyWith(
        redactando: false,
        detalles: texto,
        textoIa: texto,
        generadoPorIa: true,
      ));
    } catch (err) {
      emit(state.copyWith(
        redactando: false,
        errorIa: 'El asistente no pudo redactar el reporte: '
            '${FalloApp.mensajeDe(err)} Puedes escribirlo a mano.',
      ));
    }
  }

  void _alAgregarFoto(FotoAgregada e, Emitter<LlenarReporteState> emit) {
    if (!state.puedeAgregarFoto) return;        // el tope de 30 es de la base
    emit(state.copyWith(fotos: [
      ...state.fotos,
      FotoPendiente(
          id: _siguienteFoto++,
          foto: FotoElegida(bytes: e.bytes, extension: e.extension),
        ),
    ]));
  }

  /// Quitar una foto que ya se había subido (tras un fallo) deja el archivo
  /// huérfano en el bucket: no hay política para borrar evidencias.
  void _alQuitarFoto(FotoQuitada e, Emitter<LlenarReporteState> emit) {
    if (state.publicando) return;
    emit(state.copyWith(
        fotos: state.fotos.where((f) => f.id != e.id).toList()));
  }

  Future<void> _alPublicar(
    ReportePublicado e,
    Emitter<LlenarReporteState> emit,
  ) async {
    if (!state.valido || state.publicando || state.redactando) return;

    final fotos = [...state.fotos];
    final porSubir = fotos.where((f) => !f.subida).length;
    emit(state.copyWith(
      status: EstadoLlenarReporte.publicando,
      subiendo: 0,
      totalSubir: porSubir,
      limpiarError: true,
    ));

    // ── Fase 1: subir las fotos que aún no tienen ruta ──
    var hechas = 0;
    for (var i = 0; i < fotos.length; i++) {
      final foto = fotos[i];
      if (foto.subida) continue;
      emit(state.copyWith(subiendo: hechas + 1));
      try {
        final ruta = await _subirEvidencia.ejecutar(
          plantaId: plantaId,
          ordenId: ordenId,
          bytes: foto.foto.bytes,
          extension: foto.foto.extension,
        );
        fotos[i] = foto.subidaA(ruta, DateTime.now());
        hechas++;
        emit(state.copyWith(fotos: List.of(fotos)));
      } catch (err) {
        // Sin insertar: las ya subidas quedan con su ruta para el reintento
        emit(state.copyWith(
          status: EstadoLlenarReporte.error,
          fotos: List.of(fotos),
          mensajeError:
              'No se pudo subir la foto ${i + 1}. ${FalloApp.mensajeDe(err)}',
        ));
        return;
      }
    }

    // ── Fase 2: insertar el reporte con las rutas ──
    final reporte = Reporte(
      id: '',                                  // lo genera la base de datos
      ordenId: ordenId,
      autor: e.autor,
      detalles: state.detalles.trim(),
      estadoTrabajo: state.estadoTrabajo,
      evidencias: [
        for (final f in fotos)
          Evidencia(ruta: f.ruta!, subidaEn: f.subidaEn!, autorUid: e.autor.uid),
      ],
      esAlertaCritica: state.esAlertaCritica,
      generadoPorIA: state.generadoPorIa,
      createdAt: DateTime.now(),               // el trigger pone la del servidor
    );

    try {
      await _publicarReporte.ejecutar(reporte);
      emit(state.copyWith(status: EstadoLlenarReporte.publicado));
    } catch (err) {
      // Las fotos ya subidas quedan huérfanas en el bucket si el usuario
      // abandona. Es un costo aceptado (sin compensación).
      emit(state.copyWith(
        status: EstadoLlenarReporte.error,
        mensajeError: 'No se pudo publicar el reporte. ${FalloApp.mensajeDe(err)}',
      ));
    }
  }
}
