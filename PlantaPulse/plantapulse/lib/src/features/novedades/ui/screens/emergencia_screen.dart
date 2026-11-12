// lib/src/features/novedades/ui/screens/emergencia_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../../domain/usecases/alertas_criticas.dart';

/// KAN-90: el personal de planta elige la categoría, describe el incidente
/// y envía la alerta con su ubicación. Al guardarse, los supervisores la
/// reciben en tiempo real (ver EscuchaAlertasCriticas).
class EmergenciaScreen extends StatefulWidget {
  const EmergenciaScreen({super.key});
  @override
  State<EmergenciaScreen> createState() => _EmergenciaScreenState();
}

class _EmergenciaScreenState extends State<EmergenciaScreen> {
  final _descCtrl = TextEditingController();
  int _categoria = 0;
  bool _enviando = false;

  /// La ubicación se pide al abrir la pantalla, sin bloquear el envío.
  bool _buscandoGps = true;
  PuntoGps? _gps;

  @override
  void initState() {
    super.initState();
    _descCtrl.addListener(() => setState(() {}));
    _buscarUbicacion();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscarUbicacion() async {
    PuntoGps? punto;
    try {
      punto = await context.read<ObtenerUbicacion>().ejecutar();
    } catch (_) {
      punto = null;
    }
    if (!mounted) return;
    setState(() {
      _gps = punto;
      _buscandoGps = false;
    });
  }

  int get _largo => _descCtrl.text.trim().length;

  bool get _puedeEnviar =>
      !_enviando &&
      _largo >= EnviarAlertaCritica.minDescripcion &&
      _descCtrl.text.length <= EnviarAlertaCritica.maxDescripcion;

  TipoEmergencia get _tipo => TipoEmergencia.values[_categoria];

  String get _textoUbicacion {
    if (_buscandoGps) return 'Obteniendo ubicación…';
    final g = _gps;
    if (g == null) {
      return 'Ubicación no disponible. La alerta se enviará sin GPS.';
    }
    return 'GPS: ${g.latitude.toStringAsFixed(5)}, '
        '${g.longitude.toStringAsFixed(5)}';
  }

  Future<void> _confirmar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: AppColors.rojo, size: 40),
        title: const Text('¿Confirmar alerta crítica?'),
        content: Text('Se notificará de inmediato a todos los supervisores '
            'de turno sobre: ${_tipo.etiqueta}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ENVIAR',
                style: TextStyle(
                    color: AppColors.rojo, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) await _enviar();
  }

  Future<void> _enviar() async {
    final usuario = context.read<SesionBloc>().state.usuario;
    if (usuario == null) return;
    final mensajes = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    final enviarAlerta = context.read<EnviarAlertaCritica>();

    setState(() => _enviando = true);
    try {
      await enviarAlerta.ejecutar(
        usuario: usuario,
        tipo: _tipo,
        descripcion: _descCtrl.text,
        ubicacion: _gps,
      );
      mensajes.showSnackBar(const SnackBar(
          content: Text('Alerta enviada a supervisores'),
          backgroundColor: AppColors.rojo));
      if (mounted) navegador.pop();
    } catch (e) {
      // La alerta NO se guardó: se queda en pantalla para reintentar
      mensajes.showSnackBar(SnackBar(
          content: Text(FalloApp.mensajeDe(e)),
          backgroundColor: AppColors.rojo));
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: 'Reporte de Emergencia',
      tabActiva: 1,
      cuerpo: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 14),

          const TileAviso(
            icono: Icons.error_outline,
            titulo: 'Utilice esta pantalla únicamente para incidentes que '
                'requieran intervención inmediata.',
            color: AppColors.textoGris,
          ),
          const SizedBox(height: 18),

          const Row(children: [
            Icon(Icons.error_outline, color: AppColors.rojo, size: 22),
            SizedBox(width: 8),
            Text('Alerta Crítica',
                style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: AppColors.rojo)),
          ]),
          const SizedBox(height: 4),
          const Text('PROTOCOLO DE ACCIÓN INMEDIATA',
              style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: AppColors.textoGris)),

          const SeccionHeader(titulo: 'Categoría del Incidente'),
          ChipsFila(
            opciones: [for (final t in TipoEmergencia.values) t.etiqueta],
            iconos: [for (final t in TipoEmergencia.values) t.icono],
            envolver: true, // ← se acomodan en 2 filas
            colorActivo: AppColors.rojo,
            onCambio: (i) => setState(() => _categoria = i),
          ),

          SeccionHeader(
            titulo: 'Descripción del Hallazgo',
            accion:
                '${_descCtrl.text.length}/${EnviarAlertaCritica.maxDescripcion}',
            colorAccion:
                _descCtrl.text.length > EnviarAlertaCritica.maxDescripcion
                    ? AppColors.rojo
                    : AppColors.textoGris,
          ),
          CampoTexto(
            label: '',
            hint: 'Detalle la situación, ubicación exacta y riesgos '
                'inminentes...',
            lineas: 4,
            controller: _descCtrl,
          ),

          const SizedBox(height: 16),
          FilaOpcion(
            icono: Icons.place_outlined,
            titulo: 'Ubicación Detectada',
            subtitulo: _textoUbicacion,
          ),
          const SizedBox(height: 12),
          const TileAviso(
            icono: Icons.info_outline,
            titulo: 'Asegure su propia integridad física antes de reportar.',
            color: AppColors.ambar,
          ),

          const SizedBox(height: 20),
          BotonAncho(
            texto: _enviando ? 'ENVIANDO…' : 'ENVIAR ALERTA AHORA',
            icono: _enviando ? Icons.hourglass_top : Icons.send,
            estilo: EstiloBoton.peligro,
            onTap: _puedeEnviar ? _confirmar : null,
          ),
          const SizedBox(height: 10),
          const Center(
              child: Text('SE NOTIFICARÁ A TODOS LOS SUPERVISORES DE TURNO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 9.5,
                      letterSpacing: 1,
                      color: AppColors.textoGris))),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
