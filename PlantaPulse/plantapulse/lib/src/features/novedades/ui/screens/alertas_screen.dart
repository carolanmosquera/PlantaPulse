// lib/src/features/novedades/ui/screens/alertas_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../../../../core/data/datos_demo.dart';
import '../../domain/usecases/alertas_criticas.dart';

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  /// Alertas críticas abiertas de la planta (KAN-90). Null si no hay
  /// sesión de planta o el servicio no está disponible.
  Stream<List<AlertaCritica>>? _criticas;

  @override
  void initState() {
    super.initState();
    final plantaId = context.read<SesionBloc>().state.usuario?.plantaId ?? '';
    if (plantaId.isEmpty) return;
    try {
      _criticas = context.read<ObservarAlertasCriticas>().ejecutar(plantaId);
    } catch (_) {
      _criticas = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Agrupa por el getter 'grupo' (calculado desde createdAt),
    // conservando el orden de aparición
    final grupos = <String, List<Alerta>>{};
    for (final a in alertasDemo) {
      grupos.putIfAbsent(a.grupo, () => []).add(a);
    }

    return PantallaBase(
      titulo: 'Alertas de Planta',
      mostrarAtras: false,
      mostrarMenu: true,
      tabActiva: 1,
      cuerpo: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 12),

          // ══ BARRA DE FILTROS ══
          Row(
            children: [
              _botonFiltro(context, Icons.filter_list, 'Filtrar'),
              const SizedBox(width: 8),
              _botonFiltro(context, Icons.calendar_today_outlined, 'Fecha'),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 15,
                         color: AppColors.textoGris.segunTema(context)),
                    SizedBox(width: 5),
                    Text('Limpiar leídas',
                      style: TextStyle(fontSize: 12,
                                       color: AppColors.textoGris.segunTema(context))),
                  ],
                ),
              ),
            ],
          ),

          // ══ ALERTAS CRÍTICAS ABIERTAS (tiempo real) ══
          if (_criticas != null)
            StreamBuilder<List<AlertaCritica>>(
              stream: _criticas,
              builder: (context, snap) {
                final lista = snap.data ?? const <AlertaCritica>[];
                if (lista.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SeccionHeader(titulo: 'ALERTAS CRÍTICAS ABIERTAS'),
                    for (final a in lista)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FilaAlerta(
                          icono: a.tipo.icono,
                          titulo: a.tipo.etiqueta,
                          descripcion:
                              '${a.creadoPor.nombre}: ${a.descripcion}',
                          hora: a.hora,
                          color: AppColors.rojo,
                          noLeida: true,
                        ),
                      ),
                  ],
                );
              },
            ),

          // ══ GRUPOS ══
          for (final entrada in grupos.entries) ...[
            SeccionHeader(titulo: entrada.key),
            ...entrada.value.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FilaAlerta(
                icono: a.tipo.icono,
                titulo: a.titulo,
                descripcion: a.descripcion,
                hora: a.hora,
                codigo: a.codigo,
                color: a.tipo.color,
                noLeida: a.noLeida,
              ),
            )),
          ],

          const SizedBox(height: 12),
          const TileAviso(
            icono: Icons.settings_outlined,
            titulo: 'Gestiona tus preferencias de alertas en Ajustes',
            color: AppColors.azul,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _botonFiltro(BuildContext context, IconData icono, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borde.segunTema(context)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: AppColors.textoGris.segunTema(context)),
          const SizedBox(width: 6),
          Text(texto, style: TextStyle(fontSize: 12.5,
                                             color: AppColors.texto.segunTema(context))),
        ],
      ),
    );
  }
}