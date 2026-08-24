import 'package:flutter/material.dart';
import 'package:plantapulse/src/theme/app_colors.dart';
// lib/src/components/stat_card.dart
class StatCard extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;
  final String? nota;
  final Color color;

  const StatCard({
    super.key,
    required this.icono,
    required this.valor,
    required this.etiqueta,
    this.nota,
    this.color = AppColors.textoGris,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color == AppColors.textoGris ? Colors.white : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(etiqueta.toUpperCase(), style: AppText.label)),
              Icon(icono, size: 15, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(valor, style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w700,
              color: color == AppColors.textoGris ? AppColors.texto : color)),
          if (nota != null) Text(nota!, style: const TextStyle(
              fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textoGris)),
        ],
      ),
    );
  }
}