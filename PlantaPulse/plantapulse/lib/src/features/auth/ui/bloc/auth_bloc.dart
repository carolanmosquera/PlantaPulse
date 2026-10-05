// lib/src/features/auth/ui/bloc/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/entities/usuario.dart';
import '../../../../core/errors/fallos.dart';
import '../../../../core/sesion/sesion_bloc.dart';
import '../../domain/usecases/cerrar_sesion.dart';
import '../../domain/usecases/comprobar_sesion.dart';
import '../../domain/usecases/iniciar_sesion.dart';
import '../../domain/usecases/recargar_perfil.dart';
import '../../domain/usecases/registrar_solicitud.dart';

export '../../../../core/sesion/sesion_bloc.dart';

/// Decide a qué pantalla pertenece el usuario según el estado de su cuenta.
/// Recibe casos de uso: no sabe qué servicio de autenticación ni qué base
/// de datos hay detrás.
///
/// Se registra en main.dart como SesionBloc para que los demás features
/// lo lean sin importar este archivo.
class AuthBloc extends SesionBloc {
  final ComprobarSesion _comprobarSesion;
  final IniciarSesion _iniciarSesion;
  final RegistrarSolicitud _registrarSolicitud;
  final RecargarPerfil _recargarPerfil;
  final CerrarSesion _cerrarSesion;

  AuthBloc({
    required this._comprobarSesion,
    required this._iniciarSesion,
    required this._registrarSolicitud,
    required this._recargarPerfil,
    required this._cerrarSesion,
  }) {
    on<AuthComprobarSesion>(_alComprobarSesion);
    on<AuthIniciarSesion>(_alIniciarSesion);
    on<AuthRegistrarse>(_alRegistrarse);
    on<AuthRecargarPerfil>(_alRecargarPerfil);
    on<AuthCerrarSesion>(_alCerrarSesion);
  }

  // ── Eventos ──────────────────────────────────────────────────

  Future<void> _alComprobarSesion(
    AuthComprobarSesion event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final usuario = await _comprobarSesion.ejecutar();
      if (usuario == null) {
        emit(state.copyWith(
          sesion: EstadoSesion.sinCuenta,
          limpiarUsuario: true,
        ));
        return;
      }
      emit(_estadoPara(usuario));
    } catch (e) {
      emit(state.copyWith(
        sesion: EstadoSesion.sinCuenta,
        accion: EstadoAccion.error,
        mensajeError: FalloApp.mensajeDe(e),
      ));
    }
  }

  Future<void> _alIniciarSesion(
    AuthIniciarSesion event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(accion: EstadoAccion.enviando, limpiarError: true));
    try {
      final usuario = await _iniciarSesion.ejecutar(
        email: event.email,
        password: event.password,
      );
      emit(_estadoPara(usuario));
    } catch (e) {
      // sesion NO se toca: el login sigue en pantalla
      emit(state.copyWith(
        accion: EstadoAccion.error,
        mensajeError: FalloApp.mensajeDe(e),
      ));
    }
  }

  Future<void> _alRegistrarse(
    AuthRegistrarse event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(accion: EstadoAccion.enviando, limpiarError: true));
    try {
      final nuevo = await _registrarSolicitud.ejecutar(
        nombre: event.nombre,
        email: event.email,
        password: event.password,
      );

      // La sesión NO se cierra: la pantalla de espera necesita estar
      // autenticada para poder releer su propio perfil.
      emit(state.copyWith(
        sesion: EstadoSesion.pendiente,
        accion: EstadoAccion.inactiva,
        usuario: nuevo,
      ));
    } catch (e) {
      emit(state.copyWith(
        accion: EstadoAccion.error,
        mensajeError: FalloApp.mensajeDe(e),
      ));
    }
  }

  Future<void> _alRecargarPerfil(
    AuthRecargarPerfil event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(accion: EstadoAccion.enviando, limpiarError: true));
    try {
      final usuario = await _recargarPerfil.ejecutar();
      if (usuario == null) {
        emit(state.copyWith(
          sesion: EstadoSesion.sinCuenta,
          accion: EstadoAccion.inactiva,
          limpiarUsuario: true,
        ));
        return;
      }
      emit(_estadoPara(usuario));
    } catch (e) {
      emit(state.copyWith(
        accion: EstadoAccion.error,
        mensajeError: FalloApp.mensajeDe(e),
      ));
    }
  }

  Future<void> _alCerrarSesion(
    AuthCerrarSesion event,
    Emitter<AuthState> emit,
  ) async {
    await _cerrarSesion.ejecutar();
    emit(state.copyWith(
      sesion: EstadoSesion.sinCuenta,
      accion: EstadoAccion.inactiva,
      limpiarUsuario: true,
      limpiarError: true,
    ));
  }

  // ── Auxiliares ───────────────────────────────────────────────

  /// Mapea el estado de la cuenta a la sesión, con la acción terminada.
  AuthState _estadoPara(Usuario usuario) => state.copyWith(
        sesion: switch (usuario.estado) {
          EstadoCuenta.activo    => EstadoSesion.activa,
          EstadoCuenta.pendiente => EstadoSesion.pendiente,
          EstadoCuenta.rechazado => EstadoSesion.rechazada,
        },
        accion: EstadoAccion.inactiva,
        usuario: usuario,
        limpiarError: true,
      );
}
