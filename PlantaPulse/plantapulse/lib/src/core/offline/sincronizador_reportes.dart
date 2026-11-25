// lib/src/core/offline/sincronizador_reportes.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../sesion/sesion_bloc.dart';
import '../theme/app_colors.dart';
import 'cola_reportes_cubit.dart';

/// Va por encima del MaterialApp (como EscuchaPush): arranca la cola de
/// reportes sin conexión al iniciar sesión, la detiene al salir, y avisa
/// cuando se enviaron o se rechazaron reportes guardados.
class SincronizadorReportes extends StatelessWidget {
  final GlobalKey<NavigatorState> navegador;
  final Widget child;

  const SincronizadorReportes({
    super.key,
    required this.navegador,
    required this.child,
  });

  void _alCambiarSesion(BuildContext context, AuthState state) {
    final cola = context.read<ColaReportesCubit>();
    final usuario = state.usuario;
    if (state.sesion == EstadoSesion.activa && usuario != null) {
      cola.iniciar(usuario.uid);
    } else {
      cola.detener();
    }
  }

  void _avisar(ColaReportesEstado s) {
    final contexto = navegador.currentContext;
    if (contexto == null) return;
    final mensajes = ScaffoldMessenger.of(contexto);
    if (s.enviados > 0) {
      mensajes.showSnackBar(SnackBar(
        backgroundColor: AppColors.verde,
        content: Text(s.enviados == 1
            ? 'Se envió 1 reporte que estaba guardado sin conexión.'
            : 'Se enviaron ${s.enviados} reportes que estaban guardados '
                'sin conexión.'),
      ));
    }
    for (final motivo in s.rechazados) {
      mensajes.showSnackBar(SnackBar(
        backgroundColor: AppColors.rojo,
        duration: const Duration(seconds: 8),
        content: Text('Un reporte guardado no se pudo enviar: $motivo'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SesionBloc, AuthState>(
          listenWhen: (antes, ahora) =>
              antes.sesion != ahora.sesion ||
              antes.usuario?.uid != ahora.usuario?.uid,
          listener: _alCambiarSesion,
        ),
        BlocListener<ColaReportesCubit, ColaReportesEstado>(
          listenWhen: (antes, ahora) => antes.revision != ahora.revision,
          listener: (_, s) => _avisar(s),
        ),
      ],
      child: child,
    );
  }
}
