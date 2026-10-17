// lib/src/core/components/hoja_formulario.dart
import 'package:flutter/material.dart';
import 'package:plantapulse/src/core/components/boton_ancho.dart';
import 'package:plantapulse/src/core/components/tile_aviso.dart';
import 'package:plantapulse/src/core/theme/app_colors.dart';

/// Marco común de los formularios de alta: hoja inferior que sube con
/// el teclado, título, contenido desplazable, error y botón de guardar.
class HojaFormulario extends StatelessWidget {
  final String titulo;
  final List<Widget> campos;
  final String? error;
  final bool guardando;
  final VoidCallback? alGuardar;

  const HojaFormulario({
    super.key,
    required this.titulo,
    required this.campos,
    required this.error,
    required this.guardando,
    required this.alGuardar,
  });

  /// Abre [hoja] como hoja inferior y devuelve lo que ella devuelva al cerrar.
  static Future<T?> mostrar<T>(BuildContext context, Widget hoja) =>
      showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.fondo,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => hoja,
      );

  @override
  Widget build(BuildContext context) {
    final medidas = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: medidas.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: medidas.size.height * 0.85),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + medidas.padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.borde,
                  borderRadius: BorderRadius.circular(2)))),
              Row(
                children: [
                  Expanded(child: Text(titulo, style: AppText.subtitulo)),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textoGris),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...campos,
              if (error != null) ...[
                TileAviso(icono: Icons.error_outline, titulo: error!,
                    color: AppColors.rojo),
                const SizedBox(height: 12),
              ],
              BotonAncho(
                texto: guardando ? 'GUARDANDO...' : 'GUARDAR',
                icono: Icons.check,
                onTap: guardando ? null : alGuardar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
