// lib/src/core/components/meta_row.dart
import 'package:flutter/material.dart';
import 'package:plantapulse/src/core/theme/app_colors.dart';

class MetaRow extends StatelessWidget {
  final IconData icono;
  final String texto;
  final String? valor; // si lo pasas, muestra etiqueta arriba y valor abajo

  const MetaRow({super.key, required this.icono, required this.texto, this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 15, color: AppColors.textoGris),
        const SizedBox(width: 8),
        Expanded(
          child: valor == null
              ? Text(texto, style: AppText.gris, overflow: TextOverflow.ellipsis)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(texto, style: AppText.gris),
                    Text(valor!, style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.texto)),
                  ],
                ),
        ),
      ],
    );
  }
}