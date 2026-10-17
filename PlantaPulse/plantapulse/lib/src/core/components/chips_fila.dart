// lib/src/core/components/chips_fila.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:plantapulse/src/core/theme/app_colors.dart';

class ChipsFila extends StatefulWidget {
  final List<String> opciones;
  final List<IconData>? iconos;
  final bool envolver;     // true = se acomodan en varias filas (emergencia)
  final Color colorActivo;
  final int inicial;       // chip seleccionado; si cambia, la fila lo sigue
  final ValueChanged<int>? onCambio;

  /// Margen lateral de la pantalla que la fila recupera al desplazarse.
  /// Con 16 (el padding de las pantallas) los chips se deslizan de borde
  /// a borde y se nota que hay más; el primero y el último conservan
  /// esos 16 de aire. Con 0 la fila se queda dentro del padding.
  final double sangria;

  const ChipsFila({
    super.key,
    required this.opciones,
    this.iconos,
    this.envolver = false,
    this.colorActivo = AppColors.azul,
    this.inicial = 0,
    this.onCambio,
    this.sangria = 0,
  });

  @override
  State<ChipsFila> createState() => _ChipsFilaState();
}

class _ChipsFilaState extends State<ChipsFila> {
  late int _sel = widget.inicial; // esto es lo único que el widget "recuerda"
  final _scroll = ScrollController();
  List<GlobalKey> _llaves = [];

  @override
  void didUpdateWidget(ChipsFila anterior) {
    super.didUpdateWidget(anterior);
    // La selección puede cambiar desde fuera (llegó el catálogo, se creó
    // una categoría): sin esto el chip marcado se quedaría en el viejo.
    if (anterior.inicial != widget.inicial && widget.inicial != _sel) {
      _sel = widget.inicial;
      WidgetsBinding.instance.addPostFrameCallback((_) => _mostrarSeleccionado());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Desplaza SOLO la fila hasta el chip marcado. Scrollable.ensureVisible
  /// movería también la pantalla vertical, y no se quiere eso.
  void _mostrarSeleccionado() {
    if (!mounted || !_scroll.hasClients || _sel < 0 || _sel >= _llaves.length) {
      return;
    }
    final chip = _llaves[_sel].currentContext?.findRenderObject();
    if (chip == null) return;
    final destino = RenderAbstractViewport.of(chip)
        .getOffsetToReveal(chip, 0.5)
        .offset
        .clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(destino,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  List<Widget> _construirChips() {
    if (_llaves.length != widget.opciones.length) {
      _llaves = List.generate(widget.opciones.length, (_) => GlobalKey());
    }
    return List.generate(widget.opciones.length, (i) {
      final activo = _sel == i;
      return Padding(
        key: _llaves[i],
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
    // Los chips tienen tamaño intrínseco (nada de Expanded/Flexible):
    // dentro de un scroll horizontal el ancho no está acotado.
    final fila = SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: widget.sangria),
      child: Row(children: _construirChips()),
    );
    if (widget.sangria <= 0) return fila;

    // La fila es más ancha que el hueco que le da la pantalla y se centra
    // sobre él: así cubre también el padding lateral.
    return LayoutBuilder(
      builder: (context, c) => OverflowBox(
        fit: OverflowBoxFit.deferToChild,
        minWidth: c.maxWidth + 2 * widget.sangria,
        maxWidth: c.maxWidth + 2 * widget.sangria,
        child: fila,
      ),
    );
  }
}
