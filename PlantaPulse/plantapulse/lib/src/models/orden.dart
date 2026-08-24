// lib/src/models/orden.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum EstadoOrden { pendiente, enProgreso, critica, validando, completada }

extension EstadoOrdenX on EstadoOrden {
  String get etiqueta => switch (this) {
    EstadoOrden.pendiente   => 'PENDIENTE',
    EstadoOrden.enProgreso  => 'EN PROGRESO',
    EstadoOrden.critica     => 'CRÍTICA',
    EstadoOrden.validando   => 'VALIDANDO',
    EstadoOrden.completada  => 'COMPLETADA',
  };

  Color get color => switch (this) {
    EstadoOrden.pendiente   => AppColors.gris,
    EstadoOrden.enProgreso  => AppColors.ambar,
    EstadoOrden.critica     => AppColors.rojo,
    EstadoOrden.validando   => AppColors.verde,
    EstadoOrden.completada  => AppColors.verde,
  };
}

class Orden {
  final String codigo;
  final String titulo;
  final String ubicacion;
  final EstadoOrden estado;
  final String hora;
  final String prioridad;
  final String? fotoUrl;
  final String? descripcion;
  final String? asignadoA;
  final String? creadoEn;
  final List<String> fotos;
  final List<PasoActividad> actividades;
  final Equipo? equipo;

  const Orden({
    required this.codigo,
    required this.titulo,
    required this.ubicacion,
    required this.estado,
    required this.hora,
    required this.prioridad,
    this.fotoUrl,
    this.descripcion,
    this.asignadoA,
    this.creadoEn,
    this.fotos = const [],
    this.actividades = const [],
    this.equipo,
  });

}

class PasoActividad {
  final String titulo;
  final String tecnico;
  final String hora;
  final bool completado;

  const PasoActividad({
    required this.titulo,
    required this.tecnico,
    required this.hora,
    this.completado = false,
  });
}

class Equipo {
  final String nombre;
  final String serial;
  final String modelo;

  const Equipo({
    required this.nombre,
    required this.serial,
    required this.modelo,
  });
}