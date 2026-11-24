import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Temas de Material para controles, diálogos y superficies compartidas.
/// Los componentes propios conservan su diseño mediante AppColors y AppText.
class AppTheme {
  static final claro = ThemeData(
    scaffoldBackgroundColor: AppColors.fondo,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.azul),
  );

  static final oscuro = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.adaptar(
      AppColors.fondo,
      Brightness.dark,
    ),
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.azul,
          brightness: Brightness.dark,
        ).copyWith(
          surface: AppColors.adaptar(Colors.white, Brightness.dark),
          onSurface: AppColors.adaptar(AppColors.texto, Brightness.dark),
          onSurfaceVariant: AppColors.adaptar(
            AppColors.textoGris,
            Brightness.dark,
          ),
          primary: AppColors.adaptar(AppColors.azul, Brightness.dark),
        ),
  );
}
