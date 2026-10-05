// lib/src/core/domain/repositories/usuario_repositorio.dart
import '../entities/usuario.dart';

/// Perfiles de usuario. No sabe nada de contraseñas ni de autenticación.
///
/// Está en core y no en auth porque también lo usan crear_orden
/// (técnicos de la planta) y perfil (actualizar datos).
abstract class UsuarioRepositorio {
  /// Crea el perfil. Su identificador es el uid de la cuenta.
  Future<void> crear(Usuario usuario);

  /// Lee el perfil una sola vez. Devuelve null si no existe.
  Future<Usuario?> obtener(String uid);

  /// Escucha los cambios del perfil en tiempo real.
  Stream<Usuario?> escuchar(String uid);

  /// Actualiza solo los campos que cambian (nombres de las propiedades
  /// de la entidad), no el perfil completo.
  Future<void> actualizar(String uid, Map<String, dynamic> cambios);

  Future<void> guardarTokenPush(String uid, String token);

  /// Técnicos activos y aprobados de una planta, ordenados por nombre.
  Future<List<Usuario>> tecnicosDePlanta(String plantaId);

  /// Solicitudes pendientes de aprobación, las más nuevas primero.
  Stream<List<Usuario>> solicitudesPendientes();

  Future<void> aprobar(
    String uid, {
    required RolUsuario rol,
    required String plantaId,
    required UsuarioRef aprobadoPor,
  });

  Future<void> rechazar(String uid, UsuarioRef aprobadoPor);
}
