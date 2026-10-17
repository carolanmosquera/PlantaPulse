// lib/src/features/ordenes/ui/screens/feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../bloc/ordenes_bloc.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _busquedaCtrl = TextEditingController();

  // Alineadas con el switch de OrdenesState.visibles: índice 4 = sin técnico
  static const _filtros = [
    'Todos', 'Pendiente', 'En Progreso', 'Urgente', 'Sin asignar',
  ];

  @override
  void initState() {
    super.initState();
    final ordenes = context.read<OrdenesBloc>();

    // El Bloc es global: si ya había una búsqueda, el campo la refleja
    _busquedaCtrl.text = ordenes.state.busqueda;
    _busquedaCtrl.addListener(
        () => ordenes.add(BusquedaCambiada(_busquedaCtrl.text)));

    // Se relanza siempre: Mis Tareas pudo dejar el Bloc con otra consulta
    final plantaId = context.read<SesionBloc>().state.usuario?.plantaId ?? '';
    ordenes.add(OrdenesSuscritas(plantaId));
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Supervisor o admin: el mismo criterio que puede_operar() en la base
    final puedeCrear =
        context.watch<SesionBloc>().state.usuario?.rol.puedeOperar ?? false;

    return PantallaBase(
      titulo: 'PlantaPulse Feed',
      mostrarAtras: false,        // pantalla raíz: no hay a dónde volver
      mostrarMenu: true,
      tabActiva: 0,
      accionesExtra: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: AppColors.texto),
          onPressed: () => Navigator.pushReplacementNamed(context, Rutas.alertas),
        ),
      ],
      // Solo supervisor y admin crean órdenes (RLS también lo exige)
      fab: puedeCrear
          ? FloatingActionButton(
              backgroundColor: AppColors.naranja,
              onPressed: () => Navigator.pushNamed(context, Rutas.crearOrden),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      cuerpo: BlocBuilder<OrdenesBloc, OrdenesState>(
        builder: (context, state) {
          final visibles = state.visibles;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 12),

              // ══ BÚSQUEDA ══
              CampoTexto(
                label: '',
                hint: 'Buscar órdenes o equipos...',
                iconoIzq: Icons.search,
                controller: _busquedaCtrl,
              ),
              const SizedBox(height: 14),

              // ══ FILTROS ══
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 34,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borde),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.tune, size: 17,
                                      color: AppColors.textoGris),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChipsFila(
                      opciones: _filtros,
                      inicial: state.filtro,
                      onCambio: (i) =>
                          context.read<OrdenesBloc>().add(FiltroCambiado(i)),
                    ),
                  ),
                ],
              ),

              // ══ ENCABEZADO ══
              SeccionHeader(
                titulo: 'Órdenes Activas',
                accion: 'Ver Calendario',
                onAccion: () {},
              ),
              Text(
                'Mostrando ${visibles.length} '
                '${visibles.length == 1 ? "tarea" : "tareas"} para hoy',
                style: AppText.gris,
              ),
              const SizedBox(height: 14),

              // ══ AVISO DE ERROR: no oculta lo que ya estaba ══
              if (state.status == EstadoOrdenes.error) ...[
                TileAviso(
                  icono: Icons.cloud_off,
                  titulo: 'No se pudieron actualizar las órdenes',
                  subtitulo: state.mensajeError,
                  color: AppColors.rojo,
                ),
                const SizedBox(height: 14),
              ],

              // ══ LISTA ══
              if (state.status == EstadoOrdenes.cargando && state.ordenes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.vacioTotal)
                _mensajeVacio(Icons.inbox,
                    'Aún no hay órdenes publicadas en esta planta')
              else if (state.sinResultados)
                _mensajeVacio(Icons.search_off, 'No hay órdenes que coincidan')
              else
                ...visibles.map((orden) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OrdenCard(
                    codigo: orden.codigo,
                    titulo: orden.titulo,
                    ubicacion: orden.ubicacion,
                    estado: orden.estado.etiqueta,
                    estadoColor: orden.estado.color,
                    hora: orden.hora,
                    prioridad: orden.prioridadTexto,
                    fotoUrl: orden.portadaUrl,
                    estilo: EstiloOrden.conFoto,
                    sinAsignar: orden.sinAsignar,
                    onTap: () => Navigator.pushNamed(
                      context,
                      Rutas.detalleOrden,
                      arguments: orden,
                    ),
                  ),
                )),

              const SizedBox(height: 8),

              // ══ BANNER ══
              const TarjetaOscura(
                icono: Icon(Icons.check_circle_outline,
                            color: Colors.white, size: 28),
                titulo: 'Optimización del Turno',
                subtitulo: 'Has completado el 60% de tus objetivos semanales. '
                          '¡Buen trabajo!',
              ),

              const SizedBox(height: 90),   // espacio para que el FAB no tape
            ],
          );
        },
      ),
    );
  }

  Widget _mensajeVacio(IconData icono, String texto) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(icono, size: 46, color: AppColors.textoGris),
            const SizedBox(height: 12),
            Text(texto, style: AppText.gris, textAlign: TextAlign.center),
          ],
        ),
      );
}
