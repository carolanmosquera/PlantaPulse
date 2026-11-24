// lib/src/features/ordenes/ui/widgets/progreso_ia_tarjeta.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../bloc/progreso_ia_bloc.dart';

/// "CALCULAR PROGRESO" para el supervisor, en los reportes de la orden.
/// La IA lee los reportes y propone cuánto se lleva y qué podría faltar,
/// con una barra SUGESTIVA: no es una medición, y la tarjeta lo dice.
class ProgresoIaTarjeta extends StatelessWidget {
  final Orden orden;
  final List<Reporte> reportes;

  const ProgresoIaTarjeta({
    super.key,
    required this.orden,
    required this.reportes,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProgresoIaBloc>(
      create: (context) =>
          ProgresoIaBloc(calcularProgreso: context.read<CalcularProgreso>()),
      child: _ProgresoIaVista(orden: orden, reportes: reportes),
    );
  }
}

class _ProgresoIaVista extends StatelessWidget {
  final Orden orden;
  final List<Reporte> reportes;

  const _ProgresoIaVista({required this.orden, required this.reportes});

  void _calcular(BuildContext context) => context
      .read<ProgresoIaBloc>()
      .add(ProgresoSolicitado(orden: orden, reportes: reportes));

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgresoIaBloc, ProgresoIaState>(
      builder: (context, state) {
        final progreso = state.progreso;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (progreso != null)
                _resultado(context, state, progreso)
              else
                // La primera llamada puede tardar (arranque en frío):
                // botón deshabilitado y barra indeterminada mientras piensa
                BotonAncho(
                  texto: state.calculando
                      ? 'CALCULANDO PROGRESO...'
                      : 'CALCULAR PROGRESO',
                  icono: state.calculando
                      ? Icons.hourglass_top
                      : Icons.auto_awesome,
                  estilo: EstiloBoton.borde,
                  onTap: state.calculando ? null : () => _calcular(context),
                ),
              if (state.calculando && progreso == null) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: AppColors.borde.segunTema(context),
                  color: AppColors.naranja,
                ),
              ],
              if (state.mensajeError != null) ...[
                const SizedBox(height: 8),
                TileAviso(
                  icono: Icons.error_outline,
                  titulo: state.mensajeError!,
                  color: AppColors.rojo,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _resultado(
    BuildContext context,
    ProgresoIaState state,
    ProgresoOrdenIa progreso,
  ) {
    final hayNuevos = reportes.length != state.reportesAnalizados;
    // Los estilos pasan por segunTema: en modo oscuro la tarjeta es oscura
    // y el texto tiene que aclararse
    final etiqueta = AppText.label.segunTema(context);
    final cuerpo = AppText.cuerpo.segunTema(context);
    final gris = AppColors.textoGris.segunTema(context);
    return TarjetaBlanca(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: AppColors.naranja),
              const SizedBox(width: 6),
              Expanded(
                child: Text('PROGRESO ESTIMADO POR IA', style: etiqueta),
              ),
              Text('≈ ${progreso.porcentaje} %',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.naranja)),
            ],
          ),
          const SizedBox(height: 10),
          // Naranja (el color del asistente), no verde: no es un avance
          // medido, es una sugerencia
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progreso.porcentaje / 100,
              minHeight: 10,
              backgroundColor: AppColors.naranja.withValues(alpha: 0.15),
              color: AppColors.naranja,
              semanticsLabel: 'Progreso estimado por IA',
              semanticsValue: '${progreso.porcentaje} %',
            ),
          ),
          const SizedBox(height: 14),
          Text('Lo que se lleva', style: etiqueta),
          const SizedBox(height: 4),
          Text(progreso.resumen, style: cuerpo),
          if (progreso.falta.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Lo que podría faltar', style: etiqueta),
            const SizedBox(height: 4),
            Text(progreso.falta, style: cuerpo),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  hayNuevos
                      ? 'Hay reportes nuevos desde este cálculo.'
                      : 'Basado en ${state.reportesAnalizados} '
                          '${state.reportesAnalizados == 1 ? 'reporte' : 'reportes'}.',
                  style: TextStyle(
                      fontSize: 11.5,
                      color: hayNuevos ? AppColors.naranja : gris),
                ),
              ),
              TextButton.icon(
                onPressed: state.calculando ? null : () => _calcular(context),
                icon: state.calculando
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh, size: 16),
                label: Text(state.calculando ? 'Calculando...' : 'Recalcular'),
              ),
            ],
          ),
          const Divider(height: 16),
          // El aviso va al final, siempre visible con el resultado
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 14, color: gris),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Análisis generado con criterio de IA a partir de los '
                  'reportes. Es una estimación orientativa y no debe '
                  'tomarse como literal.',
                  style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: gris,
                      height: 1.35),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
