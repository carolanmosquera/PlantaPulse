// lib/src/components/seccion_header.dart
import 'package:flutter/material.dart';
import 'package:plantapulse/src/theme/app_colors.dart';

class SeccionHeader extends StatelessWidget {
  final IconData? icono;
  final String titulo;
  final String? accion;
  final VoidCallback? onAccion;
  final Color colorAccion;

  const SeccionHeader({
    super.key,
    this.icono,
    required this.titulo,
    this.accion,
    this.onAccion,
    this.colorAccion = AppColors.azul,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (icono != null) ...[
            Icon(icono, size: 16, color: AppColors.textoGris),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(titulo.toUpperCase(), style: AppText.label)),
          if (accion != null)
            GestureDetector(
              onTap: onAccion,
              child: Text(accion!, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: colorAccion)),
            ),
        ],
      ),
    );
  }
}