// lib/src/core/data/models/equipo_modelo.dart
import '../../domain/entities/equipo.dart';
import '../json_helpers.dart';

/// Fila de la tabla 'equipos'.
class EquipoModelo extends Equipo {
  const EquipoModelo({
    required super.id,
    required super.plantaId,
    super.zonaId,
    super.zonaNombre,
    required super.nombre,
    super.serial,
    super.modelo,
    super.tipo,
    super.fotoUrl,
    super.estado,
    super.ultimoMantenimiento,
    super.activo,
  });

  factory EquipoModelo.desdeEntidad(Equipo e) => EquipoModelo(
        id: e.id,
        plantaId: e.plantaId,
        zonaId: e.zonaId,
        zonaNombre: e.zonaNombre,
        nombre: e.nombre,
        serial: e.serial,
        modelo: e.modelo,
        tipo: e.tipo,
        fotoUrl: e.fotoUrl,
        estado: e.estado,
        ultimoMantenimiento: e.ultimoMantenimiento,
        activo: e.activo,
      );

  factory EquipoModelo.fromJson(Map<String, dynamic> j) => EquipoModelo(
        id: texto(j['id']),
        plantaId: texto(j['planta_id']),
        zonaId: texto(j['zona_id']),
        zonaNombre: texto(j['zona_nombre']),
        nombre: texto(j['nombre'], 'Sin equipo'),
        serial: texto(j['serial']),
        modelo: texto(j['modelo']),
        tipo: texto(j['tipo']),
        fotoUrl: textoOpcional(j['foto_url']),
        estado: EstadoEquipoX.desdeDb(j['estado']),
        ultimoMantenimiento: fechaOpcional(j['ultimo_mantenimiento']),
        activo: booleano(j['activo'], true),
      );

  /// Para insertar: sin id (lo genera Postgres) y sin zona_nombre, que lo
  /// rellena un trigger a partir de zona_id (si se enviara, lo pisaría).
  Map<String, dynamic> toJson() => {
        'planta_id': plantaId,
        'zona_id': zonaId,
        'nombre': nombre,
        'serial': serial,
        'modelo': modelo,
        'tipo': tipo,
        'foto_url': fotoUrl,
        'estado': estado.db,
        'ultimo_mantenimiento': aIsoOpcional(ultimoMantenimiento),
        'activo': activo,
      };
}
