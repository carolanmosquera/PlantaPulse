// lib/src/core/errors/fallos.dart
// Errores del dominio. Las implementaciones de repositorio capturan las
// excepciones del SDK (Firebase hoy, Supabase mañana) y las convierten a
// estas: así los casos de uso y los Blocs nunca ven un tipo del SDK.

/// Error con un mensaje listo para mostrar al usuario, en español.
class FalloApp implements Exception {
  final String mensaje;

  const FalloApp(this.mensaje);

  /// El mensaje para mostrar de cualquier error que llegue a la UI.
  static String mensajeDe(Object e) => e is FalloApp
      ? e.mensaje
      : 'Ocurrió un error inesperado. Intenta de nuevo.';

  @override
  String toString() => mensaje;
}

/// Sin conexión, servidor caído o tiempo de espera agotado.
class FalloRed extends FalloApp {
  const FalloRed([super.mensaje = 'Sin conexión. Revisa tu internet.']);
}

/// Credenciales incorrectas, cuenta ya existente, contraseña débil...
class FalloAutenticacion extends FalloApp {
  const FalloAutenticacion(super.mensaje);
}

/// Las reglas de seguridad de la base de datos rechazaron la operación.
class FalloPermisos extends FalloApp {
  const FalloPermisos(
      [super.mensaje = 'No tienes permiso para realizar esta operación.']);
}
