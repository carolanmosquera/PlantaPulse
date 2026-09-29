// lib/src/components/boton_ancho.dart
import 'package:flutter/material.dart';
import 'package:plantapulse/src/theme/app_colors.dart';

enum EstiloBoton { primario, borde, peligro }

class BotonAncho extends StatelessWidget {
  final String texto;
  final IconData? icono;
  final EstiloBoton estilo;
  final VoidCallback? onTap; // null = deshabilitado (gris, como en Registro)
  final Color? color;        // opcional: reemplaza el color del estilo (ej. verde)

  const BotonAncho({
    super.key,
    required this.texto,
    this.icono,
    this.estilo = EstiloBoton.primario,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final esPeligro = estilo == EstiloBoton.peligro;
    final colorBase = color ?? (esPeligro ? AppColors.rojo : AppColors.azul);
    final relleno   = estilo != EstiloBoton.borde;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: relleno
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: icono != null ? Icon(icono, size: 18) : const SizedBox.shrink(),
              label: Text(texto),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorBase,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.gris,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: icono != null ? Icon(icono, size: 18) : const SizedBox.shrink(),
              label: Text(texto),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorBase,
                side: BorderSide(color: colorBase),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
    );
  }
}