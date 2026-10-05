// lib/src/core/components/grid_fotos.dart
import 'package:flutter/material.dart';
import 'package:plantapulse/src/core/theme/app_colors.dart';
import 'package:plantapulse/src/core/components/dotted_box.dart';

class GridFotos extends StatelessWidget {
  final List<String> urls;
  final int columnas;
  final bool permiteAgregar;
  final bool permiteEliminar;
  final VoidCallback? onAgregar;
  final void Function(int indice)? onEliminar;

  const GridFotos({
    super.key,
    required this.urls,
    this.columnas = 3,
    this.permiteAgregar = true,
    this.permiteEliminar = true,
    this.onAgregar,
    this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: columnas,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true, // obligatorio dentro de un scroll
      physics: const NeverScrollableScrollPhysics(), // obligatorio dentro de un scroll
      children: [
        // asMap().entries nos da el índice además del valor,
        // para poder avisar cuál foto se eliminó.
        ...urls.asMap().entries.map((entrada) {
          final indice = entrada.key;
          final url = entrada.value;

          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.borde,
                    child: const Icon(Icons.broken_image_outlined,
                        color: Colors.white),
                  ),
                ),
              ),
              if (permiteEliminar)
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => onEliminar?.call(indice),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
            ],
          );
        }),

        if (permiteAgregar)
          GestureDetector(
            onTap: onAgregar,
            child: const DottedBox(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, color: AppColors.textoGris),
                  SizedBox(height: 4),
                  Text("Tomar Foto", style: AppText.gris),
                ],
              ),
            ),
          ),
      ],
    );
  }
}