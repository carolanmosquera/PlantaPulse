// lib/src/features/crear_orden/ui/screens/crear_orden_p1_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../../domain/usecases/crear_orden_casos.dart';
import '../bloc/crear_orden_bloc.dart';
import 'crear_orden_p2_screen.dart';

/// Primer paso del asistente. Crea el CrearOrdenBloc, que vive solo
/// mientras el asistente esté abierto y se comparte con P2.
class CrearOrdenP1Screen extends StatelessWidget {
  const CrearOrdenP1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final plantaId = context.read<SesionBloc>().state.usuario?.plantaId ?? '';
    return BlocProvider<CrearOrdenBloc>(
      create: (context) => CrearOrdenBloc(
        listarEquipos: context.read<ListarEquiposDePlanta>(),
        listarTecnicos: context.read<ListarTecnicosDePlanta>(),
        publicarOrden: context.read<PublicarOrden>(),
      )..add(CrearOrdenIniciada(plantaId)),
      child: const _CrearOrdenP1Vista(),
    );
  }
}

class _CrearOrdenP1Vista extends StatefulWidget {
  const _CrearOrdenP1Vista();
  @override
  State<_CrearOrdenP1Vista> createState() => _CrearOrdenP1VistaState();
}

class _CrearOrdenP1VistaState extends State<_CrearOrdenP1Vista> {
  final _descCtrl = TextEditingController();

  // Las categorías salen del enum del modelo, así P1 y la orden nunca se desincronizan
  static const _categorias = CategoriaOrden.values;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<CrearOrdenBloc>();
    _descCtrl.addListener(
        () => bloc.add(DescripcionCambiada(_descCtrl.text)));
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  void _continuar() {
    final bloc = context.read<CrearOrdenBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const CrearOrdenP2Screen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CrearOrdenBloc, CrearOrdenState>(
      builder: (context, state) {
        final largo = state.descripcion.trim().length;

        return PantallaBase(
          titulo: 'Crear Nueva Orden',
          tabActiva: 0,
          cuerpo: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 14),

              // ══ PROGRESO ══
              Row(
                children: [
                  const PillEstado(texto: 'PASO 1 DE 2', color: AppColors.azulOscuro,
                    relleno: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: const LinearProgressIndicator(
                        value: 0.5, minHeight: 4,
                        backgroundColor: AppColors.borde,
                        color: AppColors.azul,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text('¿Cuál es el problema?',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold,
                                color: AppColors.texto)),
              const SizedBox(height: 8),
              const Text(
                'Describe el hallazgo o falla técnica. Puedes usar el dictado '
                'por voz para mayor rapidez.',
                style: TextStyle(fontSize: 13.5, color: AppColors.textoGris,
                                height: 1.4)),
              const SizedBox(height: 16),

              // ══ DESCRIPCIÓN ══
              CampoTexto(
                label: '',
                hint: 'Ej: Se detectó una fuga de aceite en el sello mecánico '
                      'del motor principal, temperatura elevada...',
                lineas: 4,
                controller: _descCtrl,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 13,
                    color: largo >= 10 ? AppColors.textoGris : AppColors.rojo),
                  const SizedBox(width: 6),
                  Text('Mínimo 10 caracteres',
                    style: TextStyle(fontSize: 11.5,
                      color: state.descripcion.isNotEmpty && largo < 10
                          ? AppColors.rojo : AppColors.textoGris)),
                  const Spacer(),
                  Container(
                    width: 42, height: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.naranja, shape: BoxShape.circle),
                    child: const Icon(Icons.mic, color: Colors.white, size: 20),
                  ),
                ],
              ),

              // ══ CATEGORÍA ══
              const SeccionHeader(titulo: 'CATEGORÍA INICIAL',
                accion: 'Obligatorio'),
              ChipsFila(
                opciones: [for (final c in _categorias) c.etiqueta],
                iconos: [for (final c in _categorias) c.icono],
                inicial: _categorias.indexOf(state.categoria),
                onCambio: (i) => context
                    .read<CrearOrdenBloc>()
                    .add(CategoriaCambiada(_categorias[i])),
              ),

              // ══ EQUIPOS ══
              SeccionHeader(
                icono: Icons.history,
                titulo: 'EQUIPOS RECIENTES',
                accion: 'BUSCAR TODOS',
                onAccion: () {},
              ),
              if (state.status == EstadoCrearOrden.cargando)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.equipos.isEmpty)
                TileAviso(
                  icono: Icons.precision_manufacturing_outlined,
                  titulo: state.mensajeError ??
                      'No hay equipos activos en esta planta',
                  color: state.mensajeError != null
                      ? AppColors.rojo : AppColors.textoGris,
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.equipos.length,
                  itemBuilder: (context, i) =>
                      _equipo(state.equipos[i], state.equipo),
                ),

              const SizedBox(height: 20),
              const Center(child: Text('PLANTAPULSE INDUSTRIAL CORE V3.4',
                style: TextStyle(fontSize: 9.5, color: AppColors.textoGris,
                                letterSpacing: 1.5))),
              const SizedBox(height: 16),

              // La IA es otra tajada: por ahora solo avanza a P2
              BotonAncho(
                texto: 'Estructurar con IA',
                icono: Icons.auto_awesome,
                onTap: state.paso1Valido ? _continuar : null,
              ),
              const SizedBox(height: 8),
              const Center(child: Text(
                'La IA analizará tu reporte para sugerir equipo, prioridad y tags.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textoGris))),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _equipo(Equipo equipo, Equipo? elegido) {
    final seleccionado = elegido?.id == equipo.id;
    return FilaOpcion(
      icono: Icons.build_outlined,
      titulo: equipo.nombre,
      subtitulo: '${equipo.zonaNombre} • ${equipo.serial}',
      color: seleccionado ? AppColors.azul : AppColors.textoGris,
      trailing: Icon(
        seleccionado ? Icons.check_circle : Icons.chevron_right,
        color: seleccionado ? AppColors.verde : AppColors.textoGris,
        size: seleccionado ? 22 : 20,
      ),
      onTap: () =>
          context.read<CrearOrdenBloc>().add(EquipoSeleccionado(equipo)),
    );
  }
}
