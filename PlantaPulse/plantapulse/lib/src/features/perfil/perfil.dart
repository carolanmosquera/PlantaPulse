
// lib/src/features/perfil/perfil.dart
// Barril público del feature: dominio y UI.
// La capa data NO se exporta:
// solo main.dart conoce las implementaciones concretas.

export 'domain/usecases/actualizar_perfil.dart';
export 'domain/entities/preferencias_usuario.dart';
export 'domain/repositories/preferencias_repositorio.dart';
export 'domain/usecases/consultar_perfil.dart';
export 'domain/usecases/preferencias_casos.dart';

// KAN-99: fotografía de perfil.
export 'domain/repositories/foto_perfil_repositorio.dart' hide SubirFotoPerfil;
export 'domain/usecases/subir_foto_perfil.dart';

// Pantallas del perfil.
export 'ui/screens/ajustes_screen.dart';
export 'ui/screens/perfil_screen.dart';

