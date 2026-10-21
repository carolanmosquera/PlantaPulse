// lib/src/core/components/orden_card.dart
import 'package:flutter/material.dart';
import 'package:plantapulse/src/core/theme/app_colors.dart';
import 'package:plantapulse/src/core/components/pill_estado.dart';
import 'package:plantapulse/src/core/components/meta_row.dart';

enum EstiloOrden { conFoto, conBarra }

class OrdenCard extends StatelessWidget {
  final String codigo;
  final String titulo;
  final String ubicacion;
  final String estado;
  final Color estadoColor;
  final String hora;
  final String prioridad;
  final String? fotoUrl;
  final EstiloOrden estilo;
  final VoidCallback? onTap;

  /// La orden no tiene responsable: se marca en gris bajo la ubicación.
  final bool sinAsignar;

  /// Reportes de avance publicados. Con 0 no se muestra nada.
  final int reportes;

  const OrdenCard({
    super.key,
    required this.codigo,
    required this.titulo,
    required this.ubicacion,
    required this.estado,
    required this.estadoColor,
    required this.hora,
    required this.prioridad,
    this.fotoUrl,
    this.estilo = EstiloOrden.conFoto,
    this.onTap,
    this.sinAsignar = false,
    this.reportes = 0,
  });

  @override
  Widget build(BuildContext context) {
    final conBarra = estilo == EstiloOrden.conBarra;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          // Un ÚNICO borde, y uniforme. La barra de color NO va aquí.
          border: Border.all(color: AppColors.borde),
        ),
        // ClipRRect recorta el contenido para que la foto y la barra
        // respeten las esquinas redondeadas de la tarjeta.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11), // 12 del contenedor - 1 del borde
          child: IntrinsicHeight(
            // IntrinsicHeight permite que la barra de 4px tome la altura
            // completa de la tarjeta sin conocerla de antemano.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (conBarra) Container(width: 4, color: estadoColor),
                Expanded(child: _contenido()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenido() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Foto superior con la píldora encima (solo variante del Feed)
        if (estilo == EstiloOrden.conFoto && fotoUrl != null)
          Stack(
            children: [
              Image.network(
                fotoUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                // Si la imagen falla, mostramos un bloque gris en vez de romper la UI
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: AppColors.borde,
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: Colors.white),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: PillEstado(
                    texto: estado, color: estadoColor, relleno: true),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Text(
                  codigo,
                  style: const TextStyle(
                      fontSize: 10, color: Colors.white, letterSpacing: 0.5),
                ),
              ),
            ],
          ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabecera de la variante "Mis Tareas"
              if (estilo == EstiloOrden.conBarra) ...[
                Row(
                  children: [
                    Expanded(child: Text(codigo, style: AppText.gris)),
                    PillEstado(texto: estado, color: estadoColor),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              Text(
                titulo,
                style: AppText.subtitulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              MetaRow(icono: Icons.place_outlined, texto: ubicacion),
              if (sinAsignar) ...[
                const SizedBox(height: 4),
                const MetaRow(icono: Icons.person_off_outlined,
                    texto: 'Sin asignar'),
              ],
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.borde),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.schedule,
                      size: 14, color: AppColors.textoGris),
                  const SizedBox(width: 4),
                  Text(hora, style: AppText.gris),
                  if (reportes > 0) ...[
                    const SizedBox(width: 10),
                    const Icon(Icons.forum_outlined,
                        size: 14, color: AppColors.textoGris),
                    const SizedBox(width: 4),
                    Text(reportes == 1 ? '1 reporte' : '$reportes reportes',
                        style: AppText.gris),
                  ],
                  const SizedBox(width: 12),
                  Flexible(
                    child: PillEstado(texto: prioridad, color: estadoColor),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward,
                      size: 16, color: AppColors.textoGris),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}