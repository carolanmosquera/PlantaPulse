// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import 'src/core/core.dart';
import 'src/features/auth/auth.dart';
import 'src/features/crear_orden/crear_orden.dart';
import 'src/features/novedades/novedades.dart';
import 'src/features/ordenes/ordenes.dart';
import 'src/features/perfil/perfil.dart';
import 'src/features/reportes/reportes.dart';

// Implementaciones concretas: main.dart es el ÚNICO archivo que las conoce.
import 'src/core/data/planta_repositorio_supabase.dart';
import 'src/core/data/repositories/almacenamiento_repositorio_supabase.dart';
import 'src/core/data/repositories/categoria_repositorio_supabase.dart';
import 'src/core/data/repositories/zona_repositorio_supabase.dart';
import 'src/features/auth/data/repositories/autenticacion_repositorio_supabase.dart';
import 'src/features/auth/data/repositories/usuario_repositorio_supabase.dart';
import 'src/features/crear_orden/data/repositories/equipo_repositorio_supabase.dart';
import 'src/features/ordenes/data/repositories/orden_repositorio_supabase.dart';
import 'src/features/reportes/data/repositories/reporte_repositorio_supabase.dart';

// Proyecto de Supabase. La clave es la PUBLISHABLE: está pensada para ir
// en el cliente, y lo que protege los datos es RLS (supabase/esquema.sql).
// NUNCA poner aquí la clave service_role: se salta RLS por completo.
// Ambas se pueden cambiar sin tocar el código:
//   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL',
    defaultValue: 'https://uxajglpaoofragjxcrvx.supabase.co');
const _supabaseKey = String.fromEnvironment('SUPABASE_KEY',
    defaultValue: 'sb_publishable_3u4XDt2DaGZ3q8uKJ422OA_7ivMKL2X');

// Supabase tiene que estar listo ANTES de que exista cualquier pantalla,
// porque el splash ya lo va a usar para restaurar la sesión guardada.
Future<void> main() async {
  // Obligatorio cuando haces 'await' antes de runApp:
  // prepara el puente entre Flutter y el sistema operativo.
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseKey);

  runApp(const PlantaPulseApp());
}

class PlantaPulseApp extends StatelessWidget {
  /// Solo para pruebas: permiten inyectar versiones falsas de los
  /// contratos. En la app real son null y se crean las de Supabase.
  final SesionBloc? authBloc;
  final AutenticacionRepositorio? autenticacionRepositorio;
  final UsuarioRepositorio? usuarioRepository;
  final PlantaRepositorio? plantaRepository;
  final OrdenRepositorio? ordenRepository;
  final EquipoRepositorio? equipoRepository;
  final CategoriaRepositorio? categoriaRepositorio;
  final ZonaRepositorio? zonaRepositorio;
  final ReporteRepositorio? reporteRepositorio;
  final AlmacenamientoRepositorio? almacenamientoRepositorio;

  const PlantaPulseApp({
    super.key,
    this.authBloc,
    this.autenticacionRepositorio,
    this.usuarioRepository,
    this.plantaRepository,
    this.ordenRepository,
    this.equipoRepository,
    this.categoriaRepositorio,
    this.zonaRepositorio,
    this.reporteRepositorio,
    this.almacenamientoRepositorio,
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
    // de Supabase solo se crea si alguien lo pide (las pruebas no lo piden).
    // El CrearOrdenBloc NO va aquí: vive y muere dentro del asistente.
    return MultiRepositoryProvider(
      providers: [
        // ── Repositorios (contratos del dominio) ──
        RepositoryProvider<UsuarioRepositorio>(
            create: (_) => usuarioRepository ?? UsuarioRepositorioSupabase()),
        RepositoryProvider<PlantaRepositorio>(
            create: (_) => plantaRepository ?? PlantaRepositorioSupabase()),
        RepositoryProvider<OrdenRepositorio>(
            create: (_) => ordenRepository ?? OrdenRepositorioSupabase()),
        RepositoryProvider<EquipoRepositorio>(
            create: (_) => equipoRepository ?? EquipoRepositorioSupabase()),
        RepositoryProvider<CategoriaRepositorio>(
            create: (_) =>
                categoriaRepositorio ?? CategoriaRepositorioSupabase()),
        RepositoryProvider<ZonaRepositorio>(
            create: (_) => zonaRepositorio ?? ZonaRepositorioSupabase()),
        RepositoryProvider<ReporteRepositorio>(
            create: (_) =>
                reporteRepositorio ?? ReporteRepositorioSupabase()),
        RepositoryProvider<AlmacenamientoRepositorio>(
            create: (_) =>
                almacenamientoRepositorio ?? AlmacenamientoRepositorioSupabase()),

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
            create: (c) =>
                ListarCategoriasDePlanta(c.read<CategoriaRepositorio>())),
        RepositoryProvider(
            create: (c) => CrearCategoria(c.read<CategoriaRepositorio>())),
        RepositoryProvider(
            create: (c) => ListarZonasDePlanta(c.read<ZonaRepositorio>())),
        RepositoryProvider(
            create: (c) => CrearEquipo(c.read<EquipoRepositorio>())),
        RepositoryProvider(
            create: (c) => EditarEquipo(c.read<EquipoRepositorio>())),
        RepositoryProvider(
            create: (c) => DarDeBajaEquipo(c.read<EquipoRepositorio>())),
        RepositoryProvider(
            create: (c) => NuevoIdDeOrden(c.read<OrdenRepositorio>())),
        RepositoryProvider(
            create: (c) => EliminarOrden(c.read<OrdenRepositorio>())),
        // Reportes y evidencia
        RepositoryProvider(
            create: (c) =>
                ObservarReportesDeOrden(c.read<ReporteRepositorio>())),
        RepositoryProvider(
            create: (c) => UrlDeEvidencia(c.read<AlmacenamientoRepositorio>())),
        RepositoryProvider(
            create: (c) => SubirEvidencia(c.read<AlmacenamientoRepositorio>())),
        RepositoryProvider(
            create: (c) => PublicarReporte(c.read<ReporteRepositorio>())),
        RepositoryProvider(
            create: (c) => CerrarOrden(c.read<OrdenRepositorio>())),
        RepositoryProvider(
            create: (c) => DevolverOrden(c.read<OrdenRepositorio>())),
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
                editarOrden: EditarOrden(ordenes),
                asignarTecnico: AsignarTecnico(ordenes),
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
            Rutas.misTareas:     (_) => const MisTareasScreen(),
            Rutas.emergencia:    (_) => const EmergenciaScreen(),
            Rutas.espera:        (_) => const EsperaAprobacionScreen(),
            Rutas.solicitudes:   (_) => const SolicitudesScreen(),
          },
          // Rutas que necesitan la orden como parámetro
          onGenerateRoute: (settings) {
            final orden = settings.arguments;
            if (orden is! Orden) return null;
            final Widget? pantalla = switch (settings.name) {
              Rutas.detalleOrden  => DetalleOrdenScreen(orden: orden),
              Rutas.llenarReporte => LlenarReporteScreen(orden: orden),
              Rutas.validar       => ValidarEvidenciaScreen(orden: orden),
              _                   => null,
            };
            return pantalla == null
                ? null
                : MaterialPageRoute(builder: (_) => pantalla, settings: settings);
          },
        ),
      ),
    );
  }

  /// La cadena de autenticación: repositorio → casos de uso → Bloc.
  AuthBloc _crearAuthBloc(UsuarioRepositorio usuarios) {
    final auth = autenticacionRepositorio ?? AutenticacionRepositorioSupabase();
    return AuthBloc(
      comprobarSesion: ComprobarSesion(auth, usuarios),
      iniciarSesion: IniciarSesion(auth, usuarios),
      registrarSolicitud: RegistrarSolicitud(auth, usuarios),
      recargarPerfil: RecargarPerfil(auth, usuarios),
      cerrarSesion: CerrarSesion(auth),
    );
  }
}
