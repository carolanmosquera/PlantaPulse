// lib/src/features/crear_orden/ui/widgets/alta_equipo_hoja.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../../domain/usecases/crear_orden_casos.dart';

/// Alta de equipo. Devuelve el equipo como quedó en la base (con id y
/// con la zona resuelta por el servidor) o null si se canceló.
///
/// El estado no se pregunta: un equipo recién registrado está operativo.
class AltaEquipoHoja extends StatefulWidget {
  final String plantaId;

  const AltaEquipoHoja({super.key, required this.plantaId});

  static Future<Equipo?> mostrar(BuildContext context,
          {required String plantaId}) =>
      HojaFormulario.mostrar<Equipo>(context, AltaEquipoHoja(plantaId: plantaId));

  @override
  State<AltaEquipoHoja> createState() => _AltaEquipoHojaState();
}

class _AltaEquipoHojaState extends State<AltaEquipoHoja> {
  // Clave que se guarda en equipos.tipo → etiqueta en pantalla
  static const _tipos = {
    'mecanico': 'Mecánico',
    'electrico': 'Eléctrico',
    'hidraulico': 'Hidráulico',
    'electronico': 'Electrónico',
  };

  final _nombre = TextEditingController();
  final _serial = TextEditingController();
  final _modelo = TextEditingController();
  late final Future<List<Zona>> _zonas =
      context.read<ListarZonasDePlanta>().ejecutar(widget.plantaId);

  Zona? _zona;
  String _tipo = '';           // opcional: ningún chip marcado al empezar
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
      seleccionado: _zona,
      claveDe: (z) => z.id,
    );
    final zona = eleccion?.valor;
    if (zona != null && mounted) setState(() => _zona = zona);
  }

  Future<void> _guardar() async {
    final crear = context.read<CrearEquipo>();
    final navegador = Navigator.of(context);
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final creado = await crear.ejecutar(
        plantaId: widget.plantaId,
        zonaId: _zona!.id,
        nombre: _nombre.text,
        serial: _serial.text,
        modelo: _modelo.text,
        tipo: _tipo,
      );
      navegador.pop(creado);
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
    final valido = _nombre.text.trim().isNotEmpty && _zona != null;
    final claves = _tipos.keys.toList();

    return HojaFormulario(
      titulo: 'Registrar equipo nuevo',
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
              valor: _zona?.nombre,
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
