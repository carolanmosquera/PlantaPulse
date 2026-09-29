// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';           // ← NUEVO
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';                              // ← NUEVO (lo genera flutterfire configure)
import 'src/theme/app_colors.dart';
import 'src/theme/rutas.dart';
import 'src/models/orden.dart';
import 'src/blocs/auth/auth_bloc.dart';
import 'src/repositories/planta_repository.dart';
import 'src/repositories/usuario_repository.dart';
import 'src/screens/splash_screen.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/registro_screen.dart';
import 'src/screens/menu_PlantaPulse_Feed_screen.dart';
import 'src/screens/detalle_orden_screen.dart';
import 'src/screens/alertas_screen.dart';
import 'src/screens/perfil_screen.dart';
import 'src/screens/ajustes_screen.dart';
import 'src/screens/crear_orden_p1_screen.dart';
import 'src/screens/resumen_turno_screen.dart';
import 'src/screens/validar_evidencia_screen.dart';
import 'src/screens/mis_tareas_screen.dart';
import 'src/screens/llenar_reporte_screen.dart';
import 'src/screens/emergencia_screen.dart';
import 'src/screens/espera_aprobacion_screen.dart';
import 'src/screens/solicitudes_screen.dart';

// ── CAMBIO: main pasa a ser async ────────────────────────────
// Firebase tiene que estar listo ANTES de que exista cualquier pantalla,
// porque el splash ya lo va a usar para restaurar la sesión.
Future<void> main() async {
  // Obligatorio cuando haces 'await' antes de runApp:
  // prepara el puente entre Flutter y el sistema operativo.
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const PlantaPulseApp());
}
// ─────────────────────────────────────────────────────────────

class PlantaPulseApp extends StatelessWidget {
  /// Solo para pruebas: permiten inyectar versiones falsas.
  /// En la app real son null y se crean las normales.
  final AuthBloc? authBloc;
  final UsuarioRepository? usuarioRepository;
  final PlantaRepository? plantaRepository;

  const PlantaPulseApp({
    super.key,
    this.authBloc,
    this.usuarioRepository,
    this.plantaRepository,
  });

  @override
  Widget build(BuildContext context) {
    // Repositorios y AuthBloc van POR ENCIMA del MaterialApp: el splash
    // los necesita antes de que exista cualquier ruta, y así todas las
    // pantallas (y las hojas inferiores) los ven con context.read.
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<UsuarioRepository>(
            create: (_) => usuarioRepository ?? UsuarioRepository()),
        RepositoryProvider<PlantaRepository>(
            create: (_) => plantaRepository ?? PlantaRepository()),
      ],
      child: BlocProvider<AuthBloc>(
        create: (context) => (authBloc ??
                AuthBloc(usuarioRepository: context.read<UsuarioRepository>()))
          ..add(const AuthComprobarSesion()),
        child: MaterialApp(
          title: 'PlantaPulse',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: AppColors.fondo,
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.azul),
          ),
          // Simula ancho de celular en Chrome — una sola vez para las 15
          builder: (context, child) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: child,
            ),
          ),
          initialRoute: Rutas.splash,
          routes: {
            Rutas.splash:        (_) => const SplashScreen(),
            Rutas.login:         (_) => const LoginScreen(),
            Rutas.registro:      (_) => const RegistroScreen(),
            Rutas.feed:          (_) => const MenuPlantaPulseFeed(),
            Rutas.alertas:       (_) => const AlertasScreen(),
            Rutas.perfil:        (_) => const PerfilScreen(),
            Rutas.ajustes:       (_) => const AjustesScreen(),
            Rutas.crearOrden:    (_) => const CrearOrdenP1Screen(),
            Rutas.resumenTurno:  (_) => const ResumenTurnoScreen(),
            Rutas.validar:       (_) => const ValidarEvidenciaScreen(),
            Rutas.misTareas:     (_) => const MisTareasScreen(),
            Rutas.llenarReporte: (_) => const LlenarReporteScreen(),
            Rutas.emergencia:    (_) => const EmergenciaScreen(),
            Rutas.espera:        (_) => const EsperaAprobacionScreen(),
            Rutas.solicitudes:   (_) => const SolicitudesScreen(),
          },
          // Rutas que necesitan parámetros
          onGenerateRoute: (settings) {
            if (settings.name == Rutas.detalleOrden) {
              final orden = settings.arguments as Orden;
              return MaterialPageRoute(
                builder: (_) => DetalleOrdenScreen(orden: orden));
            }
            return null;
          },
        ),
      ),
    );
  }
}