// lib/src/features/ordenes/ui/bloc/ordenes_event.dart
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/orden.dart';
import '../../../../core/domain/entities/usuario.dart';

sealed class OrdenesEvent extends Equatable {
  const OrdenesEvent();

  @override
  List<Object?> get props => [];
}

/// Lo lanza el feed al abrirse: todas las órdenes de la planta.
class OrdenesSuscritas extends OrdenesEvent {
  final String plantaId;

  const OrdenesSuscritas(this.plantaId);

  @override
  List<Object?> get props => [plantaId];
}

/// Lo lanza "Mis Tareas" al abrirse: solo las asignadas a ese usuario.
class MisTareasSuscritas extends OrdenesEvent {
  final String plantaId;
  final String uid;

  const MisTareasSuscritas({required this.plantaId, required this.uid});

  @override
  List<Object?> get props => [plantaId, uid];
}

/// Lo lanzan los chips del feed.
class FiltroCambiado extends OrdenesEvent {
  final int indice;

  const FiltroCambiado(this.indice);

  @override
  List<Object?> get props => [indice];
}

/// Lo lanza "Editar orden" del detalle. Equipo y zona no se editan.
class OrdenEditada extends OrdenesEvent {
  final String ordenId;
  final String titulo;
  final String descripcion;
  final String categoria;
  final Prioridad prioridad;
  final DateTime fechaLimite;

  const OrdenEditada({
    required this.ordenId,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    required this.prioridad,
    required this.fechaLimite,
  });

  @override
  List<Object?> get props =>
      [ordenId, titulo, descripcion, categoria, prioridad, fechaLimite];
}

/// Lo lanza "Asignar técnico" del detalle. Con null, desasigna.
class TecnicoAsignado extends OrdenesEvent {
  final String ordenId;
  final Usuario? tecnico;

  const TecnicoAsignado(this.ordenId, this.tecnico);

  @override
  List<Object?> get props => [ordenId, tecnico?.uid];
}

/// Lo lanza el buscador del feed, por tecla.
class BusquedaCambiada extends OrdenesEvent {
  final String texto;

  const BusquedaCambiada(this.texto);

  @override
  List<Object?> get props => [texto];
}

/// INTERNO: lo lanza el propio Bloc cuando el stream en tiempo real responde.
/// Así los datos que llegan de afuera entran por la misma puerta que
/// los toques del usuario.
class OrdenesRecibidas extends OrdenesEvent {
  final List<Orden> ordenes;

  const OrdenesRecibidas(this.ordenes);

  @override
  List<Object?> get props => [ordenes];
}

/// INTERNO: el stream en tiempo real falló (red, permisos).
class OrdenesFallaron extends OrdenesEvent {
  final String mensaje;

  const OrdenesFallaron(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}
