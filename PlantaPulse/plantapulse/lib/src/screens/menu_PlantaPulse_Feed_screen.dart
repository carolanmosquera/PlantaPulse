  // lib/src/screens/feed_screen.dart
  import 'package:flutter/material.dart';
  import '../theme/app_colors.dart';
  import '../theme/rutas.dart';
  import '../models/orden.dart';
  import '../models/datos_demo.dart';
  import '../components/widgets.dart';

  class MenuPlantaPulseFeed extends StatefulWidget {
    const MenuPlantaPulseFeed({super.key});
    @override
    State<MenuPlantaPulseFeed> createState() => _MenuPlantaPulseFeedState();
  }

  class _MenuPlantaPulseFeedState extends State<MenuPlantaPulseFeed> {
    final _busquedaCtrl = TextEditingController();
    int _filtro = 0;

    // Copia mutable de los datos demo (la const original no admite insert)
    final List<Orden> _ordenes = List<Orden>.from(ordenesDemo);

    static const _filtros = ['Todos', 'Pendiente', 'En Progreso', 'Urgente'];

    @override
    void initState() {
      super.initState();
      _busquedaCtrl.addListener(() => setState(() {}));
    }

    @override
    void dispose() {
      _busquedaCtrl.dispose();
      super.dispose();
    }

    // ── Filtrado: se calcula, no se guarda ──
    List<Orden> get _visibles {
      var lista = _ordenes;

      switch (_filtro) {
        case 1:
          lista = lista.where((o) => o.estado == EstadoOrden.pendiente).toList();
        case 2:
          lista = lista.where((o) => o.estado == EstadoOrden.enProgreso).toList();
        case 3:
          lista = lista.where((o) => o.prioridad == Prioridad.critica).toList();
      }

      final texto = _busquedaCtrl.text.trim().toLowerCase();
      if (texto.isNotEmpty) {
        lista = lista.where((o) =>
            o.titulo.toLowerCase().contains(texto) ||
            o.codigo.toLowerCase().contains(texto) ||
            o.ubicacion.toLowerCase().contains(texto)).toList();
      }

      return lista;
    }

    @override
    Widget build(BuildContext context) {
      final visibles = _visibles;

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
        fab: FloatingActionButton(
          backgroundColor: AppColors.naranja,
          onPressed: () => Navigator.pushNamed(context, Rutas.crearOrden),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
        cuerpo: ListView(
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
                    onCambio: (i) => setState(() => _filtro = i),
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

            // ══ LISTA ══
            if (visibles.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    const Icon(Icons.search_off, size: 46,
                              color: AppColors.textoGris),
                    const SizedBox(height: 12),
                    Text('No hay órdenes que coincidan', style: AppText.gris),
                  ],
                ),
              )
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
        ),
      );
    }
  }