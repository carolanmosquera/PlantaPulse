// lib/src/components/pill_estado.dart
import 'package:flutter/material.dart';

class PillEstado extends StatelessWidget {
  final String texto;
  final Color color;
  final bool relleno; // true = fondo sólido (feed), false = fondo tenue

  const PillEstado({
    super.key,
    required this.texto,
    required this.color,
    this.relleno = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: relleno ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: relleno ? null : Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        texto.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: relleno ? Colors.white : color,
        ),
      ),
    );
  }
}