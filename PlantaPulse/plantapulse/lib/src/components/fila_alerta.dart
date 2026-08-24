// lib/src/components/fila_alerta.dart
import 'package:flutter/material.dart';
import 'package:plantapulse/src/theme/app_colors.dart';
import 'package:plantapulse/src/components/pill_estado.dart';

class FilaAlerta extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final String hora;
  final String? codigo;
  final Color color;
  final bool noLeida;
  final VoidCallback? onTap;

  const FilaAlerta({
    super.key,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.hora,
    this.codigo,
    this.color = AppColors.textoGris,
    this.noLeida = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          // Borde uniforme siempre. La marca de "no leída" va dentro.
          border: Border.all(color: AppColors.borde),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Barra azul de "no leída", como Container y no como borde
                if (noLeida) Container(width: 3, color: AppColors.azul),
                Expanded(child: _contenido()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenido() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        titulo.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.texto,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(hora, style: AppText.gris),
                  ],
                ),
                const SizedBox(height: 4),
                Text(descripcion, style: AppText.gris),
                if (codigo != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      PillEstado(texto: codigo!, color: AppColors.textoGris),
                      const Spacer(),
                      const Text(
                        "VER MÁS →",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.azul,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}