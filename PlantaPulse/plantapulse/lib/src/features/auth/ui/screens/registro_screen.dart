// lib/src/features/auth/ui/screens/registro_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});
  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  // ── Campos de texto ──
  final _nombreCtrl = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();

  // ── Selecciones ──
  // Rol y planta ya no se eligen aquí: los asigna el admin al aprobar.
  bool _aceptaTerminos = false;

  @override
  void initState() {
    super.initState();
    // Cada tecla redibuja para reevaluar si el botón se habilita
    _nombreCtrl.addListener(_refrescar);
    _emailCtrl.addListener(_refrescar);
    _passCtrl.addListener(_refrescar);
  }

  void _refrescar() => setState(() {});

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── La condición que habilita el botón ──
  bool get _formularioValido =>
      _nombreCtrl.text.trim().length >= 3 &&
      _emailCtrl.text.contains('@') &&
      _passCtrl.text.length >= 8 &&
      _aceptaTerminos;

  // La contraseña solo viaja a Firebase Auth; el perfil se guarda sin ella.
  void _registrar() {
    context.read<SesionBloc>().add(AuthRegistrarse(
      nombre: _nombreCtrl.text,
      email: _emailCtrl.text,
      password: _passCtrl.text,
    ));
  }

  void _alCambiarAuth(BuildContext context, AuthState state) {
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;

    if (state.hayError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.mensajeError ?? 'No se pudo completar el registro'),
          backgroundColor: AppColors.rojo,
        ),
      );
      return;
    }

    // Cuenta creada: a la espera, quitando login y registro del historial
    if (state.sesion == EstadoSesion.pendiente) {
      Navigator.pushNamedAndRemoveUntil(context, Rutas.espera, (_) => false);
    }
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
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28, color: AppColors.texto),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Crear Cuenta',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                           color: AppColors.texto)),
      ),
      body: BlocConsumer<SesionBloc, AuthState>(
        listenWhen: (antes, ahora) =>
            antes.sesion != ahora.sesion ||
            (ahora.hayError && antes.accion != ahora.accion),
        listener: _alCambiarAuth,
        builder: (context, state) => SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ══ HERO ══
              Container(
                width: double.infinity,
                color: AppColors.borde.withValues(alpha: 0.35),
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      height: 130,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.azulOscuro,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.precision_manufacturing_outlined,
                        size: 62, color: AppColors.naranja),
                    ),
                    const SizedBox(height: 16),
                    const Text('Únete a PlantaPulse',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                                       color: AppColors.azul)),
                    const SizedBox(height: 6),
                    const Text(
                      'Optimiza el mantenimiento industrial con nuestra '
                      'plataforma técnica avanzada.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textoGris,
                                       height: 1.4),
                    ),
                  ],
                ),
              ),

              // ══ FORMULARIO ══
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SeccionHeader(
                      icono: Icons.shield_outlined,
                      titulo: 'DATOS PERSONALES',
                    ),
                    CampoTexto(
                      label: 'NOMBRE COMPLETO',
                      hint: 'Ej. Juan Pérez',
                      iconoIzq: Icons.person_outline,
                      controller: _nombreCtrl,
                    ),
                    const SizedBox(height: 14),
                    CampoTexto(
                      label: 'CORREO ELECTRÓNICO',
                      hint: 'usuario@plantapulse.com',
                      iconoIzq: Icons.mail_outline,
                      controller: _emailCtrl,
                    ),
                    const SizedBox(height: 14),
                    CampoTexto(
                      label: 'CONTRASEÑA',
                      hint: '••••••••',
                      iconoIzq: Icons.lock_outline,
                      oculto: true,
                      controller: _passCtrl,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _passCtrl.text.isEmpty || _passCtrl.text.length >= 8
                          ? 'Mínimo 8 caracteres'
                          : 'Faltan ${8 - _passCtrl.text.length} caracteres',
                      style: TextStyle(
                        fontSize: 11,
                        color: _passCtrl.text.isNotEmpty && _passCtrl.text.length < 8
                            ? AppColors.rojo
                            : AppColors.textoGris,
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Divider(color: AppColors.borde),
                    const SizedBox(height: 12),

                    // ══ TÉRMINOS ══
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _aceptaTerminos,
                            activeColor: AppColors.azul,
                            onChanged: (v) =>
                                setState(() => _aceptaTerminos = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Acepto los términos de servicio y políticas de '
                            'seguridad industrial.',
                            style: TextStyle(fontSize: 12.5,
                                             fontWeight: FontWeight.w600,
                                             color: AppColors.texto,
                                             height: 1.35),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ══ BOTÓN ══
                    BotonAncho(
                      texto: state.cargando ? 'REGISTRANDO...' : 'COMPLETAR REGISTRO',
                      icono: state.cargando ? null : Icons.arrow_forward,
                      onTap: (_formularioValido && !state.cargando) ? _registrar : null,
                    ),

                    const SizedBox(height: 18),

                    // ══ PIE ══
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('¿Ya tienes una cuenta?',
                          style: TextStyle(fontSize: 12,
                                           color: AppColors.textoGris)),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Iniciar Sesión',
                            style: TextStyle(fontSize: 12,
                                             fontWeight: FontWeight.bold,
                                             color: AppColors.naranja)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user_outlined,
                          size: 13, color: AppColors.textoGris),
                        SizedBox(width: 6),
                        Text('CONEXIÓN SEGURA SSL',
                          style: TextStyle(fontSize: 10,
                                           color: AppColors.textoGris,
                                           letterSpacing: 1)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'PlantaPulse v2.4.0 — Sistema de Gestión de Activos '
                      'Industriales. Derechos Reservados © 2024.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: AppColors.textoGris,
                                       height: 1.4),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
