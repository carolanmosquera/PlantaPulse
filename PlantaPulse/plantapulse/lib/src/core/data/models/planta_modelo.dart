// lib/src/core/data/models/planta_modelo.dart
import '../../domain/entities/planta.dart';
import '../json_helpers.dart';

/// Fila de la tabla 'plantas'.
class PlantaModelo extends Planta {
  const PlantaModelo({
    required super.id,
    required super.nombre,
    super.ubicacion,
    super.activo,
  });

  factory PlantaModelo.fromJson(Map<String, dynamic> j) => PlantaModelo(
        id: texto(j['id']),
        nombre: texto(j['nombre'], 'Sin nombre'),
        ubicacion: texto(j['ubicacion']),
        activo: booleano(j['activo'], true),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'ubicacion': ubicacion,
        'activo': activo,
      };
}

/// Fila de la tabla 'zonas'.
class ZonaModelo extends Zona {
  const ZonaModelo({
    required super.id,
    required super.plantaId,
    required super.nombre,
    super.codigo,
    super.descripcion,
    super.activo,
  });

  factory ZonaModelo.fromJson(Map<String, dynamic> j) => ZonaModelo(
        id: texto(j['id']),
        plantaId: texto(j['planta_id']),
        nombre: texto(j['nombre'], 'Sin zona'),
        codigo: texto(j['codigo']),
        descripcion: texto(j['descripcion']),
        activo: booleano(j['activo'], true),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'planta_id': plantaId,
        'nombre': nombre,
        'codigo': codigo,
        'descripcion': descripcion,
        'activo': activo,
      };
}
