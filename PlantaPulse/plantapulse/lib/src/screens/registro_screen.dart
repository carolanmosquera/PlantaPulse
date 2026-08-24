// lib/src/screens/registro_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/rutas.dart';
import '../components/widgets.dart';

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
  String? _rol;
  String? _planta;
  bool _aceptaTerminos = false;
  bool _cargando = false;

//aqui ve agregando que roles van 
  static const _roles = [
    'Técnico de Mantenimiento',
    'Supervisor de Planta',
    'Ingeniero de Confiabilidad',
    'Operador de Línea',
  ];

//aqui van los nombre de la planta (ejemplo, la idea es que se venga de la base de datos)
  static const _plantas = [
    'Planta Norte',
    'Planta Sur',
    'Planta A - Compresores',
    'Centro de Distribución',
  ];

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
      _rol != null &&
      _planta != null &&
      _aceptaTerminos;

  Future<void> _registrar() async {
    setState(() => _cargando = true);
    await Future.delayed(const Duration(milliseconds: 800)); // simula el API
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cuenta creada correctamente'),
        backgroundColor: AppColors.verde,
      ),
    );
    Navigator.pop(context);   // vuelve al login
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
      body: SafeArea(
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

                  const SeccionHeader(
                    icono: Icons.business_outlined,
                    titulo: 'ASIGNACIÓN LABORAL',
                  ),
                  _dropdown(
                    label: 'ROL EN LA PLANTA',
                    hint: 'Seleccionar rol',
                    icono: Icons.badge_outlined,
                    valor: _rol,
                    opciones: _roles,
                    onCambio: (v) => setState(() => _rol = v),
                  ),
                  const SizedBox(height: 14),
                  _dropdown(
                    label: 'SEDE / PLANTA DE OPERACIÓN',
                    hint: 'Seleccionar planta',
                    icono: Icons.factory_outlined,
                    valor: _planta,
                    opciones: _plantas,
                    onCambio: (v) => setState(() => _planta = v),
                  ),

                  const SizedBox(height: 18),

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
                    texto: _cargando ? 'REGISTRANDO...' : 'COMPLETAR REGISTRO',
                    icono: _cargando ? null : Icons.arrow_forward,
                    onTap: (_formularioValido && !_cargando) ? _registrar : null,
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
    );
  }

  // ══════════ Dropdown reutilizable ══════════
  Widget _dropdown({
    required String label,
    required String hint,
    required IconData icono,
    required String? valor,
    required List<String> opciones,
    required ValueChanged<String?> onCambio,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borde),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: valor,
              isExpanded: true,
              hint: Row(
                children: [
                  Icon(icono, size: 18, color: AppColors.textoGris),
                  const SizedBox(width: 10),
                  Text(hint, style: const TextStyle(
                    fontSize: 14, color: AppColors.textoGris)),
                ],
              ),
              icon: const Icon(Icons.keyboard_arrow_down,
                color: AppColors.textoGris),
              items: opciones.map((o) => DropdownMenuItem(
                value: o,
                child: Row(
                  children: [
                    Icon(icono, size: 18, color: AppColors.azul),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(o, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14,
                                               color: AppColors.texto)),
                    ),
                  ],
                ),
              )).toList(),
              onChanged: onCambio,
            ),
          ),
        ),
      ],
    );
  }
}