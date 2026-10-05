// lib/src/core/components/chips_fila.dart
import 'package:flutter/material.dart';
import 'package:plantapulse/src/core/theme/app_colors.dart';

class ChipsFila extends StatefulWidget {
  final List<String> opciones;
  final List<IconData>? iconos;
  final bool envolver;     // true = se acomodan en varias filas (emergencia)
  final Color colorActivo;
  final int inicial;       // chip seleccionado al construirse
  final ValueChanged<int>? onCambio;

  const ChipsFila({
    super.key,
    required this.opciones,
    this.iconos,
    this.envolver = false,
    this.colorActivo = AppColors.azul,
    this.inicial = 0,
    this.onCambio,
  });

  @override
  State<ChipsFila> createState() => _ChipsFilaState();
}

class _ChipsFilaState extends State<ChipsFila> {
  late int _sel = widget.inicial; // esto es lo único que el widget "recuerda"

  List<Widget> _construirChips() {
    return List.generate(widget.opciones.length, (i) {
      final activo = _sel == i;
      return Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: GestureDetector(
          onTap: () {
            setState(() => _sel = i);
            widget.onCambio?.call(i); // avisa a la pantalla, si le interesa
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: activo ? widget.colorActivo : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: activo ? widget.colorActivo : AppColors.borde),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.iconos != null) ...[
                  Icon(widget.iconos![i], size: 14,
                       color: activo ? Colors.white : AppColors.textoGris),
                  const SizedBox(width: 6),
                ],
                Text(widget.opciones[i], style: TextStyle(
                    fontSize: 13,
                    fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
                    color: activo ? Colors.white : AppColors.texto)),
              ],
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.envolver) {
      return Wrap(children: _construirChips());
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: _construirChips()),
    );
  }
}