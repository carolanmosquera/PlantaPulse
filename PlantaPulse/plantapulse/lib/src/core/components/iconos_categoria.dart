// lib/src/core/components/iconos_categoria.dart
import 'package:flutter/material.dart';

/// Clave guardada en categorias.icono → icono de Flutter.
/// Las claves de la base son exactamente estas; el formulario de alta de
/// categoría deja escoger entre ellas.
const Map<String, IconData> iconosCategoria = {
  'llave':      Icons.build_outlined,
  'rayo':       Icons.bolt_outlined,
  'gota':       Icons.water_drop_outlined,
  'lupa':       Icons.search,
  'engranaje':  Icons.settings_outlined,
  'termometro': Icons.thermostat_outlined,
  'fuego':      Icons.local_fire_department_outlined,
  'alerta':     Icons.warning_amber_outlined,
  'etiqueta':   Icons.label_outline,
};

/// Una clave desconocida (escrita a mano en el panel) no rompe la UI.
IconData iconoDeCategoria(String clave) =>
    iconosCategoria[clave] ?? Icons.label_outline;
