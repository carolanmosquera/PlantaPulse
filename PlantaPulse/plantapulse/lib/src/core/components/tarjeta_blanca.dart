// lib/src/core/components/tarjeta_blanca.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TarjetaBlanca extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? colorFondo;

  const TarjetaBlanca({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.colorFondo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colorFondo ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borde),
      ),
      child: child,
    );
  }
}