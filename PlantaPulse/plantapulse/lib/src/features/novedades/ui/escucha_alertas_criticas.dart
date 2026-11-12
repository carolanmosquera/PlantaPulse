// lib/src/features/novedades/ui/escucha_alertas_criticas.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/core.dart';
import '../domain/usecases/alertas_criticas.dart';

/// KAN-90, criterio 2: mientras un supervisor tiene la sesión activa, cada
/// alerta crítica nueva de su planta le llega al instante, estando en la
/// pantalla que esté, con un aviso que lo lleva a la lista de alertas.
///
/// Va por encima del MaterialApp, como EscuchaPush, y por eso navega y
/// muestra el aviso con el [navegador] del MaterialApp.
class EscuchaAlertasCriticas extends StatefulWidget {
  final GlobalKey<NavigatorState> navegador;
  final Widget child;

  const EscuchaAlertasCriticas(
      {super.key, required this.navegador, required this.child});

  @override
  State<EscuchaAlertasCriticas> createState() =>
      _EscuchaAlertasCriticasState();
}

class _EscuchaAlertasCriticasState extends State<EscuchaAlertasCriticas> {
  StreamSubscription<List<AlertaCritica>>? _suscripcion;
  String? _uid;

  /// Alertas ya vistas. La primera lista que llega (las abiertas de antes
  /// de conectarse) solo se registra: no se avisa de lo viejo.
  final Set<String> _vistas = {};
  bool _primera = true;

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }

  void _alCambiarSesion(AuthState state) {
    final usuario = state.usuario;
    final debeEscuchar = state.sesion == EstadoSesion.activa &&
        usuario != null &&
        usuario.rol.esSupervisor &&
        usuario.plantaId.isNotEmpty;

    if (!debeEscuchar) {
      _parar();
      return;
    }
    if (_uid == usuario.uid) return; // ya está escuchando
    _parar();
    _uid = usuario.uid;
    try {
      _suscripcion = context
          .read<ObservarAlertasCriticas>()
          .ejecutar(usuario.plantaId)
          .listen((alertas) => _alLlegar(alertas, usuario.uid),
              onError: (_) {});
    } catch (_) {
      // Sin conexión con el servicio: la app sigue, solo sin el aviso
    }
  }

  void _parar() {
    _suscripcion?.cancel();
    _suscripcion = null;
    _uid = null;
    _vistas.clear();
    _primera = true;
  }

  void _alLlegar(List<AlertaCritica> alertas, String miUid) {
    final nuevas = alertas.where((a) => !_vistas.contains(a.id)).toList();
    _vistas.addAll(alertas.map((a) => a.id));
    if (_primera) {
      _primera = false;
      return;
    }
    for (final a in nuevas.where((a) => a.creadoPor.uid != miUid)) {
      _avisar(a);
    }
  }

  void _avisar(AlertaCritica a) {
    final contexto = widget.navegador.currentContext;
    if (contexto == null || !mounted) return;
    ScaffoldMessenger.of(contexto)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: AppColors.rojo,
        duration: const Duration(seconds: 12),
        content: Text('ALERTA CRÍTICA · ${a.tipo.etiqueta}\n'
            '${a.creadoPor.nombre}: ${a.descripcion}'),
        action: SnackBarAction(
          label: 'VER',
          textColor: Colors.white,
          onPressed: () => widget.navegador.currentState
              ?.pushNamedAndRemoveUntil(Rutas.alertas, (r) => false),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SesionBloc, AuthState>(
      listenWhen: (antes, ahora) =>
          antes.sesion != ahora.sesion ||
          antes.usuario?.uid != ahora.usuario?.uid ||
          antes.usuario?.rol != ahora.usuario?.rol,
      listener: (_, state) => _alCambiarSesion(state),
      child: widget.child,
    );
  }
}
