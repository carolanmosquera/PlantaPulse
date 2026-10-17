// lib/src/core/components/selector_buscable.dart
import 'package:flutter/material.dart';
import 'package:plantapulse/src/core/components/boton_ancho.dart';
import 'package:plantapulse/src/core/components/campo_texto.dart';
import 'package:plantapulse/src/core/components/fila_opcion.dart';
import 'package:plantapulse/src/core/theme/app_colors.dart';

/// Lo que devuelve el selector. null = se cerró sin elegir;
/// Eleccion(null) = se eligió la opción "ninguno" (p. ej. "Sin asignar").
/// Con un T? a secas, esos dos casos serían indistinguibles.
class Eleccion<T> {
  final T? valor;
  const Eleccion(this.valor);
}

/// Minúsculas y sin acentos: "Eléctrico" y "electrico" son lo mismo.
String normalizarBusqueda(String s) {
  const con = 'áàäâéèëêíìïîóòöôúùüûñ';
  const sin = 'aaaaeeeeiiiioooouuuun';
  final minus = s.toLowerCase();
  final b = StringBuffer();
  for (final c in minus.split('')) {
    final i = con.indexOf(c);
    b.write(i < 0 ? c : sin[i]);
  }
  return b.toString();
}

/// Lista buscable en una hoja inferior, genérica sobre el tipo de opción.
/// No conoce modelos de negocio: las funciones dicen cómo mostrar cada una.
class SelectorBuscable<T> extends StatefulWidget {
  final String titulo;
  final List<T> opciones;
  final String Function(T) textoDe;
  final String Function(T)? subtituloDe;
  final IconData Function(T)? iconoDe;
  final T? seleccionado;

  /// Cómo reconocer el seleccionado. Hace falta porque las entidades no
  /// implementan ==: se comparan por id.
  final String Function(T)? claveDe;

  /// Si no es null, primera fila que devuelve Eleccion(null).
  final String? textoNinguno;

  /// Texto del botón de crear. Si es null, no se muestra el botón.
  final String? textoCrear;

  /// Abre el formulario de alta y devuelve el elemento creado, o null
  /// si se canceló. El selector se cierra devolviendo ese elemento.
  final Future<T?> Function(BuildContext)? alCrear;

  const SelectorBuscable({
    super.key,
    required this.titulo,
    required this.opciones,
    required this.textoDe,
    this.subtituloDe,
    this.iconoDe,
    this.seleccionado,
    this.claveDe,
    this.textoNinguno,
    this.textoCrear,
    this.alCrear,
  });

  /// Abre el selector como hoja inferior y devuelve lo elegido.
  static Future<Eleccion<T>?> mostrar<T>(
    BuildContext context, {
    required String titulo,
    required List<T> opciones,
    required String Function(T) textoDe,
    String Function(T)? subtituloDe,
    IconData Function(T)? iconoDe,
    T? seleccionado,
    String Function(T)? claveDe,
    String? textoNinguno,
    String? textoCrear,
    Future<T?> Function(BuildContext)? alCrear,
  }) =>
      showModalBottomSheet<Eleccion<T>>(
        context: context,
        isScrollControlled: true,   // sin esto el teclado la aplasta
        backgroundColor: AppColors.fondo,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => SelectorBuscable<T>(
          titulo: titulo,
          opciones: opciones,
          textoDe: textoDe,
          subtituloDe: subtituloDe,
          iconoDe: iconoDe,
          seleccionado: seleccionado,
          claveDe: claveDe,
          textoNinguno: textoNinguno,
          textoCrear: textoCrear,
          alCrear: alCrear,
        ),
      );

  @override
  State<SelectorBuscable<T>> createState() => _SelectorBuscableState<T>();
}

class _SelectorBuscableState<T> extends State<SelectorBuscable<T>> {
  final _busqueda = TextEditingController();
  bool _creando = false;

  @override
  void initState() {
    super.initState();
    _busqueda.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  bool _coincide(T o, String q) =>
      normalizarBusqueda(widget.textoDe(o)).contains(q) ||
      (widget.subtituloDe != null &&
          normalizarBusqueda(widget.subtituloDe!(o)).contains(q));

  bool _esSeleccionado(T o) {
    final sel = widget.seleccionado;
    if (sel == null) return false;
    final clave = widget.claveDe;
    return clave == null ? o == sel : clave(o) == clave(sel);
  }

  Future<void> _crear() async {
    setState(() => _creando = true);
    final nuevo = await widget.alCrear!(context);
    if (!mounted) return;
    setState(() => _creando = false);
    // No se deja al usuario buscándolo otra vez: se devuelve directo
    if (nuevo != null) Navigator.pop(context, Eleccion<T>(nuevo));
  }

  @override
  Widget build(BuildContext context) {
    final medidas = MediaQuery.of(context);
    final teclado = medidas.viewInsets.bottom;
    // ~75 % de la pantalla, pero sin pasarse cuando el teclado está abierto
    final alto = (medidas.size.height * 0.75)
        .clamp(0.0, medidas.size.height - teclado - medidas.padding.top - 8);

    final q = normalizarBusqueda(_busqueda.text.trim());
    final visibles =
        q.isEmpty ? widget.opciones : widget.opciones.where((o) => _coincide(o, q)).toList();
    final ninguno = widget.textoNinguno;
    final mostrarNinguno =
        ninguno != null && (q.isEmpty || normalizarBusqueda(ninguno).contains(q));
    final puedeCrear = widget.textoCrear != null && widget.alCrear != null;

    return Padding(
      padding: EdgeInsets.only(bottom: teclado),
      child: SizedBox(
        height: alto,
        child: Column(
          children: [
            // ══ CABECERA ══
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
              child: Column(
                children: [
                  Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: AppColors.borde,
                      borderRadius: BorderRadius.circular(2))),
                  Row(
                    children: [
                      Expanded(child: Text(widget.titulo, style: AppText.subtitulo)),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textoGris),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CampoTexto(
                label: '',
                hint: 'Buscar...',
                iconoIzq: Icons.search,
                controller: _busqueda,
              ),
            ),

            // ══ LISTA ══
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (mostrarNinguno)
                    FilaOpcion(
                      icono: Icons.person_off_outlined,
                      titulo: ninguno,
                      color: widget.seleccionado == null
                          ? AppColors.azul : AppColors.textoGris,
                      trailing: widget.seleccionado == null
                          ? const Icon(Icons.check_circle, color: AppColors.verde, size: 22)
                          : const SizedBox.shrink(),
                      onTap: () => Navigator.pop(context, Eleccion<T>(null)),
                    ),
                  for (final o in visibles) _fila(o),
                  if (visibles.isEmpty && !mostrarNinguno)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        q.isEmpty
                            ? 'No hay opciones disponibles'
                            : 'Nada coincide con "${_busqueda.text.trim()}"',
                        textAlign: TextAlign.center,
                        style: AppText.gris,
                      ),
                    ),
                ],
              ),
            ),

            // ══ CREAR: fijo abajo, visible aunque la búsqueda no encuentre nada ══
            if (puedeCrear)
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + medidas.padding.bottom),
                child: BotonAncho(
                  texto: widget.textoCrear!,
                  icono: Icons.add,
                  estilo: EstiloBoton.borde,
                  onTap: _creando ? null : _crear,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fila(T o) {
    final activo = _esSeleccionado(o);
    return FilaOpcion(
      icono: widget.iconoDe?.call(o) ?? Icons.label_outline,
      titulo: widget.textoDe(o),
      subtitulo: widget.subtituloDe?.call(o),
      color: activo ? AppColors.azul : AppColors.textoGris,
      trailing: activo
          ? const Icon(Icons.check_circle, color: AppColors.verde, size: 22)
          : null,
      onTap: () => Navigator.pop(context, Eleccion<T>(o)),
    );
  }
}
