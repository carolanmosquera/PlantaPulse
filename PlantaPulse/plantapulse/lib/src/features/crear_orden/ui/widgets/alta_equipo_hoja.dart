// lib/src/features/crear_orden/ui/widgets/alta_equipo_hoja.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../../domain/usecases/crear_orden_casos.dart';

/// Clave que se guarda en equipos.tipo → etiqueta en pantalla.
const tiposDeEquipo = {
  'mecanico': 'Mecánico',
  'electrico': 'Eléctrico',
  'hidraulico': 'Hidráulico',
  'electronico': 'Electrónico',
};

/// Alta o edición de un equipo. Devuelve el equipo como quedó en la base
/// (con id y con la zona resuelta por el servidor) o null si se canceló.
///
/// El estado no se pregunta: un equipo recién registrado está operativo,
/// y al editar se conserva el que tenía.
class AltaEquipoHoja extends StatefulWidget {
  final String plantaId;

  /// Con equipo, el formulario edita ese equipo en vez de crear uno.
  final Equipo? equipo;

  const AltaEquipoHoja({super.key, required this.plantaId, this.equipo});

  static Future<Equipo?> mostrar(BuildContext context,
          {required String plantaId}) =>
      HojaFormulario.mostrar<Equipo>(context, AltaEquipoHoja(plantaId: plantaId));

  static Future<Equipo?> editar(BuildContext context, Equipo equipo) =>
      HojaFormulario.mostrar<Equipo>(
          context, AltaEquipoHoja(plantaId: equipo.plantaId, equipo: equipo));

  @override
  State<AltaEquipoHoja> createState() => _AltaEquipoHojaState();
}

class _AltaEquipoHojaState extends State<AltaEquipoHoja> {
  static const _tipos = tiposDeEquipo;

  late final _nombre = TextEditingController(text: widget.equipo?.nombre);
  late final _serial = TextEditingController(text: widget.equipo?.serial);
  late final _modelo = TextEditingController(text: widget.equipo?.modelo);
  late final Future<List<Zona>> _zonas =
      context.read<ListarZonasDePlanta>().ejecutar(widget.plantaId);

  // La zona se guarda por id y nombre: al editar, la Zona completa no se
  // conoce hasta que carga la lista
  late String? _zonaId = widget.equipo?.zonaId;
  late String? _zonaNombre = widget.equipo?.zonaNombre;
  // Opcional: ningún chip marcado al empezar un alta
  late String _tipo = widget.equipo?.tipo ?? '';

  bool get _editando => widget.equipo != null;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nombre.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nombre.dispose();
    _serial.dispose();
    _modelo.dispose();
    super.dispose();
  }

  Future<void> _elegirZona(List<Zona> zonas) async {
    final eleccion = await SelectorBuscable.mostrar<Zona>(
      context,
      titulo: 'Zona del equipo',
      opciones: zonas,
      textoDe: (z) => z.nombre,
      subtituloDe: (z) => z.codigo,
      iconoDe: (_) => Icons.place_outlined,
      seleccionado: zonas.where((z) => z.id == _zonaId).firstOrNull,
      claveDe: (z) => z.id,
    );
    final zona = eleccion?.valor;
    if (zona != null && mounted) {
      setState(() {
        _zonaId = zona.id;
        _zonaNombre = zona.nombre;
      });
    }
  }

  Future<void> _guardar() async {
    final crear = context.read<CrearEquipo>();
    final editar = context.read<EditarEquipo>();
    final navegador = Navigator.of(context);
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final original = widget.equipo;
      final guardado = original == null
          ? await crear.ejecutar(
              plantaId: widget.plantaId,
              zonaId: _zonaId!,
              nombre: _nombre.text,
              serial: _serial.text,
              modelo: _modelo.text,
              tipo: _tipo,
            )
          : await editar.ejecutar(Equipo(
              id: original.id,
              plantaId: original.plantaId,
              zonaId: _zonaId!,
              zonaNombre: _zonaNombre ?? '',
              nombre: _nombre.text,
              serial: _serial.text,
              modelo: _modelo.text,
              tipo: _tipo,
              fotoUrl: original.fotoUrl,
              estado: original.estado,
              ultimoMantenimiento: original.ultimoMantenimiento,
              activo: original.activo,
            ));
      navegador.pop(guardado);
    } catch (e) {
      // Un serial repetido llega con su propio mensaje (error 23505)
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = FalloApp.mensajeDe(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final valido = _nombre.text.trim().isNotEmpty && _zonaId != null;
    final claves = _tipos.keys.toList();

    return HojaFormulario(
      titulo: _editando ? 'Editar equipo' : 'Registrar equipo nuevo',
      error: _error,
      guardando: _guardando,
      alGuardar: valido ? _guardar : null,
      campos: [
        CampoTexto(label: 'Nombre', hint: 'Ej: Compresor Atlas Copco GA75',
            controller: _nombre),
        FutureBuilder<List<Zona>>(
          future: _zonas,
          builder: (context, snap) {
            final zonas = snap.data ?? const <Zona>[];
            return CampoSeleccion(
              label: 'ZONA',
              icono: Icons.place_outlined,
              valor: _zonaNombre,
              vacio: snap.hasError
                  ? 'No se pudieron cargar las zonas'
                  : snap.hasData ? 'Seleccionar zona' : 'Cargando zonas...',
              onTap: snap.hasData ? () => _elegirZona(zonas) : null,
            );
          },
        ),
        const SizedBox(height: 16),
        CampoTexto(label: 'Serial (opcional)', hint: 'Ej: AC-88291-K',
            controller: _serial),
        CampoTexto(label: 'Modelo (opcional)', hint: 'Ej: 2022',
            controller: _modelo),
        const Text('TIPO (OPCIONAL)', style: AppText.label),
        const SizedBox(height: 8),
        ChipsFila(
          opciones: _tipos.values.toList(),
          inicial: claves.indexOf(_tipo),
          onCambio: (i) => setState(() => _tipo = claves[i]),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
