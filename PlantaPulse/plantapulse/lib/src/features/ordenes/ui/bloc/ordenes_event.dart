// lib/src/features/ordenes/ui/bloc/ordenes_event.dart
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/orden.dart';

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

/// Lo lanza el buscador del feed, por tecla.
class BusquedaCambiada extends OrdenesEvent {
  final String texto;

  const BusquedaCambiada(this.texto);

  @override
  List<Object?> get props => [texto];
}

/// INTERNO: lo lanza el propio Bloc cuando el stream de Firestore responde.
/// Así los datos que llegan de afuera entran por la misma puerta que
/// los toques del usuario.
class OrdenesRecibidas extends OrdenesEvent {
  final List<Orden> ordenes;

  const OrdenesRecibidas(this.ordenes);

  @override
  List<Object?> get props => [ordenes];
}

/// INTERNO: el stream de Firestore falló (red, permisos, índice faltante).
class OrdenesFallaron extends OrdenesEvent {
  final String mensaje;

  const OrdenesFallaron(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}
