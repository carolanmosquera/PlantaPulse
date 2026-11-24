// lib/src/features/crear_orden/ui/widgets/elegir_categoria.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../bloc/crear_orden_bloc.dart';
import 'alta_categoria_hoja.dart';

/// Buscar entre las categorías de la planta o crear una nueva. Lo usan la
/// lupa de P1 y el campo de categoría de P2.
Future<void> elegirCategoria(BuildContext context, CrearOrdenBloc bloc) async {
  final usuario = context.read<SesionBloc>().state.usuario;
  final state = bloc.state;
  final eleccion = await SelectorBuscable.mostrar<Categoria>(
    context,
    titulo: 'Categoría',
    opciones: state.categorias,
    textoDe: (c) => c.nombre,
    iconoDe: (c) => iconoDeCategoria(c.icono),
    seleccionado:
        state.categorias.where((c) => c.nombre == state.categoria).firstOrNull,
    claveDe: (c) => c.id,
    textoCrear: usuario == null ? null : 'Crear categoría',
    alCrear: usuario == null
        ? null
        : (ctx) => AltaCategoriaHoja.mostrar(ctx,
            plantaId: state.plantaId, creadaPor: usuario.ref),
  );
  _aplicar(bloc, eleccion?.valor);
}

/// "Crear categoría" desde la sugerencia de la IA: abre el alta con el
/// nombre propuesto. La crea el supervisor al guardar, nunca el asistente.
Future<void> crearCategoriaSugerida(
  BuildContext context,
  CrearOrdenBloc bloc,
  String nombre,
) async {
  final usuario = context.read<SesionBloc>().state.usuario;
  if (usuario == null) return;
  final creada = await AltaCategoriaHoja.mostrar(
    context,
    plantaId: bloc.state.plantaId,
    creadaPor: usuario.ref,
    nombreInicial: nombre,
  );
  _aplicar(bloc, creada);
}

/// Una recién creada aún no está en el catálogo: se añade y se marca.
void _aplicar(CrearOrdenBloc bloc, Categoria? categoria) {
  if (categoria == null) return;
  bloc.add(bloc.state.categorias.any((c) => c.id == categoria.id)
      ? CategoriaCambiada(categoria.nombre)
      : CategoriaAgregada(categoria));
}
