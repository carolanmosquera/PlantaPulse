// lib/src/core/components/fila_opcion.dart
import 'package:flutter/material.dart';
import 'package:plantapulse/src/core/theme/app_colors.dart';

class FilaOpcion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final Color color;
  final Widget? trailing; // por defecto un chevron; puedes pasar un Switch
  final VoidCallback? onTap;

  const FilaOpcion({
    super.key,
    required this.icono,
    required this.titulo,
    this.subtitulo,
    this.color = AppColors.azul,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borde),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icono, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: color)),
                  if (subtitulo != null) Text(subtitulo!, style: AppText.gris),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right, size: 20, color: AppColors.textoGris),
          ],
        ),
      ),
    );
  }
}