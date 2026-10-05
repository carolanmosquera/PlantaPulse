// lib/src/features/crear_orden/ui/bloc/crear_orden_event.dart
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/equipo.dart';
import '../../../../core/domain/entities/orden.dart';
import '../../../../core/domain/entities/usuario.dart';

sealed class CrearOrdenEvent extends Equatable {
  const CrearOrdenEvent();

  @override
  List<Object?> get props => [];
}

/// Lo lanza P1 al abrirse: carga equipos y técnicos de la planta.
class CrearOrdenIniciada extends CrearOrdenEvent {
  final String plantaId;

  const CrearOrdenIniciada(this.plantaId);

  @override
  List<Object?> get props => [plantaId];
}

class DescripcionCambiada extends CrearOrdenEvent {
  final String texto;

  const DescripcionCambiada(this.texto);

  @override
  List<Object?> get props => [texto];
}

class CategoriaCambiada extends CrearOrdenEvent {
  final CategoriaOrden categoria;

  const CategoriaCambiada(this.categoria);

  @override
  List<Object?> get props => [categoria];
}

class EquipoSeleccionado extends CrearOrdenEvent {
  final Equipo equipo;

  const EquipoSeleccionado(this.equipo);

  @override
  List<Object?> get props => [equipo.id];
}

class PrioridadCambiada extends CrearOrdenEvent {
  final Prioridad prioridad;

  const PrioridadCambiada(this.prioridad);

  @override
  List<Object?> get props => [prioridad];
}

class FechaLimiteCambiada extends CrearOrdenEvent {
  final DateTime fecha;

  const FechaLimiteCambiada(this.fecha);

  @override
  List<Object?> get props => [fecha];
}

class TecnicoSeleccionado extends CrearOrdenEvent {
  final Usuario tecnico;

  const TecnicoSeleccionado(this.tecnico);

  @override
  List<Object?> get props => [tecnico.uid];
}

class ObservacionesCambiadas extends CrearOrdenEvent {
  final String texto;

  const ObservacionesCambiadas(this.texto);

  @override
  List<Object?> get props => [texto];
}

/// Lo lanza P2 con el botón "PUBLICAR ORDEN".
class OrdenPublicada extends CrearOrdenEvent {
  final UsuarioRef creadoPor;

  const OrdenPublicada(this.creadoPor);

  @override
  List<Object?> get props => [creadoPor.uid];
}
