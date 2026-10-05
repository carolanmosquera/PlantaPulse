// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';                              // lo genera flutterfire configure
import 'src/core/core.dart';
import 'src/features/auth/auth.dart';
import 'src/features/crear_orden/crear_orden.dart';
import 'src/features/novedades/novedades.dart';
import 'src/features/ordenes/ordenes.dart';
import 'src/features/perfil/perfil.dart';
import 'src/features/reportes/reportes.dart';

// Implementaciones concretas: main.dart es el ÚNICO archivo que las conoce.
import 'src/core/data/planta_repositorio_firestore.dart';
import 'src/features/auth/data/repositories/autenticacion_repositorio_firebase.dart';
import 'src/features/auth/data/repositories/usuario_repositorio_firestore.dart';
import 'src/features/crear_orden/data/repositories/equipo_repositorio_firestore.dart';
import 'src/features/ordenes/data/repositories/orden_repositorio_firestore.dart';

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

class PlantaPulseApp extends StatelessWidget {
  /// Solo para pruebas: permiten inyectar versiones falsas de los
  /// contratos. En la app real son null y se crean las de Firebase.
  final SesionBloc? authBloc;
  final AutenticacionRepositorio? autenticacionRepositorio;
  final UsuarioRepositorio? usuarioRepository;
  final PlantaRepositorio? plantaRepository;
  final OrdenRepositorio? ordenRepository;
  final EquipoRepositorio? equipoRepository;

  const PlantaPulseApp({
    super.key,
    this.authBloc,
    this.autenticacionRepositorio,
    this.usuarioRepository,
    this.plantaRepository,
    this.ordenRepository,
    this.equipoRepository,
  });

  @override
  Widget build(BuildContext context) {
    // La cadena completa se arma aquí, en este orden:
    //   implementaciones de repositorio → casos de uso → Blocs.
    //
    // Todo va POR ENCIMA del MaterialApp: el splash necesita la sesión
    // antes de que exista cualquier ruta, el feed es una ruta con nombre,
    // y así todas las pantallas (y las hojas inferiores) los ven con
    // context.read. Los RepositoryProvider son perezosos: un repositorio
    // de Firebase solo se crea si alguien lo pide.
    // El CrearOrdenBloc NO va aquí: vive y muere dentro del asistente.
    return MultiRepositoryProvider(
      providers: [
        // ── Repositorios (contratos del dominio) ──
        RepositoryProvider<UsuarioRepositorio>(
            create: (_) => usuarioRepository ?? UsuarioRepositorioFirestore()),
        RepositoryProvider<PlantaRepositorio>(
            create: (_) => plantaRepository ?? PlantaRepositorioFirestore()),
        RepositoryProvider<OrdenRepositorio>(
            create: (_) => ordenRepository ?? OrdenRepositorioFirestore()),
        RepositoryProvider<EquipoRepositorio>(
            create: (_) => equipoRepository ?? EquipoRepositorioFirestore()),

        // ── Casos de uso que las pantallas leen directamente ──
        RepositoryProvider(
            create: (c) =>
                ObservarSolicitudesPendientes(c.read<UsuarioRepositorio>())),
        RepositoryProvider(
            create: (c) => AprobarSolicitud(c.read<UsuarioRepositorio>())),
        RepositoryProvider(
            create: (c) => RechazarSolicitud(c.read<UsuarioRepositorio>())),
        RepositoryProvider(
            create: (c) => ListarPlantasActivas(c.read<PlantaRepositorio>())),
        RepositoryProvider(
            create: (c) => ListarEquiposDePlanta(c.read<EquipoRepositorio>())),
        RepositoryProvider(
            create: (c) => ListarTecnicosDePlanta(c.read<UsuarioRepositorio>())),
        RepositoryProvider(
            create: (c) => PublicarOrden(c.read<OrdenRepositorio>())),
        RepositoryProvider(
            create: (c) => ActualizarPerfil(c.read<UsuarioRepositorio>())),
      ],
      child: MultiBlocProvider(
        providers: [
          // Se registra como SesionBloc: así los demás features lo leen
          // sin importar el feature auth.
          BlocProvider<SesionBloc>(
            create: (context) =>
                (authBloc ?? _crearAuthBloc(context.read<UsuarioRepositorio>()))
                  ..add(const AuthComprobarSesion()),
          ),
          BlocProvider<OrdenesBloc>(
            create: (context) {
              final ordenes = context.read<OrdenRepositorio>();
              return OrdenesBloc(
                observarOrdenesDePlanta: ObservarOrdenesDePlanta(ordenes),
                observarMisTareas: ObservarMisTareas(ordenes),
              );
            },
          ),
        ],
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
            Rutas.feed:          (_) => const FeedScreen(),
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

  /// La cadena de autenticación: repositorio → casos de uso → Bloc.
  AuthBloc _crearAuthBloc(UsuarioRepositorio usuarios) {
    final auth = autenticacionRepositorio ?? AutenticacionRepositorioFirebase();
    return AuthBloc(
      comprobarSesion: ComprobarSesion(auth, usuarios),
      iniciarSesion: IniciarSesion(auth, usuarios),
      registrarSolicitud: RegistrarSolicitud(auth, usuarios),
      recargarPerfil: RecargarPerfil(auth, usuarios),
      cerrarSesion: CerrarSesion(auth),
    );
  }
}
