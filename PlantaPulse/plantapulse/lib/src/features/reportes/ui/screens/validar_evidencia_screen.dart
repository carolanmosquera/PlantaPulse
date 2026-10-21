// lib/src/features/reportes/ui/screens/validar_evidencia_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../../domain/usecases/reportes_casos.dart';

/// El supervisor revisa la evidencia de una orden en "validando" y decide:
/// aprobar y cerrar, o devolverla con observaciones.
///
/// Sin mensaje de éxito: cerrar y devolver son update sin .select(), y un
/// rechazo de RLS no da error. Se vuelve al detalle, que muestra el estado
/// que de verdad quedó en el servidor (llega por el stream).
class ValidarEvidenciaScreen extends StatefulWidget {
  final Orden orden;

  const ValidarEvidenciaScreen({super.key, required this.orden});

  @override
  State<ValidarEvidenciaScreen> createState() => _ValidarEvidenciaScreenState();
}

class _ValidarEvidenciaScreenState extends State<ValidarEvidenciaScreen> {
  final _obsCtrl = TextEditingController();
  bool _enviando = false;

  late final Stream<List<Reporte>> _reportes =
      context.read<ObservarReportesDeOrden>().ejecutar(widget.orden.id);

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _resolver({required bool aprobar}) async {
    final observaciones = _obsCtrl.text.trim();
    final avisos = ScaffoldMessenger.of(context);
    if (!aprobar && observaciones.isEmpty) {
      // El técnico tiene que saber qué corregir
      avisos.showSnackBar(const SnackBar(
        backgroundColor: AppColors.rojo,
        content: Text('Escribe qué hay que corregir antes de devolver la orden.'),
      ));
      return;
    }
    final supervisor = context.read<SesionBloc>().state.usuario;
    if (supervisor == null) return;
    final cerrar = context.read<CerrarOrden>();
    final devolver = context.read<DevolverOrden>();
    final navegador = Navigator.of(context);

    setState(() => _enviando = true);
    try {
      if (aprobar) {
        // El último mantenimiento del equipo lo escribe el servidor
        await cerrar.ejecutar(
          ordenId: widget.orden.id,
          validadaPor: supervisor.ref,
          observaciones: observaciones,
        );
      } else {
        await devolver.ejecutar(
            ordenId: widget.orden.id, observaciones: observaciones);
      }
      navegador.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      avisos.showSnackBar(SnackBar(
        backgroundColor: AppColors.rojo,
        content: Text(FalloApp.mensajeDe(e)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final orden = widget.orden;
    final urlDe = context.read<UrlDeEvidencia>();

    return PantallaBase(
      titulo: 'Validar Evidencia',
      mostrarMenu: true,
      tabActiva: 0,
      cuerpo: StreamBuilder<List<Reporte>>(
        stream: _reportes,
        builder: (context, snap) {
          final reportes = snap.data ?? const <Reporte>[];
          final ultimo = reportes.lastOrNull;
          final fotos = [
            for (final r in reportes)
              for (final e in r.evidencias) urlDe.ejecutar(e.ruta),
          ];

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 14),

              Row(
                children: [
                  Text('OT #${orden.codigo}', style: const TextStyle(
                      fontSize: 11.5, letterSpacing: 0.5,
                      color: AppColors.textoGris)),
                  const Spacer(),
                  PillEstado(texto: orden.estado.etiqueta,
                      color: orden.estado.color),
                ],
              ),
              const SizedBox(height: 8),
              Text(orden.titulo, style: const TextStyle(fontSize: 18,
                  fontWeight: FontWeight.bold, color: AppColors.texto,
                  height: 1.3)),

              SeccionHeader(icono: Icons.photo_camera_outlined,
                  titulo: 'Evidencia Fotográfica',
                  accion: '${fotos.length} fotos'),
              if (snap.hasError)
                TileAviso(icono: Icons.cloud_off,
                    titulo: FalloApp.mensajeDe(snap.error!),
                    color: AppColors.rojo)
              else if (!snap.hasData)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (fotos.isEmpty)
                const TileAviso(icono: Icons.image_not_supported_outlined,
                    titulo: 'Los reportes de esta orden no tienen fotos',
                    color: AppColors.textoGris)
              else
                GaleriaFotos(urls: fotos, columnas: 2),

              const SeccionHeader(icono: Icons.description_outlined,
                  titulo: 'Resumen del Reporte'),
              TarjetaBlanca(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ultimo == null
                          ? 'Aún no hay reportes del técnico'
                          : 'Último de ${reportes.length} '
                            '${reportes.length == 1 ? "reporte" : "reportes"}',
                      style: AppText.gris),
                    if (ultimo != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.fondo,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(ultimo.detalles,
                          style: const TextStyle(fontSize: 13.5, height: 1.5,
                              color: AppColors.texto)),
                      ),
                      const SizedBox(height: 16),
                      MetaRow(icono: Icons.person_outline, texto: 'TÉCNICO',
                          valor: ultimo.autor.nombre),
                      const SizedBox(height: 12),
                      MetaRow(icono: Icons.calendar_today_outlined,
                          texto: 'FECHA DE EJECUCIÓN',
                          valor: fechaCorta(ultimo.createdAt)),
                    ],
                    if (orden.equipoNombre != null) ...[
                      const SizedBox(height: 12),
                      MetaRow(icono: Icons.build_outlined,
                          texto: 'EQUIPO INTERVENIDO',
                          valor: orden.equipoNombre),
                    ],
                  ],
                ),
              ),

              const SeccionHeader(icono: Icons.chat_bubble_outline,
                  titulo: 'Observaciones del Supervisor'),
              CampoTexto(
                label: '',
                hint: 'Escriba comentarios adicionales o motivos de corrección...',
                lineas: 3,
                controller: _obsCtrl,
              ),
              const SizedBox(height: 6),
              const Text(
                'Las observaciones serán visibles para el equipo técnico. '
                'Para solicitar correcciones son obligatorias.',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic,
                    color: AppColors.textoGris)),

              const SizedBox(height: 20),
              BotonAncho(
                texto: 'APROBAR Y CERRAR ORDEN',
                icono: Icons.assignment_turned_in_outlined,
                onTap: _enviando ? null : () => _resolver(aprobar: true),
              ),
              const SizedBox(height: 12),
              BotonAncho(
                texto: 'SOLICITAR CORRECCIONES',
                icono: Icons.error_outline,
                estilo: EstiloBoton.peligro,
                onTap: _enviando ? null : () => _resolver(aprobar: false),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
