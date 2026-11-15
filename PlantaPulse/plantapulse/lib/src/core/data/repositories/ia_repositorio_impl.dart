// lib/src/core/data/repositories/ia_repositorio_impl.dart
import '../../domain/entities/borrador_orden_ia.dart';
import '../../domain/entities/orden.dart';
import '../../domain/entities/progreso_orden_ia.dart';
import '../../domain/entities/reporte.dart';
import '../../domain/entities/resumen_turno.dart';
import '../../domain/repositories/ia_repositorio.dart';
import '../../errors/fallos.dart';
import '../datasources/ia_fuente_supabase.dart';
import '../json_helpers.dart';

/// Convierte el JSON de la función en entidades. La red y sus errores
/// quedan en la fuente.
class IaRepositorioImpl implements IaRepositorio {
  final IaFuenteSupabase _fuente;

  IaRepositorioImpl(this._fuente);

  static const _incompleta =
      FalloApp('El asistente devolvió una respuesta incompleta.');

  @override
  Future<BorradorOrdenIa> estructurarNota(String nota) async {
    final j = await _fuente.estructurarOrden(nota);
    final titulo = texto(j['titulo']).trim();
    final descripcion = texto(j['descripcion']).trim();
    if (titulo.isEmpty && descripcion.isEmpty) throw _incompleta;
    return BorradorOrdenIa(
      titulo: titulo,
      descripcion: descripcion,
      categoriaSugerida: texto(j['categoria_sugerida']).trim(),
      prioridadSugerida: _prioridad(j['prioridad_sugerida']),
    );
  }

  /// Lo desconocido cae en media (así lo hace desdeDb). 'critica' también:
  /// la función nunca debería mandarla, y si llegara, marcar una orden
  /// como crítica sigue siendo decisión del supervisor, no del modelo.
  static Prioridad _prioridad(dynamic valor) {
    final p = PrioridadX.desdeDb(valor is String ? valor.trim().toLowerCase() : null);
    return p == Prioridad.critica ? Prioridad.media : p;
  }

  @override
  Future<String> redactarReporte({
    required String notas,
    required String equipo,
  }) async {
    final j = await _fuente.redactarReporte(notas: notas, equipo: equipo);
    final redactado = texto(j['texto']).trim();
    if (redactado.isEmpty) throw _incompleta;
    return redactado;
  }

  /// Solo lo que la IA necesita para estimar: nada de fotos, ids ni
  /// datos personales más allá del nombre de quien reporta.
  @override
  Future<ProgresoOrdenIa> calcularProgreso({
    required Orden orden,
    required List<Reporte> reportes,
  }) async {
    final cronologicos = [...reportes]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final j = await _fuente.progresoOrden({
      'orden': {
        'titulo': orden.titulo,
        'descripcion': orden.descripcion,
        'categoria': orden.categoria,
        'equipo': orden.equipoNombre ?? '',
        'estado': orden.estado.db,
        'prioridad': orden.prioridad.db,
        'creada': aIso(orden.createdAt),
        'fecha_limite': aIso(orden.fechaLimite),
      },
      'reportes': [
        for (final r in cronologicos)
          {
            'fecha': aIso(r.createdAt),
            'autor': r.autor.nombre,
            'estado_trabajo': r.estadoTrabajo.db,
            'alerta_critica': r.esAlertaCritica,
            'fotos': r.evidencias.length,
            'detalles': r.detalles,
          },
      ],
    });
    final resumen = texto(j['resumen']).trim();
    if (resumen.isEmpty) throw _incompleta;
    return ProgresoOrdenIa(
      porcentaje: _porcentaje(j['porcentaje']),
      resumen: resumen,
      falta: texto(j['falta']).trim(),
    );
  }

  /// Entero entre 0 y 100 aunque el modelo mande 72.5, "70" o 140.
  static int _porcentaje(dynamic v) {
    final n = v is num ? v : num.tryParse('$v'.trim().replaceAll('%', ''));
    if (n == null || n.isNaN) throw _incompleta;
    return n.round().clamp(0, 100);
  }

  @override
  Future<ResumenTurno> resumirTurno(Map<String, int> cifras) async {
    final j = await _fuente.resumenTurno(cifras);
    final vinetas = [
      for (final v in listaTexto(j['vinetas']))
        if (v.trim().isNotEmpty) v.trim(),
    ];
    if (vinetas.isEmpty) throw _incompleta;
    return ResumenTurno(vinetas: vinetas);
  }
}
