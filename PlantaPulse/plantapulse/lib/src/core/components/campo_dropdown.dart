// lib/src/core/components/campo_dropdown.dart
import 'package:flutter/material.dart';
import 'package:plantapulse/src/core/theme/app_colors.dart';

/// Desplegable con etiqueta arriba, genérico sobre el tipo de opción.
/// No conoce modelos de negocio: `textoDe` dice cómo mostrar cada opción.
class CampoDropdown<T> extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icono;
  final T? valor;
  final List<T> opciones;
  final String Function(T) textoDe;
  final ValueChanged<T?> onCambio;

  const CampoDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.icono,
    required this.valor,
    required this.opciones,
    required this.textoDe,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borde),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: valor,
              isExpanded: true,
              hint: Row(
                children: [
                  Icon(icono, size: 18, color: AppColors.textoGris),
                  const SizedBox(width: 10),
                  Text(hint, style: const TextStyle(
                    fontSize: 14, color: AppColors.textoGris)),
                ],
              ),
              icon: const Icon(Icons.keyboard_arrow_down,
                color: AppColors.textoGris),
              items: opciones.map((o) => DropdownMenuItem<T>(
                value: o,
                child: Row(
                  children: [
                    Icon(icono, size: 18, color: AppColors.azul),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(textoDe(o), overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14,
                                               color: AppColors.texto)),
                    ),
                  ],
                ),
              )).toList(),
              onChanged: onCambio,
            ),
          ),
        ),
      ],
    );
  }
}
