// lib/src/features/reportes/ui/screens/llenar_reporte_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../../domain/usecases/reportes_casos.dart';
import '../bloc/llenar_reporte_bloc.dart';

/// Reporte de avance de una orden: texto, estado del trabajo, hasta cuatro
/// fotos y la bandera de alerta crítica.
///
/// Al publicar NO se actualiza la orden desde aquí: el servidor sube los
/// contadores, pone la portada y avanza el estado, y el cambio vuelve por
/// el stream.
class LlenarReporteScreen extends StatelessWidget {
  final Orden orden;

  const LlenarReporteScreen({super.key, required this.orden});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LlenarReporteBloc>(
      create: (context) => LlenarReporteBloc(
        subirEvidencia: context.read<SubirEvidencia>(),
        publicarReporte: context.read<PublicarReporte>(),
        ordenId: orden.id,
        plantaId: orden.plantaId,
      ),
      child: _LlenarReporteVista(orden: orden),
    );
  }
}

class _LlenarReporteVista extends StatefulWidget {
  final Orden orden;

  const _LlenarReporteVista({required this.orden});

  @override
  State<_LlenarReporteVista> createState() => _LlenarReporteVistaState();
}

class _LlenarReporteVistaState extends State<_LlenarReporteVista> {
  final _detallesCtrl = TextEditingController();

  // "Pendiente" no se reporta: si hay reporte, el trabajo ya empezó
  static const _estados = [
    EstadoTrabajo.enProgreso,
    EstadoTrabajo.bloqueado,
    EstadoTrabajo.resuelto,
  ];
  static const _iconosEstado = [
    Icons.play_circle_outline,
    Icons.block,
    Icons.check_circle_outline,
  ];

  @override
  void initState() {
    super.initState();
    final bloc = context.read<LlenarReporteBloc>();
    _detallesCtrl.addListener(
        () => bloc.add(DetallesCambiados(_detallesCtrl.text)));
  }

  @override
  void dispose() {
    _detallesCtrl.dispose();
    super.dispose();
  }

  Future<void> _agregarFoto() async {
    final bloc = context.read<LlenarReporteBloc>();
    final foto = await elegirFoto(context);
    if (foto != null) bloc.add(FotoAgregada(foto.bytes, foto.extension));
  }

  void _publicar() {
    final autor = context.read<SesionBloc>().state.usuario;
    if (autor == null) return;
    context.read<LlenarReporteBloc>().add(ReportePublicado(autor.ref));
  }

  void _alCambiarEstado(BuildContext context, LlenarReporteState state) {
    if (state.status == EstadoLlenarReporte.publicado) {
      // La orden ya cambió en el servidor; el detalle lo recibe por stream
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppColors.verde,
        content: Text('Reporte publicado'),
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LlenarReporteBloc, LlenarReporteState>(
      listenWhen: (antes, ahora) => antes.status != ahora.status,
      listener: _alCambiarEstado,
      builder: (context, state) {
        final orden = widget.orden;
        return PopScope(
          // No se sale a mitad de una subida
          canPop: !state.publicando,
          child: PantallaBase(
            titulo: 'Llenar reporte de avance',
            mostrarMenu: true,
            tabActiva: 0,
            cuerpo: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 14),

                TarjetaOscura(
                  icono: const Icon(Icons.description_outlined,
                      color: Colors.white, size: 26),
                  titulo: 'Resumen de Intervención',
                  subtitulo: 'ORDEN ID\n#${orden.codigo}\n\nEQUIPO\n'
                      '${orden.equipoNombre ?? orden.titulo}',
                  extra: orden.zonaNombre.isEmpty
                      ? null
                      : Row(children: [
                          PillEstado(texto: orden.zonaNombre,
                              color: Colors.white70),
                        ]),
                ),

                const SeccionHeader(icono: Icons.schedule,
                    titulo: 'ESTATUS DE AVANCE'),
                ChipsFila(
                  opciones: [for (final e in _estados) e.etiqueta],
                  iconos: _iconosEstado,
                  colorActivo: AppColors.ambar,
                  inicial: _estados.indexOf(state.estadoTrabajo).clamp(0, 2),
                  onCambio: (i) => context
                      .read<LlenarReporteBloc>()
                      .add(EstadoTrabajoCambiado(_estados[i])),
                ),

                SeccionHeader(
                  icono: Icons.info_outline,
                  titulo: 'DETALLES TÉCNICOS',
                  accion: 'REQUERIDO',
                  colorAccion:
                      state.valido ? AppColors.textoGris : AppColors.rojo,
                ),
                CampoTexto(
                  label: '',
                  hint: 'Describa el trabajo realizado, hallazgos técnicos y '
                      'ajustes de parámetros...',
                  lineas: 4,
                  controller: _detallesCtrl,
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    state.valido
                        ? '${state.detalles.length} caracteres'
                        : 'Mínimo 10 caracteres (${state.detalles.trim().length})',
                    style: AppText.gris),
                ),

                SeccionHeader(
                  icono: Icons.photo_camera_outlined,
                  titulo: 'EVIDENCIA FOTOGRÁFICA',
                  accion: '${state.fotos.length}/$maxFotosPorReporte · OPCIONAL',
                ),
                _cuadriculaFotos(state),

                const SizedBox(height: 16),
                FilaOpcion(
                  icono: Icons.priority_high,
                  titulo: 'Incidente Crítico',
                  subtitulo: 'Notificar al supervisor de inmediato',
                  color: state.esAlertaCritica
                      ? AppColors.rojo : AppColors.textoGris,
                  trailing: Switch(
                    value: state.esAlertaCritica,
                    activeThumbColor: AppColors.rojo,
                    onChanged: state.publicando
                        ? null
                        : (v) => context
                            .read<LlenarReporteBloc>()
                            .add(AlertaCriticaCambiada(v)),
                  ),
                ),

                if (state.status == EstadoLlenarReporte.error &&
                    state.mensajeError != null) ...[
                  const SizedBox(height: 12),
                  TileAviso(
                    icono: Icons.error_outline,
                    titulo: state.mensajeError!,
                    subtitulo: state.fotos.any((f) => f.subida)
                        ? 'Las fotos ya subidas no se volverán a subir al reintentar.'
                        : null,
                    color: AppColors.rojo,
                  ),
                ],

                const SizedBox(height: 20),
                BotonAncho(
                  texto: state.progresoTexto ??
                      (state.publicando ? 'PUBLICANDO...' : 'ENVIAR REPORTE'),
                  icono: Icons.arrow_forward,
                  onTap: state.valido && !state.publicando ? _publicar : null,
                ),
                const SizedBox(height: 10),
                const Center(child: Text(
                  'Al enviar, el registro se sincronizará con el sistema '
                  'central de PlantaPulse.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.textoGris))),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Hasta cuatro fotos. El recuadro de agregar desaparece al llenarse.
  Widget _cuadriculaFotos(LlenarReporteState state) {
    final bloc = context.read<LlenarReporteBloc>();
    return CuadriculaFotosLocales(
      imagenes: [for (final f in state.fotos) f.bytes],
      subidas: [for (final f in state.fotos) f.subida],
      puedeAgregar: state.puedeAgregarFoto,
      bloqueada: state.publicando,
      onAgregar: _agregarFoto,
      onQuitar: (i) => bloc.add(FotoQuitada(state.fotos[i].id)),
    );
  }
}
