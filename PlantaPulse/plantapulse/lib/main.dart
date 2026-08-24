// lib/main.dart
import 'package:flutter/material.dart';
import 'package:plantapulse/src/theme/app_colors.dart';

import 'package:plantapulse/src/components/pill_estado.dart';
import 'package:plantapulse/src/components/meta_row.dart';
import 'package:plantapulse/src/components/seccion_header.dart';
import 'package:plantapulse/src/components/boton_ancho.dart';
import 'package:plantapulse/src/components/tile_aviso.dart';
import 'package:plantapulse/src/components/tarjeta_oscura.dart';
import 'package:plantapulse/src/components/chips_fila.dart';
import 'package:plantapulse/src/components/orden_card.dart';
import 'package:plantapulse/src/components/grid_fotos.dart';
import 'package:plantapulse/src/components/fila_alerta.dart';
import 'package:plantapulse/src/components/stat_card.dart';
import 'package:plantapulse/src/components/campo_texto.dart';
import 'package:plantapulse/src/components/fila_opcion.dart';
import 'package:plantapulse/src/components/dotted_box.dart';
import 'package:plantapulse/src/components/pantalla_base.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlantaPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.azul,
          primary: AppColors.azul,
          secondary: AppColors.naranja,
        ),
        scaffoldBackgroundColor: AppColors.fondo,
      ),
      home: const GaleriaComponentes(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GALERÍA
// Es StatefulWidget porque el Switch de FilaOpcion necesita setState.
// ═══════════════════════════════════════════════════════════════
class GaleriaComponentes extends StatefulWidget {
  const GaleriaComponentes({super.key});

  @override
  State<GaleriaComponentes> createState() => _GaleriaComponentesState();
}

class _GaleriaComponentesState extends State<GaleriaComponentes> {
  // Estado del Switch de la fila de Ajustes
  bool _push = true;

  // Controlador para leer lo que se escribe en el CampoTexto
  final _correoCtrl = TextEditingController();

  // Estado del ojito de la contraseña
  bool _ocultarPass = true;

  @override
  void dispose() {
    _correoCtrl.dispose(); // libera memoria al cerrar la pantalla
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galería de componentes'),
        backgroundColor: AppColors.azul,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─────────────────────────────────────────────
                // 15. DottedBox — NECESITA tamaño explícito
                // ─────────────────────────────────────────────
                _titulo('DottedBox'),
                const Text(
                  'Solo pinta el borde: no tiene tamaño propio. Siempre '
                  'envuélvelo en un SizedBox o úsalo dentro de un GridView.',
                  style: AppText.gris,
                ),
                const SizedBox(height: 10),
                const SizedBox(
                  height: 110,
                  width: 110,
                  child: DottedBox(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined,
                            color: AppColors.textoGris),
                        SizedBox(height: 4),
                        Text('Tomar Foto', style: AppText.gris),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Variante ancha y en rojo (zona de emergencia)
                const SizedBox(
                  height: 70,
                  width: double.infinity,
                  child: DottedBox(
                    color: AppColors.rojo,
                    radius: 12,
                    child: Center(
                      child: Text('Adjuntar evidencia del incidente',
                          style: AppText.gris),
                    ),
                  ),
                ),
 
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _titulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(texto,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.azul)),
          const Divider(color: AppColors.borde),
        ],
      ),
    );
  }
}

