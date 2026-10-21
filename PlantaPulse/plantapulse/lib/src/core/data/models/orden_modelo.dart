// lib/src/core/data/models/orden_modelo.dart
import '../../domain/entities/orden.dart';
import '../json_helpers.dart';
import 'evidencia_modelo.dart';
import 'usuario_modelo.dart';

/// Fila de la tabla 'ordenes'.
/// Ejemplo de la traducción: la columna asignado_a_uid alimenta asignadoAUid.
class OrdenModelo extends Orden {
  const OrdenModelo({
    required super.id,
    required super.codigo,
    required super.plantaId,
    required super.titulo,
    super.descripcion,
    super.categoria,
    super.zonaId,
    super.zonaNombre,
    super.equipoId,
    super.equipoNombre,
    required super.creadoPor,
    super.asignadoA,
    super.asignadoAUid,
    super.estado,
    super.prioridad,
    required super.createdAt,
    required super.fechaLimite,
    super.fechaCierre,
    required super.ultimaActividad,
    super.portadaUrl,
    super.totalReportes,
    super.totalAlertas,
    super.generadaPorIA,
    super.notaOriginal,
    super.evidencias,
    super.validadaPor,
    super.observacionesSupervisor,
    super.eliminadaEn,
  });

  factory OrdenModelo.desdeEntidad(Orden o) => OrdenModelo(
        id: o.id,
        codigo: o.codigo,
        plantaId: o.plantaId,
        titulo: o.titulo,
        descripcion: o.descripcion,
        categoria: o.categoria,
        zonaId: o.zonaId,
        zonaNombre: o.zonaNombre,
        equipoId: o.equipoId,
        equipoNombre: o.equipoNombre,
        creadoPor: o.creadoPor,
        asignadoA: o.asignadoA,
        asignadoAUid: o.asignadoAUid,
        estado: o.estado,
        prioridad: o.prioridad,
        createdAt: o.createdAt,
        fechaLimite: o.fechaLimite,
        fechaCierre: o.fechaCierre,
        ultimaActividad: o.ultimaActividad,
        portadaUrl: o.portadaUrl,
        totalReportes: o.totalReportes,
        totalAlertas: o.totalAlertas,
        generadaPorIA: o.generadaPorIA,
        notaOriginal: o.notaOriginal,
        evidencias: o.evidencias,
        validadaPor: o.validadaPor,
        observacionesSupervisor: o.observacionesSupervisor,
        eliminadaEn: o.eliminadaEn,
      );

  factory OrdenModelo.fromJson(Map<String, dynamic> j) {
    // Sin técnico: asignado_a y asignado_a_uid llegan como null
    final asignado = UsuarioRefModelo.fromJsonOpcional(j['asignado_a']);
    final id = texto(j['id']);
    return OrdenModelo(
      id: id,
      codigo: texto(j['codigo'], id),
      plantaId: texto(j['planta_id']),
      titulo: texto(j['titulo'], 'Sin título'),
      descripcion: texto(j['descripcion']),
      categoria: texto(j['categoria']),
      zonaId: texto(j['zona_id']),
      zonaNombre: texto(j['zona_nombre']),
      equipoId: textoOpcional(j['equipo_id']),
      equipoNombre: textoOpcional(j['equipo_nombre']),
      creadoPor: UsuarioRefModelo.fromJson(mapa(j['creado_por'])),
      asignadoA: asignado,
      asignadoAUid: textoOpcional(j['asignado_a_uid']) ?? asignado?.uid,
      estado: EstadoOrdenX.desdeDb(j['estado']),
      prioridad: PrioridadX.desdeDb(j['prioridad']),
      createdAt: fecha(j['created_at']),
      fechaLimite: fecha(j['fecha_limite']),
      fechaCierre: fechaOpcional(j['fecha_cierre']),
      ultimaActividad: fecha(j['ultima_actividad']),
      portadaUrl: textoOpcional(j['portada_url']),
      totalReportes: entero(j['total_reportes']),
      totalAlertas: entero(j['total_alertas']),
      generadaPorIA: booleano(j['generada_por_ia']),
      notaOriginal: textoOpcional(j['nota_original']),
      evidencias: evidenciasDesdeJson(j['evidencias']),
      validadaPor: UsuarioRefModelo.fromJsonOpcional(j['validada_por']),
      observacionesSupervisor: textoOpcional(j['observaciones_supervisor']),
      eliminadaEn: fechaOpcional(j['eliminada_en']),
    );
  }

  /// Para insertar: sin id (lo genera Postgres) y sin created_at ni
  /// ultima_actividad (los pone el trigger con la hora del servidor).
  /// eliminada_en tampoco: solo la pone la función eliminar_orden().
  ///
  /// El id SÍ se envía si la app ya lo generó (OrdenRepositorio.nuevoId):
  /// las fotos del hallazgo se suben antes, a la carpeta de esa orden.
  /// 'evidencias' solo va si hay fotos, así crear una orden sin fotos no
  /// depende de que exista la columna.
  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        if (evidencias.isNotEmpty) 'evidencias': evidenciasAJson(evidencias),
        'codigo': codigo,
        'planta_id': plantaId,
        'titulo': titulo,
        'descripcion': descripcion,
        'categoria': categoria,
        'zona_id': zonaId,
        'zona_nombre': zonaNombre,
        'equipo_id': equipoId,
        'equipo_nombre': equipoNombre,
        'creado_por': refAJson(creadoPor),
        // Sin técnico van null, nunca mapa vacío ni '': asignado_a_uid es
        // uuid y una cadena vacía haría fallar el insert.
        'asignado_a': refAJsonOpcional(asignadoA),
        'asignado_a_uid': asignadoAUid,
        'estado': estado.db,
        'prioridad': prioridad.db,
        'fecha_limite': aIso(fechaLimite),
        'fecha_cierre': aIsoOpcional(fechaCierre),
        'portada_url': portadaUrl,
        'total_reportes': totalReportes,
        'total_alertas': totalAlertas,
        'generada_por_ia': generadaPorIA,
        'nota_original': notaOriginal,
        'validada_por': refAJsonOpcional(validadaPor),
        'observaciones_supervisor': observacionesSupervisor,
      };
}
