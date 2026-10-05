// lib/src/features/auth/ui/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';

class SplashScreen extends StatefulWidget {
  //se crean 2 clases
  //Flutter destruye y reconstruye widgets constantemente — decenas de veces por segundo
  //durante una animación. Si el temporizador viviera en el widget, 
  //se reiniciaría en cada reconstrucción.

  //La solución: el widget es desechable (por eso es const), y el State es el que persiste. 
  //Flutter llama a createState() una sola vez
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}


class _SplashScreenState extends State<SplashScreen> {

  Timer? _timer;
  bool _timerTerminado = false;
  bool _yaNavego = false;

  //esta es la parte que arranca y comienza a ejecutar todo 
  //initState corre una sola vez, justo cuando el State nace, antes del primer build. 
  //Es donde va todo lo que se configura al arrancar: temporizadores, listeners, peticiones iniciales al API.

  //super.initState() va primero, siempre. Flutter hace su propia inicialización ahí; 
  //si lo pones al final o lo omites, obtienes errores raros.
  @override
  void initState() {
    super.initState();

    //Timer recibe dos cosas: cuánto esperar y qué hacer después. 
    //Ese () { ... } es una función anónima (callback) — código empaquetado para ejecutarse más tarde.
    // CAMBIO: el Timer ya no decide a dónde ir; solo marca que terminó.
    // La sesión la resuelve el SesionBloc (lanzado en main.dart).
    _timer = Timer(const Duration(seconds: 3), () {
      _timerTerminado = true;
      _intentarNavegar(context.read<SesionBloc>().state);
    });
  }

  // Se navega solo cuando se cumplen DOS condiciones: el Timer terminó
  // y el SesionBloc ya sabe a qué pantalla pertenece el usuario.
  // Se llama desde el Timer y desde el BlocListener; el que llegue último navega.
  void _intentarNavegar(AuthState state) {
    if (!mounted || _yaNavego || !_timerTerminado) return;
    if (state.sesion == EstadoSesion.desconocida) return;

    _yaNavego = true;
    final destino = switch (state.sesion) {
      EstadoSesion.activa      => Rutas.feed,
      EstadoSesion.pendiente   => Rutas.espera,
      EstadoSesion.rechazada   => Rutas.espera, // la pantalla decide el modo
      EstadoSesion.sinCuenta ||
      EstadoSesion.desconocida => Rutas.login,
    };
    Navigator.pushReplacementNamed(context, destino);
  }

  //metodo para cancelar
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  //metodo para crear
  //este es el widget anidado
  @override
  Widget build(BuildContext context) {
    return BlocListener<SesionBloc, AuthState>(
      listenWhen: (antes, ahora) => antes.sesion != ahora.sesion,
      listener: (context, state) => _intentarNavegar(state),
      child: Scaffold(//es la base de la pantalla
        backgroundColor: AppColors.azulOscuro,
        body: SafeArea(//es el area donde van a estar los componentes
          child: Padding(//Aparta el contenido de las zonas donde el sistema dibuja: el notch arriba, la barra de gestos abajo
            padding: const EdgeInsets.all(24),//son 24 píxeles lógicos por los cuatro costados
            child: Column(
              children: [
                const Spacer(flex: 3),

                // ── Logo ──
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: AppColors.azul,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.settings, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(text: 'Planta', style: TextStyle(color: Colors.white)),
                      TextSpan(text: 'Pulse',  style: TextStyle(color: AppColors.naranja)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Gestión de planta en tiempo real',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),

                const Spacer(flex: 3),

                // ── Cargando ──
                const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    color: AppColors.naranja,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'SINCRONIZANDO SISTEMAS...',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),

                const Spacer(flex: 2),

                // ── Pie ──
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ESTADO',
                          style: TextStyle(color: Colors.white38, fontSize: 10,
                                           letterSpacing: 1)),
                        SizedBox(height: 4),
                        Text('OPERATIVO',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('VERSIÓN',
                          style: TextStyle(color: Colors.white38, fontSize: 10,
                                           letterSpacing: 1)),
                        SizedBox(height: 4),
                        Text('V2.4.0-PRO',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}