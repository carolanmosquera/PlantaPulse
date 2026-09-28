// lib/src/screens/espera_aprobacion_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/app_colors.dart';
import '../theme/rutas.dart';
import '../components/widgets.dart';
import '../blocs/auth/auth_bloc.dart';

/// Pantalla para cuentas que aún no pueden entrar al feed.
/// Tiene dos modos según `state.sesion`: pendiente o rechazada.
///
/// Scaffold simple y no PantallaBase: aquí no va barra inferior.
class EsperaAprobacionScreen extends StatelessWidget {
  const EsperaAprobacionScreen({super.key});

  void _alCambiarAuth(BuildContext context, AuthState state) {
    if (state.hayError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.mensajeError ?? 'No se pudo consultar tu cuenta'),
          backgroundColor: AppColors.rojo,
        ),
      );
      return;
    }

    switch (state.sesion) {
      case EstadoSesion.activa:
        Navigator.pushNamedAndRemoveUntil(context, Rutas.feed, (_) => false);
      case EstadoSesion.sinCuenta:
        Navigator.pushNamedAndRemoveUntil(context, Rutas.login, (_) => false);
      default:
        break; // pendiente ↔ rechazada: el builder cambia de modo
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (antes, ahora) =>
            antes.sesion != ahora.sesion ||
            (ahora.hayError && antes.accion != ahora.accion),
        listener: _alCambiarAuth,
        builder: (context, state) {
          final rechazada = state.sesion == EstadoSesion.rechazada;
          final email = state.usuario?.email ?? '';

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),

                  // ── Ícono ──
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: (rechazada ? AppColors.rojo : AppColors.ambar)
                            .withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        rechazada ? Icons.block : Icons.hourglass_top,
                        size: 52,
                        color: rechazada ? AppColors.rojo : AppColors.ambar,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Textos ──
                  Text(
                    rechazada ? 'Acceso denegado' : 'Solicitud enviada',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22,
                                           fontWeight: FontWeight.bold,
                                           color: AppColors.azul),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    rechazada
                        ? 'Tu solicitud de registro fue rechazada. '
                          'Contacta al administrador de tu planta.'
                        : 'Esperando permiso concedido por el administrador.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14,
                                           color: AppColors.textoGris,
                                           height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  if (email.isNotEmpty)
                    TileAviso(
                      icono: Icons.mail_outline,
                      titulo: 'Correo registrado',
                      subtitulo: email,
                      color: rechazada ? AppColors.rojo : AppColors.azul,
                    ),

                  const Spacer(flex: 3),

                  // ── Botones ──
                  if (!rechazada) ...[
                    BotonAncho(
                      texto: state.cargando
                          ? 'Consultando...'
                          : 'Ya me aprobaron, reintentar',
                      icono: state.cargando ? null : Icons.refresh,
                      onTap: state.cargando
                          ? null
                          : () => context
                              .read<AuthBloc>()
                              .add(const AuthRecargarPerfil()),
                    ),
                    const SizedBox(height: 12),
                  ],
                  BotonAncho(
                    texto: 'Cerrar sesión',
                    icono: Icons.logout,
                    estilo: EstiloBoton.borde,
                    onTap: state.cargando
                        ? null
                        : () => context
                            .read<AuthBloc>()
                            .add(const AuthCerrarSesion()),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
