// lib/src/core/components/meta_row.dart
import 'package:flutter/material.dart';
import 'package:plantapulse/src/core/theme/app_colors.dart';

class MetaRow extends StatelessWidget {
  final IconData icono;
  final String texto;
  final String? valor; // si lo pasas, muestra etiqueta arriba y valor abajo
  final bool atenuado; // el valor en gris: "Sin asignar" no es un nombre

  const MetaRow({super.key, required this.icono, required this.texto,
      this.valor, this.atenuado = false});

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
                    Text(valor!, style: TextStyle(
                        fontSize: 14,
                        fontWeight: atenuado ? FontWeight.w400 : FontWeight.w600,
                        color: atenuado ? AppColors.textoGris : AppColors.texto)),
                  ],
                ),
        ),
      ],
    );
  }
}