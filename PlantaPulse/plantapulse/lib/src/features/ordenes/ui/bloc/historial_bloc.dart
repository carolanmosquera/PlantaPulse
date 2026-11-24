import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/equipo.dart';
import '../../../../core/domain/entities/orden.dart';
import '../../../../core/domain/repositories/orden_repositorio.dart';
import '../../../../core/errors/fallos.dart';
import '../../../crear_orden/domain/repositories/equipo_repositorio.dart';

sealed class HistorialEvent extends Equatable {
  const HistorialEvent();
  @override
  List<Object?> get props => [];
}

class HistorialIniciado extends HistorialEvent {
  final String plantaId;
  const HistorialIniciado(this.plantaId);
  @override
  List<Object?> get props => [plantaId];
}

class HistorialBuscado extends HistorialEvent {
  final String texto;
  final String? equipoId;
  const HistorialBuscado(this.texto, this.equipoId);
  @override
  List<Object?> get props => [texto, equipoId];
}

class HistorialSiguientePagina extends HistorialEvent {
  const HistorialSiguientePagina();
}

class HistorialState extends Equatable {
  final String plantaId;
  final String texto;
  final String? equipoId;
  final List<Equipo> equipos;
  final List<Orden> ordenes;
  final bool cargando;
  final bool cargandoEquipos;
  final bool hayMas;
  final String? error;
  final String? errorEquipos;

  const HistorialState({
    this.plantaId = '',
    this.texto = '',
    this.equipoId,
    this.equipos = const [],
    this.ordenes = const [],
    this.cargando = false,
    this.cargandoEquipos = false,
    this.hayMas = false,
    this.error,
    this.errorEquipos,
  });

  @override
  List<Object?> get props => [
    plantaId,
    texto,
    equipoId,
    equipos,
    ordenes,
    cargando,
    cargandoEquipos,
    hayMas,
    error,
    errorEquipos,
  ];
}

class HistorialBloc extends Bloc<HistorialEvent, HistorialState> {
  static const tamanoPagina = 30;
  final OrdenRepositorio _ordenes;
  final EquipoRepositorio _equipos;
  int _version = 0;
  int _desde = 0;
  bool _consultaEnCurso = false;

  HistorialBloc(this._ordenes, this._equipos) : super(const HistorialState()) {
    on<HistorialIniciado>(_iniciar);
    on<HistorialBuscado>(_buscar);
    on<HistorialSiguientePagina>(_siguiente);
  }

  Future<void> _iniciar(
    HistorialIniciado e,
    Emitter<HistorialState> emit,
  ) async {
    final version = ++_version;
    _desde = 0;
    emit(
      HistorialState(
        plantaId: e.plantaId,
        cargando: true,
        cargandoEquipos: true,
      ),
    );
    try {
      final equipos = await _equipos.conHistorial(e.plantaId);
      if (version != _version) return;
      emit(
        HistorialState(plantaId: e.plantaId, equipos: equipos, cargando: true),
      );
    } catch (error) {
      if (version != _version) return;
      emit(
        HistorialState(
          plantaId: e.plantaId,
          cargando: true,
          errorEquipos: _mensaje(error),
        ),
      );
    }
    await _cargar(emit, version);
  }

  Future<void> _buscar(HistorialBuscado e, Emitter<HistorialState> emit) async {
    final version = ++_version;
    _desde = 0;
    emit(
      HistorialState(
        plantaId: state.plantaId,
        texto: e.texto.trim(),
        equipoId: e.equipoId,
        equipos: state.equipos,
        errorEquipos: state.errorEquipos,
        cargando: true,
      ),
    );
    await _cargar(emit, version);
  }

  Future<void> _siguiente(
    HistorialSiguientePagina e,
    Emitter<HistorialState> emit,
  ) async {
    if (_consultaEnCurso || state.cargando || !state.hayMas) return;
    final version = _version;
    emit(_estado(cargando: true));
    await _cargar(emit, version, agregar: true);
  }

  Future<void> _cargar(
    Emitter<HistorialState> emit,
    int version, {
    bool agregar = false,
  }) async {
    _consultaEnCurso = true;
    try {
      final pagina = await _ordenes.buscarHistorial(
        plantaId: state.plantaId,
        texto: state.texto,
        equipoId: state.equipoId,
        desde: _desde,
        limite: tamanoPagina,
      );
      if (version != _version) return;
      _desde += pagina.length;
      emit(
        _estado(
          ordenes: agregar ? [...state.ordenes, ...pagina] : pagina,
          cargando: false,
          hayMas: pagina.length == tamanoPagina,
        ),
      );
    } catch (error) {
      if (version != _version) return;
      emit(_estado(cargando: false, error: _mensaje(error)));
    } finally {
      if (version == _version) _consultaEnCurso = false;
    }
  }

  HistorialState _estado({
    List<Orden>? ordenes,
    bool? cargando,
    bool? hayMas,
    String? error,
  }) => HistorialState(
    plantaId: state.plantaId,
    texto: state.texto,
    equipoId: state.equipoId,
    equipos: state.equipos,
    ordenes: ordenes ?? state.ordenes,
    cargando: cargando ?? state.cargando,
    hayMas: hayMas ?? state.hayMas,
    error: error,
    errorEquipos: state.errorEquipos,
  );

  static String _mensaje(Object error) =>
      error is FalloApp ? error.mensaje : 'No se pudo consultar el historial.';
}
