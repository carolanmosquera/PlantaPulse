// lib/src/features/ordenes/ui/widgets/editar_orden_hoja.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../bloc/ordenes_bloc.dart';

/// "Editar orden": título, descripción, categoría, prioridad, fecha límite
/// y técnico responsable. El técnico también se cambia desde "Asignar
/// técnico" en el menú del detalle: aquí está por si alguien lo busca al
/// editar.
///
/// Equipo y zona NO se editan: cambiarlos convierte la orden en otra y deja
/// el historial del equipo mintiendo. Si se equivocaron de equipo, se
/// cierra esa orden y se abre otra.
///
/// Al guardar se cierra sin mensaje de éxito: el cambio vuelve por el
/// stream y el detalle se actualiza solo con lo que guardó el servidor.
class EditarOrdenHoja extends StatefulWidget {
  final Orden orden;
  final OrdenesBloc bloc;   // la hoja vive en otra ruta: se le pasa el Bloc

  const EditarOrdenHoja({super.key, required this.orden, required this.bloc});

  static Future<void> mostrar(BuildContext context, Orden orden) =>
      HojaFormulario.mostrar<void>(
        context,
        EditarOrdenHoja(orden: orden, bloc: context.read<OrdenesBloc>()),
      );

  @override
  State<EditarOrdenHoja> createState() => _EditarOrdenHojaState();
}

class _EditarOrdenHojaState extends State<EditarOrdenHoja> {
  static const _prioridades = Prioridad.values;

  late final _titulo = TextEditingController(text: widget.orden.titulo);
  late final _descripcion =
      TextEditingController(text: widget.orden.descripcion);
  late String _categoria = widget.orden.categoria;
  late Prioridad _prioridad = widget.orden.prioridad;
  late DateTime _fechaLimite = widget.orden.fechaLimite;

  /// Lo que muestra el campo. Empieza con el responsable actual de la orden.
  late UsuarioRef? _responsable = widget.orden.asignadoA;

  /// Solo si el usuario eligió algo distinto se manda la reasignación:
  /// así guardar un cambio de título no toca el técnico.
  bool _tecnicoCambiado = false;
  Usuario? _tecnicoNuevo;

  late final Future<List<Categoria>> _categorias = context
      .read<ListarCategoriasDePlanta>()
      .ejecutar(widget.orden.plantaId);

  late final Future<List<Usuario>> _tecnicos = context
      .read<ListarTecnicosDePlanta>()
      .ejecutar(widget.orden.plantaId);

  @override
  void initState() {
    super.initState();
    _titulo.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _elegirCategoria(List<Categoria> categorias) async {
    final eleccion = await SelectorBuscable.mostrar<Categoria>(
      context,
      titulo: 'Categoría',
      opciones: categorias,
      textoDe: (c) => c.nombre,
      iconoDe: (c) => iconoDeCategoria(c.icono),
      seleccionado: categorias.where((c) => c.nombre == _categoria).firstOrNull,
      claveDe: (c) => c.id,
    );
    final c = eleccion?.valor;
    if (c != null && mounted) setState(() => _categoria = c.nombre);
  }

  /// El mismo selector que "Asignar técnico", con "Sin asignar" primero.
  Future<void> _elegirTecnico(List<Usuario> tecnicos) async {
    final eleccion = await SelectorBuscable.mostrar<Usuario>(
      context,
      titulo: 'Técnico Responsable',
      opciones: tecnicos,
      textoDe: (u) => u.nombre,
      subtituloDe: (u) => u.especialidad,
      iconoDe: (_) => Icons.engineering_outlined,
      seleccionado:
          tecnicos.where((u) => u.uid == _responsable?.uid).firstOrNull,
      claveDe: (u) => u.uid,
      textoNinguno: 'Sin asignar',
    );
    if (eleccion == null || !mounted) return;       // cerró sin elegir
    final tecnico = eleccion.valor;
    setState(() {
      _responsable = tecnico?.ref;
      _tecnicoNuevo = tecnico;
      // Volver a elegir el mismo que ya tenía no cuenta como cambio
      _tecnicoCambiado = tecnico?.uid != widget.orden.asignadoAUid;
    });
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaLimite,
      // Una orden vencida conserva su fecha aunque sea anterior a hoy
      firstDate: _fechaLimite.isBefore(hoy) ? _fechaLimite : hoy,
      lastDate: hoy.add(const Duration(days: 365)),
    );
    if (elegida == null || !mounted) return;
    // Igual que al publicar: vence al final del día elegido, en hora local.
    // El repositorio la pasa a UTC con aIso.
    setState(() => _fechaLimite =
        DateTime(elegida.year, elegida.month, elegida.day, 23, 59));
  }

  void _guardar() {
    widget.bloc.add(OrdenEditada(
      ordenId: widget.orden.id,
      titulo: _titulo.text,
      descripcion: _descripcion.text,
      categoria: _categoria,
      prioridad: _prioridad,
      fechaLimite: _fechaLimite,
    ));
    // Mismo evento que "Asignar técnico": una sola forma de reasignar
    if (_tecnicoCambiado) {
      widget.bloc.add(TecnicoAsignado(widget.orden.id, _tecnicoNuevo));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final valido = _titulo.text.trim().length >= 10;
    final f = _fechaLimite;

    return HojaFormulario(
      titulo: 'Editar orden',
      error: null,
      guardando: false,
      alGuardar: valido ? _guardar : null,
      campos: [
        CampoTexto(label: 'Título', hint: 'Mínimo 10 caracteres',
            lineas: 2, controller: _titulo),
        CampoTexto(label: 'Descripción', hint: 'Observaciones técnicas',
            lineas: 3, controller: _descripcion),
        FutureBuilder<List<Categoria>>(
          future: _categorias,
          builder: (context, snap) => CampoSeleccion(
            label: 'CATEGORÍA',
            icono: Icons.label_outline,
            // Puede no estar en la lista si la renombraron: se conserva igual
            valor: _categoria.isEmpty ? null : _categoria,
            vacio: 'Sin categoría',
            onTap: snap.hasData ? () => _elegirCategoria(snap.data!) : null,
          ),
        ),
        const SizedBox(height: 16),
        const Text('PRIORIDAD', style: AppText.label),
        const SizedBox(height: 8),
        ChipsFila(
          opciones: [for (final p in _prioridades) p.etiqueta],
          colorActivo: AppColors.naranja,
          inicial: _prioridades.indexOf(_prioridad),
          onCambio: (i) => setState(() => _prioridad = _prioridades[i]),
        ),
        const SizedBox(height: 12),
        CampoSeleccion(
          label: 'FECHA LÍMITE',
          icono: Icons.calendar_today_outlined,
          valor: '${f.day.toString().padLeft(2, '0')}/'
              '${f.month.toString().padLeft(2, '0')}/${f.year}',
          vacio: '',
          onTap: _elegirFecha,
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Usuario>>(
          future: _tecnicos,
          builder: (context, snap) => CampoSeleccion(
            label: 'TÉCNICO RESPONSABLE',
            icono: Icons.engineering_outlined,
            valor: _responsable?.nombre,
            vacio: snap.hasError
                ? 'No se pudieron cargar los técnicos'
                : 'Sin asignar',
            onTap: snap.hasData ? () => _elegirTecnico(snap.data!) : null,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
