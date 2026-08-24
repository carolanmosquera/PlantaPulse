// lib/main.dart
import 'package:flutter/material.dart';
import 'src/theme/app_colors.dart';
import 'src/theme/rutas.dart';
import 'src/models/orden.dart';
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

void main() => runApp(const PlantaPulseApp());

class PlantaPulseApp extends StatelessWidget {
  const PlantaPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }
}