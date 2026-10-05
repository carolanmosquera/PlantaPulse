// lib/src/core/components/tarjeta_oscura.dart
import 'package:flutter/material.dart';
import 'package:plantapulse/src/core/theme/app_colors.dart';

class TarjetaOscura extends StatelessWidget {
  final Widget? icono;      // avatar, círculo con check, etc.
  final String? etiqueta;   // texto pequeño superior en mayúsculas
  final String titulo;
  final String? subtitulo;
  final Widget? extra;      // un botón, una cita, lo que sea

  const TarjetaOscura({
    super.key,
    this.icono,
    this.etiqueta,
    required this.titulo,
    this.subtitulo,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.azulOscuro,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icono != null) ...[icono!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (etiqueta != null)
                      Text(etiqueta!.toUpperCase(), style: const TextStyle(
                          fontSize: 10, letterSpacing: 0.8, color: Colors.white70)),
                    Text(titulo, style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                    if (subtitulo != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitulo!, style: const TextStyle(
                          fontSize: 12, color: Colors.white70, height: 1.4)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (extra != null) ...[const SizedBox(height: 14), extra!],
        ],
      ),
    );
  }
}