// lib/src/services/sesion_actual.dart
import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../repositories/usuario_repository.dart';
import 'auth_service.dart';

/// Une AuthService (contraseñas) con UsuarioRepository (perfil).
///
/// Es un ChangeNotifier: las pantallas pueden escucharlo para saber
/// cuándo cambia el usuario conectado. Es la versión más simple de
/// manejo de estado global, sin agregar paquetes.
class SesionActual extends ChangeNotifier {
  SesionActual._();

  /// Instancia única accesible desde cualquier pantalla: SesionActual.instancia
  static final SesionActual instancia = SesionActual._();

  final AuthService _auth = AuthService();
  final UsuarioRepository _repo = UsuarioRepository();

  Usuario? _usuario;
  Usuario? get usuario => _usuario;

  bool get haySesion => _usuario != null;
  bool get esSupervisor => _usuario?.rol.esSupervisor ?? false;

  /// Referencia corta para denormalizar en órdenes y reportes.
  UsuarioRef? get ref => _usuario?.ref;

  /// Registro: crea la cuenta y DESPUÉS el documento del perfil.
  /// El orden importa: el uid sale de Auth y es el ID del documento.
  Future<void> registrar({
    required String nombre,
    required String email,
    required String password,
    required RolUsuario rol,
    required String plantaId,
    String especialidad = '',
  }) async {
    final uid = await _auth.registrar(email: email, password: password);

    final nuevo = Usuario(
      uid: uid,
      nombre: nombre.trim(),
      email: email.trim(),
      rol: rol,
      especialidad: especialidad,
      plantaId: plantaId,
      createdAt: DateTime.now(),
    );

    await _repo.crear(nuevo);
    _usuario = nuevo;
    notifyListeners();
  }

  Future<void> entrar({
    required String email,
    required String password,
  }) async {
    final uid = await _auth.entrar(email: email, password: password);
    _usuario = await _repo.obtener(uid);
    notifyListeners();
  }

  /// Al abrir la app: si Firebase recuerda la sesión, carga el perfil.
  /// Devuelve true si hay sesión válida.
  Future<bool> restaurar() async {
    final uid = _auth.uidActual;
    if (uid == null) return false;
    _usuario = await _repo.obtener(uid);
    notifyListeners();
    return _usuario != null;
  }

  Future<void> salir() async {
    await _auth.salir();
    _usuario = null;
    notifyListeners();
  }

  /// Traduce errores de Auth a español, para mostrarlos en un SnackBar.
  static String mensajeDeError(Object e) => AuthService.mensajeDeError(e);
}