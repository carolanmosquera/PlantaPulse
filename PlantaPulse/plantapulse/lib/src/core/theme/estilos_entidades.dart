// lib/src/core/theme/estilos_entidades.dart
// Color e icono de cada enum del dominio. Viven aquí y no en las entidades
// porque el dominio no puede importar Flutter.
import 'package:flutter/material.dart';
import '../domain/entities/alerta.dart';
import '../domain/entities/novedad.dart';
import '../domain/entities/orden.dart';
import 'app_colors.dart';

extension EstadoOrdenEstilo on EstadoOrden {
  Color get color => switch (this) {
        EstadoOrden.pendiente  => AppColors.gris,
        EstadoOrden.enProgreso => AppColors.ambar,
        EstadoOrden.critica    => AppColors.rojo,
        EstadoOrden.validando  => AppColors.verde,
        EstadoOrden.completada => AppColors.verde,
      };
}

extension PrioridadEstilo on Prioridad {
  Color get color => switch (this) {
        Prioridad.baja    => AppColors.gris,
        Prioridad.media   => AppColors.ambar,
        Prioridad.alta    => AppColors.naranja,
        Prioridad.critica => AppColors.rojo,
      };
}

extension TipoAlertaEstilo on TipoAlerta {
  IconData get icono => switch (this) {
        TipoAlerta.critica    => Icons.warning_amber_rounded,
        TipoAlerta.preventiva => Icons.schedule,
        TipoAlerta.completada => Icons.check_circle_outline,
        TipoAlerta.info       => Icons.info_outline,
      };

  Color get color => switch (this) {
        TipoAlerta.critica    => AppColors.rojo,
        TipoAlerta.preventiva => AppColors.azul,
        TipoAlerta.completada => AppColors.verde,
        TipoAlerta.info       => AppColors.textoGris,
      };
}

extension TipoEmergenciaEstilo on TipoEmergencia {
  IconData get icono => switch (this) {
        TipoEmergencia.fuego     => Icons.local_fire_department_outlined,
        TipoEmergencia.electrico => Icons.bolt,
        TipoEmergencia.fuga      => Icons.water_drop_outlined,
        TipoEmergencia.mecanico  => Icons.build_outlined,
      };
}

extension EstadoNovedadEstilo on EstadoNovedad {
  Color get color => switch (this) {
        EstadoNovedad.reportada  => AppColors.ambar,
        EstadoNovedad.revisada   => AppColors.azul,
        EstadoNovedad.convertida => AppColors.verde,
        EstadoNovedad.descartada => AppColors.gris,
      };
}

extension CategoriaNovedadEstilo on CategoriaNovedad {
  IconData get icono => switch (this) {
        CategoriaNovedad.electrica       => Icons.lightbulb_outline,
        CategoriaNovedad.mecanica        => Icons.build_outlined,
        CategoriaNovedad.infraestructura => Icons.domain,
        CategoriaNovedad.seguridad       => Icons.health_and_safety_outlined,
        CategoriaNovedad.limpieza        => Icons.cleaning_services_outlined,
        CategoriaNovedad.otra            => Icons.chat_bubble_outline,
      };
}
