// lib/src/core/components/fotos.dart
import 'package:flutter/material.dart';
import 'package:plantapulse/src/core/theme/app_colors.dart';

/// Foto de la red que nunca rompe la pantalla: muestra un cargador
/// mientras baja y un recuadro gris si no carga.
class FotoRed extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double radio;

  const FotoRed({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.radio = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: Image.network(
        url,
        fit: fit,
        loadingBuilder: (context, hijo, progreso) => progreso == null
            ? hijo
            : Container(
                color: AppColors.borde,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
        errorBuilder: (_, _, _) => Container(
          color: AppColors.borde,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined,
              color: AppColors.textoGris),
        ),
      ),
    );
  }
}

/// Cuadrícula de fotos de la red. Tocar una la abre a pantalla completa.
class GaleriaFotos extends StatelessWidget {
  final List<String> urls;
  final int columnas;

  const GaleriaFotos({super.key, required this.urls, this.columnas = 3});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: columnas,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,                               // dentro de un scroll
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < urls.length; i++)
          GestureDetector(
            onTap: () => VisorFoto.abrir(context, urls, inicial: i),
            child: FotoRed(url: urls[i]),
          ),
      ],
    );
  }
}

/// Pantalla completa con zoom (pellizcar) y deslizar entre fotos.
class VisorFoto extends StatelessWidget {
  final List<String> urls;
  final int inicial;

  const VisorFoto({super.key, required this.urls, this.inicial = 0});

  static Future<void> abrir(BuildContext context, List<String> urls,
          {int inicial = 0}) =>
      Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => VisorFoto(urls: urls, inicial: inicial),
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: inicial),
        itemCount: urls.length,
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Center(
            child: FotoRed(url: urls[i], fit: BoxFit.contain, radio: 0),
          ),
        ),
      ),
    );
  }
}
