
import 'package:flutter/material.dart';
import 'servicio_offline.dart';

class IndicadorOffline extends StatelessWidget {
  final ServicioOffline servicio;

  const IndicadorOffline({
    super.key,
    required this.servicio,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: servicio,
      builder: (context, _) {
        final conectado = servicio.conectado;
        final pendientes = servicio.pendientes;
        final sincronizando = servicio.sincronizando;

        final texto = sincronizando
            ? 'Sincronizando reportes...'
            : !conectado
                ? 'Sin conexión · $pendientes pendientes'
                : pendientes > 0
                    ? 'Pendientes de sincronizar: $pendientes'
                    : 'Sincronizado';

        return Align(
          alignment: Alignment.centerLeft,
          child: Chip(
            avatar: Icon(
              sincronizando
                  ? Icons.sync
                  : conectado
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
              size: 18,
              color: conectado
                  ? Colors.green
                  : Colors.orange,
            ),
            label: Text(
              texto,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}
