// lib/src/core/components/paso_timeline.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PasoTimeline extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String hora;
  final bool completado;
  final bool esUltimo;

  const PasoTimeline({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.hora,
    this.completado = false,
    this.esUltimo = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = completado ? AppColors.verde : AppColors.gris;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Columna del círculo + línea ──
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Icon(
                  completado ? Icons.check : Icons.schedule,
                  size: 14,
                  color: color,
                ),
              ),
              if (!esUltimo)
                Expanded(
                  child: Container(width: 2, color: AppColors.borde),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // ── Texto ──
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: esUltimo ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          titulo.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: completado
                                ? AppColors.texto
                                : AppColors.textoGris,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(hora, style: const TextStyle(
                        fontSize: 11, color: AppColors.textoGris)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(subtitulo, style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textoGris)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}