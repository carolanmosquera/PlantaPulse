// lib/src/core/components/marca_ia.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Etiqueta junto a un campo que propuso el asistente. Desaparece cuando
/// la persona lo cambia: así se ve qué propuso el modelo y qué escribió
/// la persona.
class MarcaIa extends StatelessWidget {
  final String texto;

  const MarcaIa({super.key, this.texto = 'SUGERIDO POR IA'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.naranja.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 12, color: AppColors.naranja),
          const SizedBox(width: 4),
          Text(texto,
              style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.naranja)),
        ],
      ),
    );
  }
}
