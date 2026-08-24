// lib/src/screens/crear_orden_p1_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/borrador_orden.dart';
import '../components/widgets.dart';
import 'crear_orden_p2_screen.dart';

class CrearOrdenP1Screen extends StatefulWidget {
  const CrearOrdenP1Screen({super.key});
  @override
  State<CrearOrdenP1Screen> createState() => _CrearOrdenP1ScreenState();
}

class _CrearOrdenP1ScreenState extends State<CrearOrdenP1Screen> {
  final _descCtrl = TextEditingController();
  int _categoria = 0;
  String? _equipoNombre;
  String? _equipoCodigo;

  static const _categorias = ['Mecánico', 'Eléctrico', 'Crítico', 'Otro'];
  static const _iconos = [Icons.build_outlined, Icons.bolt,
                          Icons.warning_amber_rounded, Icons.more_horiz];

  @override
  void initState() {
    super.initState();
    _descCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _puedeSeguir =>
      _descCtrl.text.trim().length >= 10 && _equipoNombre != null;

  Future<void> _continuar() async {
    final borrador = BorradorOrden()
      ..descripcion = _descCtrl.text.trim()
      ..categoria = _categorias[_categoria]
      ..equipoNombre = _equipoNombre
      ..equipoCodigo = _equipoCodigo;

    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CrearOrdenP2Screen(borrador: borrador)),
    );

    if (!mounted) return;
    if (resultado != null) Navigator.pop(context, resultado);
  }

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: 'Crear Nueva Orden',
      tabActiva: 0,
      cuerpo: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 14),

          // ══ PROGRESO ══
          Row(
            children: [
              const PillEstado(texto: 'PASO 1 DE 2', color: AppColors.azulOscuro,
                relleno: true),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: const LinearProgressIndicator(
                    value: 0.5, minHeight: 4,
                    backgroundColor: AppColors.borde,
                    color: AppColors.azul,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text('¿Cuál es el problema?',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold,
                             color: AppColors.texto)),
          const SizedBox(height: 8),
          const Text(
            'Describe el hallazgo o falla técnica. Puedes usar el dictado '
            'por voz para mayor rapidez.',
            style: TextStyle(fontSize: 13.5, color: AppColors.textoGris,
                             height: 1.4)),
          const SizedBox(height: 16),

          // ══ DESCRIPCIÓN ══
          CampoTexto(
            label: '',
            hint: 'Ej: Se detectó una fuga de aceite en el sello mecánico '
                  'del motor principal, temperatura elevada...',
            lineas: 4,
            controller: _descCtrl,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 13,
                color: _descCtrl.text.trim().length >= 10
                    ? AppColors.textoGris : AppColors.rojo),
              const SizedBox(width: 6),
              Text('Mínimo 10 caracteres',
                style: TextStyle(fontSize: 11.5,
                  color: _descCtrl.text.isNotEmpty &&
                         _descCtrl.text.trim().length < 10
                      ? AppColors.rojo : AppColors.textoGris)),
              const Spacer(),
              Container(
                width: 42, height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.naranja, shape: BoxShape.circle),
                child: const Icon(Icons.mic, color: Colors.white, size: 20),
              ),
            ],
          ),

          // ══ CATEGORÍA ══
          const SeccionHeader(titulo: 'CATEGORÍA INICIAL',
            accion: 'Obligatorio'),
          ChipsFila(
            opciones: _categorias,
            iconos: _iconos,
            onCambio: (i) => setState(() => _categoria = i),
          ),

          // ══ EQUIPOS ══
          SeccionHeader(
            icono: Icons.history,
            titulo: 'EQUIPOS RECIENTES',
            accion: 'BUSCAR TODOS',
            onAccion: () {},
          ),
          _equipo('Compresor GA75', 'Sector 04 • EQ-8821'),
          const SizedBox(height: 10),
          _equipo('Bomba Centrífuga P-1', 'Línea A • EQ-4490'),

          const SizedBox(height: 20),
          const Center(child: Text('PLANTAPULSE INDUSTRIAL CORE V3.4',
            style: TextStyle(fontSize: 9.5, color: AppColors.textoGris,
                             letterSpacing: 1.5))),
          const SizedBox(height: 16),

          BotonAncho(
            texto: 'Estructurar con IA',
            icono: Icons.auto_awesome,
            onTap: _puedeSeguir ? _continuar : null,
          ),
          const SizedBox(height: 8),
          const Center(child: Text(
            'La IA analizará tu reporte para sugerir equipo, prioridad y tags.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textoGris))),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _equipo(String nombre, String detalle) {
    final seleccionado = _equipoNombre == nombre;
    return FilaOpcion(
      icono: Icons.build_outlined,
      titulo: nombre,
      subtitulo: detalle,
      color: seleccionado ? AppColors.azul : AppColors.textoGris,
      trailing: Icon(
        seleccionado ? Icons.check_circle : Icons.chevron_right,
        color: seleccionado ? AppColors.verde : AppColors.textoGris,
        size: seleccionado ? 22 : 20,
      ),
      onTap: () => setState(() {
        _equipoNombre = nombre;
        _equipoCodigo = detalle.split('• ').last;
      }),
    );
  }
}