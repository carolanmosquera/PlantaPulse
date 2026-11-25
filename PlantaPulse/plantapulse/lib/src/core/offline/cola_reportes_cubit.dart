// lib/src/core/offline/cola_reportes_cubit.dart
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/usecases/cola_reportes.dart';

class ColaReportesEstado extends Equatable {
  /// Reportes guardados en el teléfono que esperan conexión.
  final int pendientes;
  final bool sincronizando;

  /// Resultado del último intento que envió o rechazó algo. [revision]
  /// cambia con cada uno, para avisar una sola vez.
  final int enviados;
  final List<String> rechazados;
  final int revision;

  const ColaReportesEstado({
    this.pendientes = 0,
    this.sincronizando = false,
    this.enviados = 0,
    this.rechazados = const [],
    this.revision = 0,
  });

  ColaReportesEstado copyWith({
    int? pendientes,
    bool? sincronizando,
    int? enviados,
    List<String>? rechazados,
    int? revision,
  }) =>
      ColaReportesEstado(
        pendientes: pendientes ?? this.pendientes,
        sincronizando: sincronizando ?? this.sincronizando,
        enviados: enviados ?? this.enviados,
        rechazados: rechazados ?? this.rechazados,
        revision: revision ?? this.revision,
      );

  @override
  List<Object?> get props =>
      [pendientes, sincronizando, enviados, rechazados, revision];
}

/// KAN-98: mientras hay sesión, reintenta enviar los reportes guardados
/// sin conexión cada [intervalo], y al pedirlo ("Reintentar"). No depende
/// de detectar la red: intenta, y si sigue sin conexión, espera al
/// siguiente turno. Ningún error de aquí rompe la app.
class ColaReportesCubit extends Cubit<ColaReportesEstado> {
  final SincronizarReportesPendientes _sincronizar;
  final ContarReportesPendientes _contar;
  final Duration intervalo;
  Timer? _temporizador;
  String? _uid;

  ColaReportesCubit({
    required this._sincronizar,
    required this._contar,
    this.intervalo = const Duration(seconds: 30),
  }) : super(const ColaReportesEstado());

  /// Al iniciar sesión: cuenta lo guardado e intenta enviarlo.
  void iniciar(String uid) {
    if (_uid == uid) return;
    detener();
    _uid = uid;
    _temporizador = Timer.periodic(intervalo, (_) => sincronizar());
    sincronizar();
  }

  /// Al cerrar sesión: los reportes de esa cuenta no se envían con otra.
  void detener() {
    _temporizador?.cancel();
    _temporizador = null;
    _uid = null;
    if (!isClosed) emit(const ColaReportesEstado());
  }

  /// Un reporte acaba de quedar en cola: actualizar el aviso.
  Future<void> refrescar() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final n = await _contar.ejecutar(uid);
      if (!isClosed && uid == _uid) emit(state.copyWith(pendientes: n));
    } catch (_) {/* sin aviso, sin romper nada */}
  }

  Future<void> sincronizar() async {
    final uid = _uid;
    if (uid == null || state.sincronizando || isClosed) return;
    try {
      // Sin pendientes no se llama al servidor
      final n = await _contar.ejecutar(uid);
      if (isClosed || uid != _uid) return;
      if (n == 0) {
        if (state.pendientes != 0) emit(state.copyWith(pendientes: 0));
        return;
      }
      emit(state.copyWith(pendientes: n, sincronizando: true));
      final r = await _sincronizar.ejecutar(uid);
      if (isClosed || uid != _uid) return;
      final hubo = r.enviados > 0 || r.rechazados.isNotEmpty;
      emit(state.copyWith(
        pendientes: r.pendientes,
        sincronizando: false,
        enviados: hubo ? r.enviados : null,
        rechazados: hubo ? r.rechazados : null,
        revision: hubo ? state.revision + 1 : null,
      ));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(sincronizando: false));
    }
  }

  @override
  Future<void> close() {
    _temporizador?.cancel();
    return super.close();
  }
}
