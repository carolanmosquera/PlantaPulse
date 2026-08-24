// lib/src/models/alerta.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum TipoAlerta { critica, preventiva, completada, info }

extension TipoAlertaX on TipoAlerta {
  IconData get icono => switch (this) {
    TipoAlerta.critica     => Icons.warning_amber_rounded,
    TipoAlerta.preventiva  => Icons.schedule,
    TipoAlerta.completada  => Icons.check_circle_outline,
    TipoAlerta.info        => Icons.info_outline,
  };

  Color get color => switch (this) {
    TipoAlerta.critica     => AppColors.rojo,
    TipoAlerta.preventiva  => AppColors.azul,
    TipoAlerta.completada  => AppColors.verde,
    TipoAlerta.info        => AppColors.textoGris,
  };
}

class Alerta {
  final TipoAlerta tipo;
  final String titulo;
  final String descripcion;
  final String hora;
  final String? codigo;
  final bool noLeida;
  final String grupo;   // 'HOY', 'AYER', 'ESTA SEMANA'

  const Alerta({
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.hora,
    this.codigo,
    this.noLeida = false,
    required this.grupo,
  });
}