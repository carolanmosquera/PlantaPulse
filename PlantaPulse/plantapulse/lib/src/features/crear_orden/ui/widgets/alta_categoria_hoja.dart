// lib/src/features/crear_orden/ui/widgets/alta_categoria_hoja.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../../domain/usecases/crear_orden_casos.dart';

/// Alta de categoría: nombre e icono. Devuelve la categoría guardada
/// (con su id) o null si se canceló.
class AltaCategoriaHoja extends StatefulWidget {
  final String plantaId;
  final UsuarioRef creadaPor;

  const AltaCategoriaHoja({
    super.key,
    required this.plantaId,
    required this.creadaPor,
  });

  static Future<Categoria?> mostrar(
    BuildContext context, {
    required String plantaId,
    required UsuarioRef creadaPor,
  }) =>
      HojaFormulario.mostrar<Categoria>(
        context,
        AltaCategoriaHoja(plantaId: plantaId, creadaPor: creadaPor),
      );

  @override
  State<AltaCategoriaHoja> createState() => _AltaCategoriaHojaState();
}

class _AltaCategoriaHojaState extends State<AltaCategoriaHoja> {
  final _nombre = TextEditingController();
  String _icono = 'etiqueta';
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nombre.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final crear = context.read<CrearCategoria>();
    final navegador = Navigator.of(context);
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final creada = await crear.ejecutar(Categoria(
        id: '',                       // lo genera la base de datos
        plantaId: widget.plantaId,
        nombre: _nombre.text.trim(),
        icono: _icono,
        creadaPor: widget.creadaPor,
      ));
      navegador.pop(creada);
    } catch (e) {
      // Un nombre repetido llega con su propio mensaje: el usuario
      // probablemente no vio la categoría porque estaba fuera de pantalla
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = FalloApp.mensajeDe(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final valido = _nombre.text.trim().isNotEmpty;
    return HojaFormulario(
      titulo: 'Crear categoría',
      error: _error,
      guardando: _guardando,
      alGuardar: valido ? _guardar : null,
      campos: [
        CampoTexto(label: 'Nombre', hint: 'Ej: Neumático',
            controller: _nombre),
        const Text('ICONO', style: AppText.label),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (final MapEntry(key: clave, value: icono) in iconosCategoria.entries)
              _celdaIcono(clave, icono),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _celdaIcono(String clave, IconData icono) {
    final activo = _icono == clave;
    return InkWell(
      onTap: () => setState(() => _icono = clave),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: activo ? AppColors.azul : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: activo ? AppColors.azul : AppColors.borde),
        ),
        child: Icon(icono, color: activo ? Colors.white : AppColors.textoGris),
      ),
    );
  }
}
