// lib/src/features/auth/ui/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';

//inicializaciones de la pagina
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //los atributos que va a utilizar
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _recordar = false;

  //el metodo para cerra
  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _entrar() {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa correo y contraseña')),
      );
      return;
    }

    // Solo valida y avisa al Bloc; la navegación la hace el listener
    context.read<SesionBloc>().add(AuthIniciarSesion(
      email: _emailCtrl.text,
      password: _passCtrl.text,
    ));
  }

  // Reacciona a lo que emite el SesionBloc: navegar o mostrar el error.
  void _alCambiarAuth(BuildContext context, AuthState state) {
    // Si Registro está encima, este listener también está vivo: no actuar.
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;

    if (state.hayError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.mensajeError ?? 'No se pudo iniciar sesión'),
          backgroundColor: AppColors.rojo,
        ),
      );
      return;
    }

    final destino = switch (state.sesion) {
      EstadoSesion.activa    => Rutas.feed,
      EstadoSesion.pendiente => Rutas.espera,
      EstadoSesion.rechazada => Rutas.espera,
      _                      => null, // sin cuenta: se queda en el login
    };
    if (destino != null) Navigator.pushReplacementNamed(context, destino);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Acceso al Sistema',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                           color: AppColors.texto)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borde),
        ),
      ),
      body: BlocConsumer<SesionBloc, AuthState>(
        listenWhen: (antes, ahora) =>
            antes.sesion != ahora.sesion ||
            (ahora.hayError && antes.accion != ahora.accion),
        listener: _alCambiarAuth,
        builder: (context, state) => SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              // ── Cabecera ──
              Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.azul,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.bolt, color: Colors.white, size: 32),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gestión eficiente de mantenimiento industrial y monitoreo en tiempo real.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textoGris, height: 1.4),
              ),
              const SizedBox(height: 20),

              // Ilustración (placeholder gris del mockup)
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.borde.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.factory_outlined,
                  size: 64, color: AppColors.azul),
              ),
              const SizedBox(height: 24),

              // ── Campos ──
              CampoTexto(
                label: 'CORREO ELECTRÓNICO',
                hint: 'nombre@empresa.com',
                iconoIzq: Icons.mail_outline,
                controller: _emailCtrl,
              ),
              const SizedBox(height: 16),
              CampoTexto(
                label: 'CONTRASEÑA',
                hint: '••••••••',
                iconoIzq: Icons.lock_outline,
                oculto: true,
                controller: _passCtrl,
                accionDerecha: GestureDetector(
                  onTap: () {},
                  child: const Text('¿Olvidaste tu contraseña?',
                    style: TextStyle(fontSize: 11, color: AppColors.textoGris)),
                ),
              ),
              const SizedBox(height: 6),

              // ── Checkbox ──
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _recordar,
                      activeColor: AppColors.azul,
                      onChanged: (v) => setState(() => _recordar = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Recordar sesión en este dispositivo',
                    style: TextStyle(fontSize: 13, color: AppColors.textoGris)),
                ],
              ),
              const SizedBox(height: 18),

              // ── Botones ──
              BotonAncho(
                texto: state.cargando ? 'Ingresando...' : 'Iniciar Sesión',
                icono: state.cargando ? null : Icons.arrow_forward,
                onTap: state.cargando ? null : _entrar,
              ),
              const SizedBox(height: 22),
              const Row(
                children: [
                  Expanded(child: Divider(color: AppColors.borde)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('¿No tienes una cuenta aún?',
                      style: TextStyle(fontSize: 13, color: AppColors.textoGris)),
                  ),
                  Expanded(child: Divider(color: AppColors.borde)),
                ],
              ),
              const SizedBox(height: 14),
              BotonAncho(
                texto: 'Registrar nuevo personal',
                estilo: EstiloBoton.borde,
                onTap: () => Navigator.pushNamed(context, Rutas.registro),
              ),
              const SizedBox(height: 28),

              // ── Pie ──
              const Center(child: Text('v2.4.0 • Enterprise Edition',
                style: TextStyle(fontSize: 11, color: AppColors.textoGris))),
              const SizedBox(height: 4),
              const Center(child: Text('Términos   Privacidad   Soporte',
                style: TextStyle(fontSize: 11, color: AppColors.textoGris))),
            ],
          ),
        ),
      ),
    );
  }
}