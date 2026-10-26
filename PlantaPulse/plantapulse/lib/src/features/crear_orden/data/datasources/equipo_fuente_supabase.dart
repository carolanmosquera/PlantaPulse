// lib/src/features/crear_orden/data/datasources/equipo_fuente_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/data.dart';

/// El único lugar que habla con la tabla 'equipos'. Devuelve filas crudas;
/// los errores ya salen como FalloApp.
class EquipoFuenteSupabase {
  final SupabaseClient _db;

  EquipoFuenteSupabase({SupabaseClient? cliente})
      : _db = cliente ?? Supabase.instance.client;

  SupabaseQueryBuilder get _tabla => _db.from('equipos');

  static const _serialRepetido = 'Ya hay un equipo con ese serial en esta planta.';

  /// Equipos activos de una planta, ordenados por nombre, para el
  /// selector del asistente de creación (paso 1).
  /// Usa el índice (planta_id, activo, nombre).
  Future<List<Map<String, dynamic>>> deLaPlanta(String plantaId) =>
      traducirSupabase(() => _tabla
          .select()
          .eq('planta_id', plantaId)
          .eq('activo', true)
          .order('nombre', ascending: true));

  /// Una fila, o null si no existe.
  Future<Map<String, dynamic>?> obtener(String equipoId) =>
      traducirSupabase(() => _tabla.select().eq('id', equipoId).maybeSingle());

  /// Aquí SÍ va .select().single(): la fila que vuelve trae el id y la
  /// zona_nombre que puso el trigger, y es la que se muestra en la lista.
  Future<Map<String, dynamic>> insertar(Map<String, dynamic> fila) =>
      traducirSupabase(
        () => _tabla.insert(fila).select().single(),
        // Índice único (planta_id, serial) cuando el serial no está vacío
        duplicado: _serialRepetido,
      );

  /// Update sin .select(); luego se relee la fila. Un update rechazado por
  /// RLS no da error, solo no cambia nada: [aplicado] dice si la fila
  /// releída trae lo que se mandó, y el repositorio decide qué hacer.
  /// zona_nombre lo recalcula el trigger trg_b_equipo_zona.
  Future<({Map<String, dynamic> fila, bool aplicado})> editar(
    String equipoId, {
    required String nombre,
    required String zonaId,
    required String serial,
    required String modelo,
    required String tipo,
  }) =>
      traducirSupabase(
        () async {
          final cambios = {
            'nombre': nombre.trim(),
            'zona_id': zonaId,
            'serial': serial.trim(),
            'modelo': modelo.trim(),
            'tipo': tipo,
          };
          await _tabla.update(cambios).eq('id', equipoId);
          final fila = await _tabla.select().eq('id', equipoId).single();
          final aplicado = cambios.entries.every((c) => fila[c.key] == c.value);
          return (fila: fila, aplicado: aplicado);
        },
        duplicado: _serialRepetido,
      );

  /// Marca el equipo como inactivo y devuelve cómo quedó 'activo' al
  /// releerlo (null si la fila no se pudo leer).
  Future<bool?> darDeBaja(String equipoId) => traducirSupabase(() async {
        await _tabla.update({'activo': false}).eq('id', equipoId);
        // Se relee para comprobar que de verdad haya quedado de baja
        final fila =
            await _tabla.select('activo').eq('id', equipoId).maybeSingle();
        return fila == null ? null : fila['activo'] as bool?;
      });
}
