// lib/src/features/notificaciones/ui/escucha_push.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/core.dart';
import '../domain/usecases/sincronizar_token_push.dart';

/// Va por encima del MaterialApp. Hace dos cosas:
///
/// 1. Cuando la sesión queda activa, registra el dispositivo para push.
/// 2. Cuando el usuario toca una notificación, abre la orden que trae
///    (con la app cerrada o en segundo plano).
///
/// Como está por encima del MaterialApp no tiene Navigator propio:
/// navega con la misma [navegador] que recibe el MaterialApp.
class EscuchaPush extends StatefulWidget {
  final GlobalKey<NavigatorState> navegador;
  final Widget child;

  const EscuchaPush({super.key, required this.navegador, required this.child});

  @override
  State<EscuchaPush> createState() => _EscuchaPushState();
}

class _EscuchaPushState extends State<EscuchaPush> {
  StreamSubscription<String>? _tocadas;

  /// Orden tocada antes de que la sesión estuviera lista (app cerrada).
  String? _pendiente;
  bool _revisoInicial = false;

  @override
  void initState() {
    super.initState();
    _tocadas = context.read<PushRepositorio>().ordenesTocadas.listen(_alTocar);
  }

  @override
  void dispose() {
    _tocadas?.cancel();
    super.dispose();
  }

  bool get _sesionActiva =>
      context.read<SesionBloc>().state.sesion == EstadoSesion.activa;

  Future<void> _alCambiarSesion(AuthState state) async {
    final usuario = state.usuario;
    if (state.sesion != EstadoSesion.activa || usuario == null) return;

    await context.read<SincronizarTokenPush>().iniciar(usuario.uid);
    if (!mounted) return;

    // La notificación que abrió la app se lee una sola vez, cuando ya hay
    // sesión: antes no se sabe si el usuario puede ver la orden.
    if (!_revisoInicial) {
      _revisoInicial = true;
      _pendiente ??= await context.read<PushRepositorio>().ordenQueAbrioLaApp();
    }
    final id = _pendiente;
    _pendiente = null;
    if (id != null) await _abrirOrden(id);
  }

  void _alTocar(String ordenId) {
    if (_sesionActiva) {
      _abrirOrden(ordenId);
    } else {
      _pendiente = ordenId; // se abre cuando termine el login
    }
  }

  Future<void> _abrirOrden(String ordenId) async {
    final ordenes = context.read<OrdenRepositorio>();
    final Orden? orden;
    try {
      orden = await ordenes.obtener(ordenId);
    } catch (_) {
      return; // sin red: la notificación solo abre la app
    }
    final nav = widget.navegador.currentState;
    // null si la orden se eliminó o es de otra planta (RLS no deja verla)
    if (orden == null || nav == null || !mounted) return;

    // El feed queda debajo: "atrás" desde el detalle vuelve a él, igual
    // que si el usuario hubiera llegado tocando la tarjeta. Esto también
    // saca al splash si la app se acaba de abrir desde la notificación.
    nav.pushNamedAndRemoveUntil(Rutas.feed, (_) => false);
    nav.pushNamed(Rutas.detalleOrden, arguments: orden);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SesionBloc, AuthState>(
      listenWhen: (antes, ahora) =>
          antes.sesion != ahora.sesion ||
          antes.usuario?.uid != ahora.usuario?.uid,
      listener: (_, state) => _alCambiarSesion(state),
      child: widget.child,
    );
  }
}
