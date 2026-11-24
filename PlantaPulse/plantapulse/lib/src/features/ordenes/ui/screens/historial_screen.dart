import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/core.dart';
import '../bloc/historial_bloc.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _texto = TextEditingController();
  Timer? _espera;

  @override
  void dispose() {
    _espera?.cancel();
    _texto.dispose();
    super.dispose();
  }

  void _buscar({String? equipoId, bool cambiarEquipo = false}) {
    _espera?.cancel();
    final actual = context.read<HistorialBloc>().state;
    context.read<HistorialBloc>().add(
      HistorialBuscado(_texto.text, cambiarEquipo ? equipoId : actual.equipoId),
    );
  }

  Future<void> _seleccionarEquipo(HistorialState state) async {
    final elegido = await SelectorBuscable.mostrar<Equipo>(
      context,
      titulo: 'Equipos de la planta',
      opciones: state.equipos,
      textoDe: (e) => e.nombre,
      subtituloDe: (e) => e.activo ? e.serial : '${e.serial} · Dado de baja',
      claveDe: (e) => e.id,
      seleccionado: state.equipos
          .where((e) => e.id == state.equipoId)
          .firstOrNull,
      textoNinguno: 'Todos los equipos',
    );
    if (!mounted || elegido == null) return;
    _buscar(equipoId: elegido.valor?.id, cambiarEquipo: true);
  }

  @override
  Widget build(BuildContext context) => PantallaBase(
    titulo: 'Historial de mantenimiento',
    conNavegacion: false,
    cuerpo: BlocBuilder<HistorialBloc, HistorialState>(
      builder: (context, state) {
        final equipo = state.equipos
            .where((e) => e.id == state.equipoId)
            .firstOrNull;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _texto,
              decoration: const InputDecoration(
                hintText: 'Buscar en título y descripción',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) {
                _espera?.cancel();
                _espera = Timer(const Duration(milliseconds: 350), _buscar);
              },
              onSubmitted: (_) => _buscar(),
            ),
            const SizedBox(height: 12),
            FilaOpcion(
              icono: Icons.precision_manufacturing_outlined,
              titulo: equipo?.nombre ?? 'Todos los equipos',
              subtitulo: equipo?.activo == false
                  ? 'Dado de baja · toca para cambiar'
                  : 'Filtrar por equipo',
              onTap: state.cargandoEquipos
                  ? null
                  : () => _seleccionarEquipo(state),
            ),
            if (state.cargandoEquipos) const LinearProgressIndicator(),
            if (state.errorEquipos != null)
              Text(
                state.errorEquipos!,
                style: TextStyle(color: AppColors.rojo.segunTema(context)),
              ),
            const SizedBox(height: 12),
            if (state.error != null) ...[
              TileAviso(
                icono: Icons.cloud_off,
                titulo: 'Error al buscar',
                subtitulo: state.error,
                color: AppColors.rojo,
              ),
              TextButton(onPressed: _buscar, child: const Text('Reintentar')),
            ],
            if (state.cargando && state.ordenes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!state.cargando &&
                state.error == null &&
                state.ordenes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No hay órdenes que coincidan')),
              ),
            ...state.ordenes.map(
              (orden) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FilaOpcion(
                  icono: Icons.build_outlined,
                  titulo: orden.titulo,
                  subtitulo:
                      '${orden.codigo} · ${orden.equipoNombre ?? "Sin equipo"} · ${orden.estado.etiqueta}\n${orden.descripcion}',
                  onTap: () => Navigator.pushNamed(
                    context,
                    Rutas.detalleOrden,
                    arguments: orden,
                  ),
                ),
              ),
            ),
            if (state.hayMas || (state.cargando && state.ordenes.isNotEmpty))
              Center(
                child: state.cargando
                    ? const CircularProgressIndicator()
                    : TextButton(
                        onPressed: () => context.read<HistorialBloc>().add(
                          const HistorialSiguientePagina(),
                        ),
                        child: const Text('Cargar más órdenes'),
                      ),
              ),
          ],
        );
      },
    ),
  );
}
