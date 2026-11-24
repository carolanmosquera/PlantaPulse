import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../../domain/repositories/novedad_repositorio.dart';

class ReportarNovedadScreen extends StatefulWidget {
  final Usuario usuario;

  const ReportarNovedadScreen({super.key, required this.usuario});

  @override
  State<ReportarNovedadScreen> createState() => _ReportarNovedadScreenState();
}

class _ReportarNovedadScreenState extends State<ReportarNovedadScreen> {
  final _fotos = <FotoPendiente>[];
  String _descripcion = '';
  CategoriaNovedad? _categoria;
  String? _id;
  String? _error;
  bool _publicando = false;
  bool _eligiendoFoto = false;
  int _siguienteFoto = 0;

  int get _largoDescripcion => _descripcion.trim().runes.length;

  bool get _descripcionValida =>
      _largoDescripcion >= minDescripcionNovedad &&
      _largoDescripcion <= maxDescripcionNovedad;

  bool get _puedePublicar =>
      !_publicando && !_eligiendoFoto && _categoria != null && _descripcionValida;

  /// Error visible bajo la descripción en cuanto se escribe algo demasiado corto.
  String? get _errorDescripcion {
    if (_descripcion.isEmpty || _descripcionValida) return null;
    if (_largoDescripcion > maxDescripcionNovedad) {
      return 'Máximo $maxDescripcionNovedad caracteres.';
    }
    final faltan = minDescripcionNovedad - _largoDescripcion;
    return 'Escribe al menos $minDescripcionNovedad caracteres '
        '(${faltan == 1 ? 'falta 1' : 'faltan $faltan'}).';
  }

  /// Explica por qué el botón de publicar está deshabilitado.
  String? get _requisitosPendientes {
    if (_publicando || _eligiendoFoto) return null;
    final faltan = [
      if (!_descripcionValida)
        'describe la novedad con al menos $minDescripcionNovedad caracteres',
      if (_categoria == null) 'elige una categoría',
    ];
    if (faltan.isEmpty) return null;
    return 'Para publicar, ${faltan.join(' y ')}.';
  }

  Future<void> _agregarFoto() async {
    if (_eligiendoFoto || _publicando || _fotos.length >= maxFotosPorNovedad) {
      return;
    }
    final obtener = context.read<ObtenerFoto>();
    setState(() {
      _eligiendoFoto = true;
      _error = null;
    });
    try {
      final origen = await elegirOrigenFoto(
        context,
        camara: OrigenFoto.camara,
        galeria: OrigenFoto.galeria,
      );
      if (!mounted || origen == null) return;
      final foto = await obtener.ejecutar(origen);
      if (!mounted || foto == null) return;
      setState(
        () => _fotos.add(FotoPendiente(id: _siguienteFoto++, foto: foto)),
      );
    } catch (error) {
      if (mounted) setState(() => _error = FalloApp.mensajeDe(error));
    } finally {
      if (mounted) setState(() => _eligiendoFoto = false);
    }
  }

  Future<void> _publicar() async {
    if (!_puedePublicar) return;
    final repositorio = context.read<NovedadRepositorio>();
    final subir = context.read<SubirEvidencia>();
    final usuario = widget.usuario;
    final categoria = _categoria!;
    final descripcion = _descripcion.trim();
    final id = _id ??= repositorio.nuevoId();
    FocusScope.of(context).unfocus();
    setState(() {
      _publicando = true;
      _error = null;
    });
    try {
      for (var i = 0; i < _fotos.length; i++) {
        final foto = _fotos[i];
        if (foto.subida) continue;
        final ruta = await subir.ejecutar(
          plantaId: usuario.plantaId,
          registroId: id,
          bytes: foto.foto.bytes,
          extension: foto.foto.extension,
        );
        if (!mounted) return;
        setState(() => _fotos[i] = foto.subidaA(ruta, DateTime.now()));
      }
      final publicada = await repositorio.publicar(
        Novedad(
          id: id,
          plantaId: usuario.plantaId,
          descripcion: descripcion,
          categoria: categoria,
          autor: usuario.ref,
          evidencias: [
            for (final foto in _fotos)
              Evidencia(
                ruta: foto.ruta!,
                subidaEn: foto.subidaEn!,
                autorUid: usuario.uid,
              ),
          ],
          createdAt: DateTime.now(),
        ),
      );
      if (mounted) Navigator.pop(context, publicada);
    } catch (error) {
      if (mounted) {
        setState(() {
          _publicando = false;
          _error =
              'No se pudo publicar la novedad. ${FalloApp.mensajeDe(error)}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_publicando,
      child: PantallaBase(
        titulo: 'Reportar novedad',
        mostrarAtras: !_publicando,
        conNavegacion: false,
        cuerpo: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                enabled: !_publicando,
                minLines: 3,
                maxLines: 5,
                maxLength: maxDescripcionNovedad,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  hintText: '¿Qué observaste?',
                  helperText: 'Mínimo $minDescripcionNovedad caracteres',
                  errorText: _errorDescripcion,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                onChanged: (texto) => setState(() => _descripcion = texto),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CategoriaNovedad>(
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final categoria in CategoriaNovedad.values)
                    DropdownMenuItem(
                      value: categoria,
                      child: Text(categoria.etiqueta),
                    ),
                ],
                onChanged: _publicando
                    ? null
                    : (categoria) => setState(() => _categoria = categoria),
              ),
              SeccionHeader(
                titulo: 'Fotos',
                accion: '${_fotos.length}/$maxFotosPorNovedad · Opcional',
              ),
              CuadriculaFotosLocales(
                imagenes: [for (final foto in _fotos) foto.foto.bytes],
                subidas: [for (final foto in _fotos) foto.subida],
                puedeAgregar: _fotos.length < maxFotosPorNovedad,
                bloqueada: _publicando || _eligiendoFoto,
                onAgregar: _agregarFoto,
                onQuitar: (i) => setState(() => _fotos.removeAt(i)),
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                TileAviso(
                  icono: Icons.error_outline,
                  titulo: _error!,
                  color: AppColors.rojo,
                ),
                const SizedBox(height: 12),
              ],
              if (_requisitosPendientes case final pendientes?) ...[
                Text(
                  pendientes,
                  key: const Key('novedad-requisitos'),
                  style: TextStyle(color: AppColors.rojo.segunTema(context)),
                ),
                const SizedBox(height: 8),
              ],
              BotonAncho(
                texto: _publicando ? 'Publicando…' : 'Publicar novedad',
                icono: Icons.send_outlined,
                onTap: _puedePublicar ? _publicar : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
