// lib/src/blocs/auth/auth_bloc.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/usuario.dart';
import '../../repositories/usuario_repository.dart';
import '../../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

/// Une AuthService (contraseñas) con UsuarioRepository (perfil) y decide
/// a qué pantalla pertenece el usuario según el estado de su cuenta.
///
/// La contraseña solo viaja a Firebase Auth. Nunca se escribe en Firestore.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final UsuarioRepository _usuarioRepository;

  AuthBloc({
    AuthService? authService,
    UsuarioRepository? usuarioRepository,
  })  : _authService = authService ?? AuthService(),
        _usuarioRepository = usuarioRepository ?? UsuarioRepository(),
        super(const AuthState()) {
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
      final uid = _authService.uidActual;
      if (uid == null) {
        emit(state.copyWith(
          sesion: EstadoSesion.sinCuenta,
          limpiarUsuario: true,
        ));
        return;
      }
      final usuario = await _perfilDe(uid);
      emit(_estadoPara(usuario));
    } catch (e) {
      emit(state.copyWith(
        sesion: EstadoSesion.sinCuenta,
        accion: EstadoAccion.error,
        mensajeError: AuthService.mensajeDeError(e),
      ));
    }
  }

  Future<void> _alIniciarSesion(
    AuthIniciarSesion event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(accion: EstadoAccion.enviando, limpiarError: true));
    try {
      final uid = await _authService.entrar(
        email: event.email,
        password: event.password,
      );
      final usuario = await _perfilDe(uid);
      emit(_estadoPara(usuario));
    } catch (e) {
      // sesion NO se toca: el login sigue en pantalla
      emit(state.copyWith(
        accion: EstadoAccion.error,
        mensajeError: AuthService.mensajeDeError(e),
      ));
    }
  }

  Future<void> _alRegistrarse(
    AuthRegistrarse event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(accion: EstadoAccion.enviando, limpiarError: true));
    try {
      // 1. La cuenta en Auth: Firebase guarda solo el hash de la contraseña
      final uid = await _authService.registrar(
        email: event.email,
        password: event.password,
      );

      // 2. El perfil en Firestore, SIN contraseña, pendiente de aprobación
      final nuevo = Usuario(
        uid: uid,
        nombre: event.nombre.trim(),
        email: event.email.trim(),
        rol: RolUsuario.tecnico,
        estado: EstadoCuenta.pendiente,
        plantaId: '',
        createdAt: DateTime.now(),
      );
      await _usuarioRepository.crear(nuevo);

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
        mensajeError: AuthService.mensajeDeError(e),
      ));
    }
  }

  Future<void> _alRecargarPerfil(
    AuthRecargarPerfil event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(accion: EstadoAccion.enviando, limpiarError: true));
    try {
      final uid = _authService.uidActual;
      if (uid == null) {
        emit(state.copyWith(
          sesion: EstadoSesion.sinCuenta,
          accion: EstadoAccion.inactiva,
          limpiarUsuario: true,
        ));
        return;
      }
      final usuario = await _perfilDe(uid);
      emit(_estadoPara(usuario));
    } catch (e) {
      emit(state.copyWith(
        accion: EstadoAccion.error,
        mensajeError: AuthService.mensajeDeError(e),
      ));
    }
  }

  Future<void> _alCerrarSesion(
    AuthCerrarSesion event,
    Emitter<AuthState> emit,
  ) async {
    await _authService.salir();
    emit(state.copyWith(
      sesion: EstadoSesion.sinCuenta,
      accion: EstadoAccion.inactiva,
      limpiarUsuario: true,
      limpiarError: true,
    ));
  }

  // ── Auxiliares ───────────────────────────────────────────────

  /// Lee el perfil. Si no existe (la cuenta de Auth se creó pero la
  /// escritura del perfil falló), lo recrea como pendiente.
  Future<Usuario> _perfilDe(String uid) async {
    final existente = await _usuarioRepository.obtener(uid);
    if (existente != null) return existente;

    final cuenta = FirebaseAuth.instance.currentUser;
    final recreado = Usuario(
      uid: uid,
      nombre: cuenta?.displayName ?? cuenta?.email?.split('@').first ?? 'Sin nombre',
      email: cuenta?.email ?? '',
      rol: RolUsuario.tecnico,
      estado: EstadoCuenta.pendiente,
      plantaId: '',
      createdAt: DateTime.now(),
    );
    await _usuarioRepository.crear(recreado);
    return recreado;
  }

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
