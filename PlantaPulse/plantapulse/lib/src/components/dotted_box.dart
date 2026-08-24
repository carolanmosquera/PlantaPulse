// lib/src/components/dotted_box.dart
import 'package:flutter/material.dart';
import 'package:plantapulse/src/theme/app_colors.dart';

/// Recuadro con borde punteado. Se usa como área de "Tomar Foto".
/// No necesita ningún paquete externo: el punteado se dibuja con CustomPainter.
class DottedBox extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;

  const DottedBox({
    super.key,
    required this.child,
    this.color = AppColors.borde,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      // foregroundPainter dibuja ENCIMA del child.
      // Si usaras 'painter', el fondo del Container taparía el punteado.
      foregroundPainter: _BordePunteado(color: color, radius: radius),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.fondo,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      ),
    );
  }
}

class _BordePunteado extends CustomPainter {
  final Color color;
  final double radius;

  _BordePunteado({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // 1. Creamos el contorno redondeado completo
    final contorno = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(radius),
      ));

    // 2. Lo recorremos dibujando tramos de 6px con huecos de 4px
    const largoRaya = 6.0;
    const largoHueco = 4.0;

    for (final tramo in contorno.computeMetrics()) {
      double posicion = 0;
      while (posicion < tramo.length) {
        final fin = (posicion + largoRaya).clamp(0.0, tramo.length);
        canvas.drawPath(tramo.extractPath(posicion, fin), pincel);
        posicion = fin + largoHueco;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BordePunteado anterior) =>
      anterior.color != color || anterior.radius != radius;
}