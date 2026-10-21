// lib/src/features/crear_orden/data/repositories/equipo_repositorio_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/data/data.dart';
import '../../../../core/domain/entities/equipo.dart';
import '../../../../core/errors/fallos.dart';
import '../../domain/repositories/equipo_repositorio.dart';

/// Habla SOLO con la tabla 'equipos'.
/// Se leen para el asistente; se dan de alta, editan y dan de baja desde él.
class EquipoRepositorioSupabase implements EquipoRepositorio {
  final SupabaseClient _db;

  EquipoRepositorioSupabase({SupabaseClient? cliente})
      : _db = cliente ?? Supabase.instance.client;

  SupabaseQueryBuilder get _tabla => _db.from('equipos');

  /// Equipos activos de una planta, ordenados por nombre, para el
  /// selector del asistente de creación (paso 1).
  /// Usa el índice (planta_id, activo, nombre).
  @override
  Future<List<Equipo>> deLaPlanta(String plantaId) =>
      traducirSupabase(() async {
        final filas = await _tabla
            .select()
            .eq('planta_id', plantaId)
            .eq('activo', true)
            .order('nombre', ascending: true);
        return filas.map(EquipoModelo.fromJson).toList();
      });

  /// Lee un equipo una sola vez. Devuelve null si no existe.
  @override
  Future<Equipo?> obtener(String equipoId) => traducirSupabase(() async {
        final fila = await _tabla.select().eq('id', equipoId).maybeSingle();
        return fila == null ? null : EquipoModelo.fromJson(fila);
      });

  /// Aquí SÍ va .select().single(): la fila que vuelve trae el id y la
  /// zona_nombre que puso el trigger, y es la que se muestra en la lista.
  @override
  Future<Equipo> crear(Equipo equipo) => traducirSupabase(
        () async {
          final fila = await _tabla
              .insert(EquipoModelo.desdeEntidad(equipo).toJson())
              .select()
              .single();
          return EquipoModelo.fromJson(fila);
        },
        // Índice único (planta_id, serial) cuando el serial no está vacío
        duplicado: 'Ya hay un equipo con ese serial en esta planta.',
      );

  /// Update sin .select(); luego se relee la fila. Un update rechazado por
  /// RLS no da error, solo no cambia nada: si la fila releída no trae lo
  /// que se mandó, se avisa en vez de mostrar "guardado".
  /// zona_nombre lo recalcula el trigger trg_b_equipo_zona.
  @override
  Future<Equipo> editar(Equipo equipo) => traducirSupabase(
        () async {
          final cambios = {
            'nombre': equipo.nombre.trim(),
            'zona_id': equipo.zonaId,
            'serial': equipo.serial.trim(),
            'modelo': equipo.modelo.trim(),
            'tipo': equipo.tipo,
          };
          await _tabla.update(cambios).eq('id', equipo.id);
          final fila = await _tabla.select().eq('id', equipo.id).single();
          final aplicado = cambios.entries.every((c) => fila[c.key] == c.value);
          if (!aplicado) {
            throw const FalloPermisos(
                'No se pudo guardar el equipo: no tienes permiso para editarlo.');
          }
          return EquipoModelo.fromJson(fila);
        },
        duplicado: 'Ya hay un equipo con ese serial en esta planta.',
      );

  @override
  Future<void> darDeBaja(String equipoId) => traducirSupabase(() async {
        await _tabla.update({'activo': false}).eq('id', equipoId);
        // Misma comprobación: que de verdad haya quedado de baja
        final fila =
            await _tabla.select('activo').eq('id', equipoId).maybeSingle();
        if (fila != null && fila['activo'] == true) {
          throw const FalloPermisos(
              'No se pudo dar de baja: no tienes permiso para editar este equipo.');
        }
      });
}
