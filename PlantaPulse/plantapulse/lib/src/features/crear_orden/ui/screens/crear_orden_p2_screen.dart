// lib/src/features/crear_orden/ui/screens/crear_orden_p2_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../bloc/crear_orden_bloc.dart';

/// Segundo paso del asistente. Recibe el CrearOrdenBloc de P1 por
/// BlocProvider.value. No devuelve nada por Navigator.pop: el feed se
/// entera de la orden nueva porque está suscrito al stream en tiempo real.
class CrearOrdenP2Screen extends StatefulWidget {
  const CrearOrdenP2Screen({super.key});

  @override
  State<CrearOrdenP2Screen> createState() => _CrearOrdenP2ScreenState();
}

class _CrearOrdenP2ScreenState extends State<CrearOrdenP2Screen> {
  final _obsCtrl = TextEditingController();

  static const _prioridades = ['BAJA', 'MEDIA', 'CRÍTICA'];
  static const _prioridadesModelo = [
    Prioridad.baja, Prioridad.media, Prioridad.critica,
  ];
  static const _meses = ['enero','febrero','marzo','abril','mayo','junio',
    'julio','agosto','septiembre','octubre','noviembre','diciembre'];
  static const _dias = ['lunes','martes','miércoles','jueves','viernes',
    'sábado','domingo'];

  @override
  void initState() {
    super.initState();
    final bloc = context.read<CrearOrdenBloc>();
    _obsCtrl.text = bloc.state.observaciones;
    _obsCtrl.addListener(
        () => bloc.add(ObservacionesCambiadas(_obsCtrl.text)));
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  String _fechaTexto(DateTime f) =>
      '${_dias[f.weekday - 1]}, ${f.day} de '
      '${_meses[f.month - 1]} de ${f.year}';

  Future<void> _elegirFecha(DateTime actual) async {
    final bloc = context.read<CrearOrdenBloc>();
    final elegida = await showDatePicker(
      context: context,
      initialDate: actual,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!mounted || elegida == null) return;
    bloc.add(FechaLimiteCambiada(elegida));
  }

  /// Responsable: un técnico o "Sin asignar" (se asigna después desde
  /// el detalle de la orden).
  Future<void> _elegirTecnico(CrearOrdenState state) async {
    final bloc = context.read<CrearOrdenBloc>();
    final eleccion = await SelectorBuscable.mostrar<Usuario>(
      context,
      titulo: 'Técnico Responsable',
      opciones: state.tecnicos,
      textoDe: (u) => u.nombre,
      subtituloDe: (u) => u.especialidad,
      iconoDe: (_) => Icons.engineering_outlined,
      seleccionado: state.tecnico,
      claveDe: (u) => u.uid,
      textoNinguno: 'Sin asignar',
    );
    if (eleccion == null) return;            // cerró la hoja sin elegir
    final tecnico = eleccion.valor;
    bloc.add(tecnico == null
        ? const TecnicoQuitado()
        : TecnicoSeleccionado(tecnico));
  }

  /// Foto del hallazgo: cámara o galería, ya comprimida.
  Future<void> _agregarFoto() async {
    final bloc = context.read<CrearOrdenBloc>();
    final foto = await elegirFoto(context);
    if (foto != null) bloc.add(FotoHallazgoAgregada(foto.bytes, foto.extension));
  }

  void _publicar() {
    final supervisor = context.read<SesionBloc>().state.usuario;
    if (supervisor == null) return;
    context.read<CrearOrdenBloc>().add(OrdenPublicada(supervisor.ref));
  }

  void _alCambiarEstado(BuildContext context, CrearOrdenState state) {
    final mensajero = ScaffoldMessenger.of(context);
    if (state.status == EstadoCrearOrden.publicada) {
      // Cierra P2 y P1 de una vez: el feed ya recibió la orden por stream
      Navigator.popUntil(context, ModalRoute.withName(Rutas.feed));
      mensajero.showSnackBar(SnackBar(
        backgroundColor: AppColors.verde,
        content: Text('Orden ${state.codigoCreado} publicada'),
      ));
    } else if (state.status == EstadoCrearOrden.error) {
      mensajero.showSnackBar(SnackBar(
        backgroundColor: AppColors.rojo,
        content: Text(state.mensajeError ?? 'No se pudo publicar la orden.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CrearOrdenBloc, CrearOrdenState>(
      listenWhen: (antes, ahora) => antes.status != ahora.status,
      listener: _alCambiarEstado,
      builder: (context, state) {
        final equipo = state.equipo;

        return PantallaBase(
          titulo: 'Nueva Orden: Paso 2',
          tabActiva: 0,
          cuerpo: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(child: Container(height: 4, color: AppColors.verde)),
                  const SizedBox(width: 6),
                  Expanded(child: Container(height: 4, color: AppColors.verde)),
                  const SizedBox(width: 12),
                  const Text('PASO 2 DE 2',
                    style: TextStyle(fontSize: 10, letterSpacing: 1,
                                     color: AppColors.textoGris)),
                ],
              ),
              const SizedBox(height: 16),

              TarjetaOscura(
                icono: const CircleAvatar(radius: 20,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.build, color: Colors.white, size: 20)),
                etiqueta: 'EQUIPO SELECCIONADO',
                titulo: equipo?.nombre ?? 'Sin equipo',
                subtitulo: 'Ubicación: '
                    '${equipo == null || equipo.zonaNombre.isEmpty ? "—" : equipo.zonaNombre}',
              ),

              const SeccionHeader(icono: Icons.info_outline,
                titulo: 'PROGRAMACIÓN Y PRIORIDAD'),
              TarjetaBlanca(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Prioridad de la Intervención',
                      style: AppText.subtitulo),
                    const SizedBox(height: 12),
                    ChipsFila(
                      opciones: _prioridades,
                      colorActivo: AppColors.naranja,
                      inicial: _prioridadesModelo.indexOf(state.prioridad)
                          .clamp(0, _prioridades.length - 1),
                      onCambio: (i) => context
                          .read<CrearOrdenBloc>()
                          .add(PrioridadCambiada(_prioridadesModelo[i])),
                    ),
                    const SizedBox(height: 18),
                    const Text('Fecha de Intervención', style: AppText.subtitulo),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _elegirFecha(state.fechaLimite),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borde),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          const Icon(Icons.calendar_today_outlined, size: 17,
                            color: AppColors.textoGris),
                          const SizedBox(width: 10),
                          Text(_fechaTexto(state.fechaLimite),
                            style: const TextStyle(fontSize: 13.5,
                                                   color: AppColors.texto)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ══ RESPONSABLE ══
                    // Opcional: sin técnico la orden se publica "Sin asignar"
                    CampoSeleccion(
                      label: 'Técnico Responsable',
                      icono: Icons.engineering_outlined,
                      valor: switch (state.tecnico) {
                        null => null,
                        final u when u.especialidad.isEmpty => u.nombre,
                        final u => '${u.nombre} • ${u.especialidad}',
                      },
                      vacio: 'Sin asignar',
                      onTap: () => _elegirTecnico(state),
                    ),
                  ],
                ),
              ),

              SeccionHeader(
                icono: Icons.photo_camera_outlined,
                titulo: 'EVIDENCIA Y NOTAS',
                accion: '${state.fotos.length}/$maxFotosPorReporte · OPCIONAL',
              ),
              // Las fotos se suben al publicar, antes de crear la orden:
              // si una falla, la orden no se crea
              CuadriculaFotosLocales(
                imagenes: [for (final f in state.fotos) f.bytes],
                subidas: [for (final f in state.fotos) f.subida],
                puedeAgregar: state.puedeAgregarFoto,
                bloqueada: state.publicando,
                onAgregar: _agregarFoto,
                onQuitar: (i) => context
                    .read<CrearOrdenBloc>()
                    .add(FotoHallazgoQuitada(state.fotos[i].id)),
              ),
              const SizedBox(height: 16),

              const Text('Observaciones Técnicas Adicionales',
                style: AppText.subtitulo),
              const SizedBox(height: 10),
              CampoTexto(
                label: '',
                hint: 'Describa ruidos inusuales, fugas o comportamientos fuera '
                      'de lo normal observados en el equipo...',
                lineas: 3,
                controller: _obsCtrl,
              ),

              const SizedBox(height: 16),
              const TileAviso(
                icono: Icons.cloud_upload_outlined,
                titulo: 'Preparado para Sincronización',
                subtitulo: 'Al publicar, la orden se registrará en el servidor '
                           'central y se notificará al equipo de guardia.',
                color: AppColors.azul,
              ),

              const SizedBox(height: 20),
              BotonAncho(
                texto: state.progresoTexto ??
                    (state.publicando ? 'PUBLICANDO...' : 'PUBLICAR ORDEN'),
                icono: Icons.arrow_forward,
                onTap: state.paso2Valido && !state.publicando ? _publicar : null,
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
