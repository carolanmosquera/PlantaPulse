// lib/src/core/components/campo_seleccion.dart
import 'package:flutter/material.dart';
import 'package:plantapulse/src/core/theme/app_colors.dart';

/// Campo con etiqueta que, al tocarlo, abre un selector (normalmente un
/// SelectorBuscable). Reemplaza al desplegable cuando la lista es larga.
class CampoSeleccion extends StatelessWidget {
  final String label;
  final IconData icono;

  /// Lo elegido. Si es null se muestra [vacio] en gris.
  final String? valor;
  final String vacio;
  final VoidCallback? onTap;

  const CampoSeleccion({
    super.key,
    required this.label,
    required this.icono,
    required this.valor,
    required this.vacio,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hayValor = valor != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label.segunTema(context)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.segunTema(context),
              border: Border.all(color: AppColors.borde.segunTema(context)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(icono, size: 18,
                  color: hayValor ? AppColors.azul.segunTema(context) : AppColors.textoGris.segunTema(context)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(valor ?? vacio,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14,
                      color: hayValor ? AppColors.texto.segunTema(context) : AppColors.textoGris.segunTema(context))),
                ),
                Icon(Icons.keyboard_arrow_down, color: AppColors.textoGris.segunTema(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
