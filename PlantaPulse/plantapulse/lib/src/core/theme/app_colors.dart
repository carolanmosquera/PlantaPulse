import 'package:flutter/material.dart';

class AppColors {
  static const azul       = Color(0xFF1B4965); // primario
  static const azulOscuro = Color(0xFF132F44); // tarjetas oscuras
  static const naranja    = Color(0xFFF4802F); // acento, FAB
  static const fondo      = Color(0xFFF6F7F9);
  static const borde      = Color(0xFFE0E4E8);
  static const texto      = Color(0xFF1D1F23);
  static const textoGris  = Color(0xFF595C61);

  static const rojo   = Color(0xFFD64545); // crítico
  static const ambar  = Color(0xFFE8A317); // en progreso
  static const verde  = Color(0xFF2E9E6B); // resuelto
  static const gris   = Color(0xFF8A96A3); // pendiente
}

class AppText {
  static const titulo    = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.texto);
  static const subtitulo = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.texto);
  static const cuerpo    = TextStyle(fontSize: 14, color: AppColors.texto);
  static const gris      = TextStyle(fontSize: 12, color: AppColors.textoGris);
  // Etiquetas en MAYÚSCULAS con espaciado, como en el diseño de Visily
  static const label     = TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                     color: AppColors.textoGris, letterSpacing: 0.8);
}