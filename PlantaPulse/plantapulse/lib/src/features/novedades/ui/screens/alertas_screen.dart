import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../../../../core/errors/fallos.dart';
import '../../domain/usecases/alertas_criticas.dart';
import '../../../notificaciones/notificaciones.dart';

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  String? _usuarioId;
  Stream<List<Alerta>>? _avisos;
  Stream<List<AlertaCritica>>? _criticas;

  @override
  void initState() {
    super.initState();
    final usuario = context.read<SesionBloc>().state.usuario;
    _usuarioId = usuario?.uid;

    if (usuario == null) return;
    _avisos = context.read<ObservarAvisos>().ejecutar(usuario.uid);
    if (usuario.plantaId.isNotEmpty) {
      _criticas =
          context.read<ObservarAlertasCriticas>().ejecutar(usuario.plantaId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: 'Alertas de Planta',
      mostrarAtras: false,
      mostrarMenu: true,
      tabActiva: 1,
      cuerpo: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 12),
          if (_criticas != null)
            StreamBuilder<List<AlertaCritica>>(
              stream: _criticas,
              builder: (context, snap) {
                final error = snap.hasError
                    ? TileAviso(
                        icono: Icons.cloud_off,
                        titulo: 'No se pudieron cargar las alertas críticas',
                        subtitulo: FalloApp.mensajeDe(snap.error!),
                        color: AppColors.rojo,
                      )
                    : null;
                if (!snap.hasData) {
                  return error ?? const SizedBox.shrink();
                }

                final lista = snap.data!;
                if (lista.isEmpty && error == null) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (error != null) error,
                    if (lista.isNotEmpty)
                      const SeccionHeader(
                        titulo: 'ALERTAS CRÍTICAS ABIERTAS',
                      ),
                    for (final alerta in lista)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FilaAlerta(
                          key: ValueKey('alerta-critica-${alerta.id}'),
                          icono: alerta.tipo.icono,
                          titulo: alerta.tipo.etiqueta,
                          descripcion:
                              '${alerta.creadoPor.nombre}: ${alerta.descripcion}',
                          hora: alerta.hora,
                          color: AppColors.rojo,
                          noLeida: true,
                        ),
                      ),
                  ],
                );
              },
            ),
          if (_avisos == null)
            const TileAviso(
              icono: Icons.info_outline,
              titulo: 'Inicia sesión para consultar tus avisos.',
              color: AppColors.ambar,
            )
          else
            StreamBuilder<List<Alerta>>(
              stream: _avisos,
              builder: _construirAvisos,
            ),
          const SizedBox(height: 12),
          const TileAviso(
            icono: Icons.info_outline,
            titulo: 'La barra azul identifica los avisos no leídos. '
                'Toca un aviso para marcarlo como leído.',
            color: AppColors.azul,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _construirAvisos(
    BuildContext context,
    AsyncSnapshot<List<Alerta>> snap,
  ) {
    final error = snap.hasError
        ? TileAviso(
            icono: Icons.cloud_off,
            titulo: 'No se pudieron cargar tus avisos',
            subtitulo: FalloApp.mensajeDe(snap.error!),
            color: AppColors.rojo,
          )
        : null;
    if (!snap.hasData) {
      if (error != null) return error;
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final avisos = snap.data!;
    final sinLeer = avisos.where((aviso) => aviso.noLeida).length;
    final grupos = <String, List<Alerta>>{};
    for (final aviso in avisos) {
      grupos.putIfAbsent(aviso.grupo, () => []).add(aviso);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (error != null) error,
        SeccionHeader(
          titulo: 'AVISOS PERSONALES',
          accion: '$sinLeer SIN LEER',
          colorAccion: sinLeer == 0 ? AppColors.textoGris : AppColors.azul,
        ),
        if (avisos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Todavía no tienes avisos.',
                style: AppText.gris.segunTema(context),
              ),
            ),
          )
        else
          for (final grupo in const [
            'HOY',
            'AYER',
            'ESTA SEMANA',
            'ANTERIORES',
          ])
            if (grupos.containsKey(grupo)) ...[
              SeccionHeader(titulo: grupo),
              for (final aviso in grupos[grupo]!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FilaAlerta(
                    key: ValueKey('aviso-${aviso.id}'),
                    icono: aviso.tipo.icono,
                    titulo: aviso.titulo,
                    descripcion: aviso.descripcion,
                    hora: aviso.hora,
                    codigo: aviso.codigo,
                    color: aviso.tipo.color,
                    noLeida: aviso.noLeida,
                    onTap: () => _abrirAviso(aviso),
                  ),
                ),
            ],
      ],
    );
  }

  Future<void> _abrirAviso(Alerta aviso) async {
    final usuarioId = _usuarioId;
    if (usuarioId == null) return;

    try {
      if (aviso.noLeida) {
        await context.read<MarcarAvisoLeido>().ejecutar(
              usuarioId: usuarioId,
              avisoId: aviso.id,
            );
      }

      final ordenId = aviso.ordenId;
      if (ordenId == null) return;
      final orden = await context.read<OrdenRepositorio>().obtener(ordenId);
      if (!mounted) return;
      if (orden == null) {
        _mostrarError('La orden de este aviso ya no está disponible.');
        return;
      }
      await Navigator.pushNamed(
        context,
        Rutas.detalleOrden,
        arguments: orden,
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarError(FalloApp.mensajeDe(error));
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }
}
