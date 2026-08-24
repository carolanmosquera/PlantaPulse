// lib/src/components/tile_aviso.dart
import 'package:flutter/material.dart';
import 'package:plantapulse/src/theme/app_colors.dart';

class TileAviso extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final Color color;

  const TileAviso({
    super.key,
    required this.icono,
    required this.titulo,
    this.subtitulo,
    this.color = AppColors.textoGris,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.texto)),
                if (subtitulo != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitulo!, style: AppText.gris),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}