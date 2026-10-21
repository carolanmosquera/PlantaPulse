// lib/src/features/crear_orden/ui/bloc/crear_orden_event.dart
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/categoria.dart';
import '../../../../core/domain/entities/equipo.dart';
import '../../../../core/domain/entities/orden.dart';
import '../../../../core/domain/entities/usuario.dart';

sealed class CrearOrdenEvent extends Equatable {
  const CrearOrdenEvent();

  @override
  List<Object?> get props => [];
}

/// Lo lanza P1 al abrirse: carga categorías, equipos y técnicos de la planta.
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

/// Lleva el NOMBRE de la categoría: es lo que se guarda en la orden.
class CategoriaCambiada extends CrearOrdenEvent {
  final String categoria;

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

/// "Sin asignar" en el selector de P2.
class TecnicoQuitado extends CrearOrdenEvent {
  const TecnicoQuitado();
}

/// El formulario de alta ya guardó la categoría: se añade al catálogo
/// y queda seleccionada.
class CategoriaAgregada extends CrearOrdenEvent {
  final Categoria categoria;

  const CategoriaAgregada(this.categoria);

  @override
  List<Object?> get props => [categoria.id];
}

/// El formulario de alta ya guardó el equipo: se añade a la lista y
/// queda seleccionado, sin reabrir el asistente.
class EquipoAgregado extends CrearOrdenEvent {
  final Equipo equipo;

  const EquipoAgregado(this.equipo);

  @override
  List<Object?> get props => [equipo.id];
}

/// Una foto del hallazgo (P2), ya comprimida por image_picker.
class FotoHallazgoAgregada extends CrearOrdenEvent {
  final Uint8List bytes;
  final String extension;

  const FotoHallazgoAgregada(this.bytes, this.extension);

  @override
  List<Object?> get props => [bytes.length, extension];
}

class FotoHallazgoQuitada extends CrearOrdenEvent {
  final int id;

  const FotoHallazgoQuitada(this.id);

  @override
  List<Object?> get props => [id];
}

/// El detalle del equipo lo editó: se reemplaza en la lista (y en la
/// selección, si era el elegido).
class EquipoActualizado extends CrearOrdenEvent {
  final Equipo equipo;

  const EquipoActualizado(this.equipo);

  @override
  List<Object?> get props => [equipo.id, equipo.nombre, equipo.zonaId];
}

/// El equipo se dio de baja: sale de la lista y, si estaba elegido, se
/// quita la selección (no se puede crear una orden sobre un equipo de baja).
class EquipoDadoDeBaja extends CrearOrdenEvent {
  final String equipoId;

  const EquipoDadoDeBaja(this.equipoId);

  @override
  List<Object?> get props => [equipoId];
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
