// lib/src/screens/solicitudes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/app_colors.dart';
import '../components/widgets.dart';
import '../blocs/auth/auth_bloc.dart';
import '../models/firestore_helpers.dart';
import '../models/planta.dart';
import '../models/usuario.dart';
import '../repositories/planta_repository.dart';
import '../repositories/usuario_repository.dart';

/// Bandeja del admin: cuentas registradas que esperan aprobación.
/// Se actualiza en tiempo real: una solicitud nueva aparece sola.
class SolicitudesScreen extends StatefulWidget {
  const SolicitudesScreen({super.key});

  @override
  State<SolicitudesScreen> createState() => _SolicitudesScreenState();
}

class _SolicitudesScreenState extends State<SolicitudesScreen> {
  // El stream se crea una sola vez: si se creara en build, cada
  // redibujado abriría una suscripción nueva a Firestore.
  late final Stream<List<Usuario>> _solicitudes =
      context.read<UsuarioRepository>().solicitudesPendientes();

  void _abrirSolicitud(Usuario solicitante) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _HojaSolicitud(solicitante: solicitante),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: 'Solicitudes de registro',
      tabActiva: 2,
      cuerpo: StreamBuilder<List<Usuario>>(
        stream: _solicitudes,
        builder: (context, snap) {
          if (snap.hasError) {
            // El caso típico: falta publicar el índice compuesto
            // (estado + createdAt) o las reglas nuevas.
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: TileAviso(
                  icono: Icons.error_outline,
                  titulo: 'No se pudieron cargar las solicitudes',
                  subtitulo: '${snap.error}',
                  color: AppColors.rojo,
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final solicitudes = snap.data!;
          if (solicitudes.isEmpty) {
            return const Center(
              child: Text('No hay solicitudes pendientes', style: AppText.gris),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: solicitudes.length,
            itemBuilder: (context, i) {
              final u = solicitudes[i];
              return FilaOpcion(
                icono: Icons.person_add_alt_1_outlined,
                titulo: u.nombre,
                subtitulo: '${u.email}\n${fechaCorta(u.createdAt)}',
                color: AppColors.ambar,
                onTap: () => _abrirSolicitud(u),
              );
            },
          );
        },
      ),
    );
  }
}

// ══════════ Hoja inferior: aprobar o rechazar ══════════

class _HojaSolicitud extends StatefulWidget {
  final Usuario solicitante;
  const _HojaSolicitud({required this.solicitante});

  @override
  State<_HojaSolicitud> createState() => _HojaSolicitudState();
}

class _HojaSolicitudState extends State<_HojaSolicitud> {
  // El admin solo asigna supervisor o técnico, nunca otro admin
  static const _roles = [RolUsuario.supervisor, RolUsuario.tecnico];

  late final Future<List<Planta>> _plantas =
      context.read<PlantaRepository>().activas();

  RolUsuario? _rol;
  Planta? _planta;
  bool _enviando = false;

  bool get _puedeAprobar => _rol != null && _planta != null && !_enviando;

  Future<void> _decidir({required bool aprobar}) async {
    final repo = context.read<UsuarioRepository>();
    final admin = context.read<AuthBloc>().state.usuario!.ref;
    final navegador = Navigator.of(context);
    final avisos = ScaffoldMessenger.of(context);
    final nombre = widget.solicitante.nombre;

    setState(() => _enviando = true);
    try {
      if (aprobar) {
        await repo.aprobar(
          widget.solicitante.uid,
          rol: _rol!,
          plantaId: _planta!.id,
          aprobadoPor: admin,
        );
      } else {
        await repo.rechazar(widget.solicitante.uid, admin);
      }
      navegador.pop();
      avisos.showSnackBar(SnackBar(
        content: Text(aprobar
            ? '$nombre aprobado como ${_rol!.etiqueta}'
            : 'Solicitud de $nombre rechazada'),
        backgroundColor: aprobar ? AppColors.verde : AppColors.rojo,
      ));
    } catch (e) {
      if (mounted) setState(() => _enviando = false);
      avisos.showSnackBar(SnackBar(
        content: Text('No se pudo guardar la decisión: $e'),
        backgroundColor: AppColors.rojo,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.solicitante;

    return Padding(
      // Deja espacio al teclado y a la barra de gestos
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Solicitante ──
          Text(s.nombre, style: AppText.titulo),
          const SizedBox(height: 4),
          MetaRow(icono: Icons.mail_outline, texto: s.email),
          const SizedBox(height: 4),
          MetaRow(icono: Icons.schedule,
              texto: 'Solicitado ${fechaCorta(s.createdAt)}'),
          const SizedBox(height: 20),

          // ── Asignación ──
          CampoDropdown<RolUsuario>(
            label: 'ROL EN LA PLANTA',
            hint: 'Seleccionar rol',
            icono: Icons.badge_outlined,
            valor: _rol,
            opciones: _roles,
            textoDe: (r) => r.etiqueta,
            onCambio: (r) => setState(() => _rol = r),
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<Planta>>(
            future: _plantas,
            builder: (context, snap) {
              if (snap.hasError) {
                return TileAviso(
                  icono: Icons.error_outline,
                  titulo: 'No se pudieron cargar las plantas',
                  subtitulo: '${snap.error}',
                  color: AppColors.rojo,
                );
              }
              final plantas = snap.data ?? const <Planta>[];
              if (snap.hasData && plantas.isEmpty) {
                return const TileAviso(
                  icono: Icons.factory_outlined,
                  titulo: 'No hay plantas registradas',
                  subtitulo: 'Crea documentos en la colección "plantas" '
                      'desde la consola de Firebase.',
                  color: AppColors.ambar,
                );
              }
              return CampoDropdown<Planta>(
                label: 'SEDE / PLANTA DE OPERACIÓN',
                hint: snap.hasData ? 'Seleccionar planta' : 'Cargando plantas...',
                icono: Icons.factory_outlined,
                valor: _planta,
                opciones: plantas,
                textoDe: (p) => p.nombre,
                onCambio: (p) => setState(() => _planta = p),
              );
            },
          ),
          const SizedBox(height: 24),

          // ── Decisión ──
          BotonAncho(
            texto: 'APROBAR',
            icono: Icons.check,
            color: AppColors.verde,
            onTap: _puedeAprobar ? () => _decidir(aprobar: true) : null,
          ),
          const SizedBox(height: 10),
          BotonAncho(
            texto: 'RECHAZAR',
            icono: Icons.close,
            estilo: EstiloBoton.borde,
            color: AppColors.rojo,
            onTap: _enviando ? null : () => _decidir(aprobar: false),
          ),
        ],
      ),
    );
  }
}
