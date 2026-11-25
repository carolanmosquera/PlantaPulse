// lib/src/features/novedades/ui/widgets/resolver_alerta_hoja.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../../domain/usecases/alertas_criticas.dart';

/// "Alerta solucionada" para supervisores y admin: muestra la alerta, pide
/// una nota opcional y la cierra. Devuelve true si se cerró, o null si se
/// cerró la hoja sin hacer nada.
class ResolverAlertaHoja extends StatefulWidget {
  final AlertaCritica alerta;

  const ResolverAlertaHoja({super.key, required this.alerta});

  static Future<bool?> mostrar(BuildContext context, AlertaCritica alerta) =>
      HojaFormulario.mostrar<bool>(context, ResolverAlertaHoja(alerta: alerta));

  @override
  State<ResolverAlertaHoja> createState() => _ResolverAlertaHojaState();
}

class _ResolverAlertaHojaState extends State<ResolverAlertaHoja> {
  final _nota = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Redibuja el contador de caracteres
    _nota.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  Future<void> _resolver() async {
    final resolver = context.read<ResolverAlertaCritica>();
    final navegador = Navigator.of(context);
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await resolver.ejecutar(alertaId: widget.alerta.id, nota: _nota.text);
      navegador.pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = FalloApp.mensajeDe(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.alerta;
    final largo = _nota.text.trim().length;
    final muyLarga = largo > ResolverAlertaCritica.maxNota;
    final gris = AppText.gris.segunTema(context);

    return HojaFormulario(
      titulo: 'Alerta crítica',
      error: _error,
      guardando: _guardando,
      textoGuardar: 'ALERTA SOLUCIONADA',
      textoGuardando: 'GUARDANDO...',
      iconoGuardar: Icons.task_alt,
      colorGuardar: AppColors.verde,
      alGuardar: muyLarga ? null : _resolver,
      campos: [
        // ══ La alerta ══
        TarjetaBlanca(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(a.tipo.icono, color: AppColors.rojo.segunTema(context)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(a.tipo.etiqueta,
                        style: AppText.subtitulo.segunTema(context)),
                  ),
                  Text(a.hora, style: gris),
                ],
              ),
              const SizedBox(height: 8),
              Text(a.descripcion, style: AppText.cuerpo.segunTema(context)),
              const SizedBox(height: 8),
              Text('Reportada por ${a.creadoPor.nombre}', style: gris),
              if (a.ubicacionTexto.isNotEmpty)
                Text(a.ubicacionTexto, style: gris),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ══ Nota de cierre (opcional) ══
        CampoTexto(
          label: 'Nota de cierre (opcional)',
          hint: 'Ej: se aisló la fuga y se revisó la zona',
          lineas: 3,
          controller: _nota,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$largo/${ResolverAlertaCritica.maxNota}',
            style: muyLarga
                ? AppText.gris.copyWith(color: AppColors.rojo.segunTema(context))
                : gris,
          ),
        ),
        const SizedBox(height: 8),
        TileAviso(
          icono: Icons.info_outline,
          titulo: 'Al marcarla como solucionada',
          subtitulo: 'Sale de las alertas abiertas y sus avisos se quitan de '
              'la bandeja de todos. Queda en el historial quién la cerró y '
              'cuándo.',
          color: AppColors.azul,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
