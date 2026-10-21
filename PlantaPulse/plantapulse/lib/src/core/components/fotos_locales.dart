// lib/src/core/components/fotos_locales.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plantapulse/src/core/components/dotted_box.dart';
import 'package:plantapulse/src/core/theme/app_colors.dart';

/// Pregunta "Tomar foto" / "Elegir de la galería" y devuelve la foto ya
/// comprimida, o null si se canceló.
///
/// maxWidth e imageQuality comprimen dentro del propio image_picker: una
/// foto de varios MB baja a unos cientos de KB, lejos del límite de 5 MB.
Future<({Uint8List bytes, String extension})?> elegirFoto(
    BuildContext context) async {
  final fuente = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Elegir de la galería'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (fuente == null) return null;

  final XFile? foto = await ImagePicker().pickImage(
    source: fuente,
    maxWidth: 1600,
    imageQuality: 80,
  );
  if (foto == null) return null;
  final bytes = await foto.readAsBytes();
  final extension =
      foto.name.contains('.') ? foto.name.split('.').last : 'jpg';
  return (bytes: bytes, extension: extension);
}

/// Cuadrícula de fotos tomadas en el teléfono (aún en memoria), con la X
/// para quitarlas y el recuadro de agregar, que desaparece al llegar al
/// tope. Genérica: no sabe qué es un reporte ni una orden.
class CuadriculaFotosLocales extends StatelessWidget {
  final List<Uint8List> imagenes;

  /// Marca la foto como ya subida (nube con check). Mismo largo que [imagenes].
  final List<bool> subidas;
  final bool puedeAgregar;
  final bool bloqueada;          // durante la subida no se quita ni se agrega
  final VoidCallback onAgregar;
  final ValueChanged<int> onQuitar;

  const CuadriculaFotosLocales({
    super.key,
    required this.imagenes,
    required this.subidas,
    required this.puedeAgregar,
    required this.onAgregar,
    required this.onQuitar,
    this.bloqueada = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,                              // dentro de un scroll
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < imagenes.length; i++)
          Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(imagenes[i], fit: BoxFit.cover),
              ),
              if (subidas[i])
                const Positioned(
                  left: 4, bottom: 4,
                  child: Icon(Icons.cloud_done, size: 18, color: Colors.white,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)]),
                ),
              if (!bloqueada)
                Positioned(
                  top: 4, right: 4,
                  child: GestureDetector(
                    onTap: () => onQuitar(i),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 14,
                          color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        if (puedeAgregar && !bloqueada)
          GestureDetector(
            onTap: onAgregar,
            child: const DottedBox(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, color: AppColors.textoGris),
                  SizedBox(height: 4),
                  Text('Agregar foto', style: AppText.gris),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
