// lib/src/screens/alertas_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/alerta.dart';
import '../models/datos_demo.dart';
import '../components/widgets.dart';

class AlertasScreen extends StatelessWidget {
  const AlertasScreen({super.key});

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
              _botonFiltro(Icons.filter_list, 'Filtrar'),
              const SizedBox(width: 8),
              _botonFiltro(Icons.calendar_today_outlined, 'Fecha'),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: const Row(
                  children: [
                    Icon(Icons.delete_outline, size: 15,
                         color: AppColors.textoGris),
                    SizedBox(width: 5),
                    Text('Limpiar leídas',
                      style: TextStyle(fontSize: 12,
                                       color: AppColors.textoGris)),
                  ],
                ),
              ),
            ],
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

  Widget _botonFiltro(IconData icono, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borde),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: AppColors.textoGris),
          const SizedBox(width: 6),
          Text(texto, style: const TextStyle(fontSize: 12.5,
                                             color: AppColors.texto)),
        ],
      ),
    );
  }
}