// lib/src/core/offline/aviso_reportes_pendientes.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/app_colors.dart';
import 'cola_reportes_cubit.dart';

/// "N reportes sin enviar": solo aparece si hay reportes guardados en el
/// teléfono por falta de conexión. Se envían solos; "Reintentar" no
/// espera al siguiente turno.
class AvisoReportesPendientes extends StatelessWidget {
  const AvisoReportesPendientes({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ColaReportesCubit, ColaReportesEstado>(
      buildWhen: (a, b) =>
          a.pendientes != b.pendientes || a.sincronizando != b.sincronizando,
      builder: (context, s) {
        if (s.pendientes == 0) return const SizedBox.shrink();
        final color = AppColors.ambar;
        return Container(
          key: const ValueKey('aviso-reportes-pendientes'),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.cloud_off, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.pendientes == 1
                          ? '1 reporte sin enviar'
                          : '${s.pendientes} reportes sin enviar',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.texto.segunTema(context),
                      ),
                    ),
                    Text(
                      'Están guardados en el teléfono y se enviarán solos '
                      'al volver la conexión.',
                      style: AppText.gris.segunTema(context),
                    ),
                  ],
                ),
              ),
              s.sincronizando
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TextButton(
                      onPressed: () =>
                          context.read<ColaReportesCubit>().sincronizar(),
                      child: const Text('Reintentar'),
                    ),
            ],
          ),
        );
      },
    );
  }
}
