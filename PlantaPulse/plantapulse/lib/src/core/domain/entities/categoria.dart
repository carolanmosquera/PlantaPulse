// lib/src/core/domain/entities/categoria.dart
import 'usuario.dart';

/// Categoría de orden de una planta: 'Mecánico', 'Eléctrico'... Las crea
/// el personal en tiempo de ejecución, por eso ya no es un enum.
class Categoria {
  final String id;
  final String plantaId;
  final String nombre;

  /// Clave corta del icono ('llave', 'rayo'...), no un IconData:
  /// el dominio no conoce Flutter. La UI la traduce con iconoDeCategoria().
  final String icono;
  final bool activo;        // se da de baja, no se borra
  final UsuarioRef? creadaPor;

  const Categoria({
    required this.id,
    required this.plantaId,
    required this.nombre,
    this.icono = 'etiqueta',
    this.activo = true,
    this.creadaPor,
  });
}
