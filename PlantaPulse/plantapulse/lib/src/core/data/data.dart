// lib/src/core/data/data.dart
// Barril de la capa de datos compartida. Solo para implementaciones de
// repositorio y main.dart; la ui no lo importa.
export 'fallos_supabase.dart';
export 'json_helpers.dart';
export 'models/alerta_modelo.dart';
export 'models/categoria_modelo.dart';
export 'models/equipo_modelo.dart';
export 'models/evidencia_modelo.dart';
export 'models/novedad_modelo.dart';
export 'models/orden_modelo.dart';
export 'models/planta_modelo.dart';
export 'models/reporte_modelo.dart';
export 'models/usuario_modelo.dart';
export 'datasources/almacenamiento_fuente_supabase.dart';
export 'datasources/categoria_fuente_supabase.dart';
export 'datasources/cola_reportes_fuente_local.dart';
export 'datasources/foto_fuente_dispositivo.dart';
export 'datasources/ia_fuente_supabase.dart';
export 'datasources/planta_fuente_supabase.dart';
export 'datasources/zona_fuente_supabase.dart';
export 'repositories/almacenamiento_repositorio_impl.dart';
export 'repositories/categoria_repositorio_impl.dart';
export 'repositories/cola_reportes_repositorio_impl.dart';
export 'repositories/ia_repositorio_impl.dart';
export 'repositories/planta_repositorio_impl.dart';
export 'repositories/zona_repositorio_impl.dart';
