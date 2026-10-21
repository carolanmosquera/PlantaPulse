// lib/src/features/reportes/ui/bloc/llenar_reporte_event.dart
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/reporte.dart';
import '../../../../core/domain/entities/usuario.dart';

sealed class LlenarReporteEvent extends Equatable {
  const LlenarReporteEvent();

  @override
  List<Object?> get props => [];
}

class DetallesCambiados extends LlenarReporteEvent {
  final String texto;

  const DetallesCambiados(this.texto);

  @override
  List<Object?> get props => [texto];
}

class EstadoTrabajoCambiado extends LlenarReporteEvent {
  final EstadoTrabajo estado;

  const EstadoTrabajoCambiado(this.estado);

  @override
  List<Object?> get props => [estado];
}

class AlertaCriticaCambiada extends LlenarReporteEvent {
  final bool activa;

  const AlertaCriticaCambiada(this.activa);

  @override
  List<Object?> get props => [activa];
}

/// Una foto de la cámara o la galería, ya comprimida por image_picker.
class FotoAgregada extends LlenarReporteEvent {
  final Uint8List bytes;
  final String extension;

  const FotoAgregada(this.bytes, this.extension);

  @override
  List<Object?> get props => [bytes.length, extension];
}

class FotoQuitada extends LlenarReporteEvent {
  final int id;

  const FotoQuitada(this.id);

  @override
  List<Object?> get props => [id];
}

/// "ENVIAR REPORTE". El autor sale de SesionBloc (usuario.ref).
class ReportePublicado extends LlenarReporteEvent {
  final UsuarioRef autor;

  const ReportePublicado(this.autor);

  @override
  List<Object?> get props => [autor.uid];
}
