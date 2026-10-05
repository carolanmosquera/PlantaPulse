// lib/src/core/components/campo_texto.dart
import 'package:flutter/material.dart';
import 'package:plantapulse/src/core/theme/app_colors.dart';

class CampoTexto extends StatelessWidget {
  final String label;
  final String hint;
  final IconData? iconoIzq;
  final Widget? accionDerecha; // el "¿Olvidaste tu contraseña?" del login
  final bool oculto;
  final int lineas;
  final TextEditingController? controller;

  const CampoTexto({
    super.key,
    required this.label,
    required this.hint,
    this.iconoIzq,
    this.accionDerecha,
    this.oculto = false,
    this.lineas = 1,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label.toUpperCase(), style: AppText.label)),
            if (accionDerecha != null) accionDerecha!,
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: oculto,
          maxLines: oculto ? 1 : lineas,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textoGris, fontSize: 15),
            prefixIcon: iconoIzq != null
                ? Icon(iconoIzq, size: 18, color: AppColors.textoGris)
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.borde),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.borde),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.azul, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}