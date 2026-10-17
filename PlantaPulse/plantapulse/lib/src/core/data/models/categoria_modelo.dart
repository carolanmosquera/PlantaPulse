// lib/src/core/data/models/categoria_modelo.dart
import '../../domain/entities/categoria.dart';
import '../json_helpers.dart';
import 'usuario_modelo.dart';

/// Fila de la tabla 'categorias'.
class CategoriaModelo extends Categoria {
  const CategoriaModelo({
    required super.id,
    required super.plantaId,
    required super.nombre,
    super.icono,
    super.activo,
    super.creadaPor,
  });

  factory CategoriaModelo.desdeEntidad(Categoria c) => CategoriaModelo(
        id: c.id,
        plantaId: c.plantaId,
        nombre: c.nombre,
        icono: c.icono,
        activo: c.activo,
        creadaPor: c.creadaPor,
      );

  factory CategoriaModelo.fromJson(Map<String, dynamic> j) => CategoriaModelo(
        id: texto(j['id']),
        plantaId: texto(j['planta_id']),
        nombre: texto(j['nombre'], 'Sin categoría'),
        icono: texto(j['icono'], 'etiqueta'),
        activo: booleano(j['activo'], true),
        creadaPor: UsuarioRefModelo.fromJsonOpcional(j['creada_por']),
      );

  /// Para insertar: sin id ni created_at (los pone Postgres).
  /// El trigger recorta los espacios del nombre.
  Map<String, dynamic> toJson() => {
        'planta_id': plantaId,
        'nombre': nombre,
        'icono': icono,
        'activo': activo,
        'creada_por': refAJsonOpcional(creadaPor),
      };
}
