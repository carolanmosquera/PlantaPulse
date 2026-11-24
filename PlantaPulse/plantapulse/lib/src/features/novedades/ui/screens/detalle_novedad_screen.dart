import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../../../crear_orden/ui/screens/crear_orden_p1_screen.dart';
import '../../domain/repositories/novedad_repositorio.dart';

class DetalleNovedadScreen extends StatefulWidget {
  final Novedad inicial;

  const DetalleNovedadScreen({super.key, required this.inicial});

  @override
  State<DetalleNovedadScreen> createState() => _DetalleNovedadScreenState();
}

class _DetalleNovedadScreenState extends State<DetalleNovedadScreen> {
  late Future<Novedad?> _novedad;
  bool _ocupada = false;

  @override
  void initState() {
    super.initState();
    _novedad = _consultar();
  }

  Future<Novedad?> _consultar() =>
      context.read<NovedadRepositorio>().obtener(widget.inicial.id);

  void _actualizar() {
    final consulta = _consultar();
    setState(() {
      _novedad = consulta;
    });
  }

  void _avisar(String mensaje) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(mensaje)));

  Future<void> _convertir(Novedad novedad) async {
    await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => CrearOrdenP1Screen(novedad: novedad)),
    );
    if (mounted) _actualizar();
  }

  Future<void> _descartar(Novedad novedad) async {
    var motivo = '';
    final confirmado = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, actualizar) => AlertDialog(
          title: const Text('Descartar novedad'),
          content: TextField(
            autofocus: true,
            maxLength: maxDescripcionNovedad,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Motivo del descarte'),
            onChanged: (texto) => actualizar(() => motivo = texto.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed:
                  motivo.isEmpty || motivo.runes.length > maxDescripcionNovedad
                  ? null
                  : () => Navigator.pop(context, motivo),
              child: const Text('Confirmar descarte'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || confirmado == null) return;

    setState(() => _ocupada = true);
    try {
      await context.read<NovedadRepositorio>().descartar(
        novedad.id,
        confirmado,
      );
      if (mounted) _avisar('Novedad descartada');
    } catch (e) {
      if (mounted) _avisar(FalloApp.mensajeDe(e));
    } finally {
      if (mounted) {
        setState(() {
          _ocupada = false;
          _novedad = _consultar();
        });
      }
    }
  }

  Future<void> _verOrden(String id) async {
    setState(() => _ocupada = true);
    try {
      final orden = await context.read<OrdenRepositorio>().obtener(id);
      if (!mounted) return;
      if (orden == null) {
        _avisar('La orden vinculada no está disponible.');
        return;
      }
      Navigator.pushNamed(context, Rutas.detalleOrden, arguments: orden);
    } catch (e) {
      if (mounted) _avisar(FalloApp.mensajeDe(e));
    } finally {
      if (mounted) setState(() => _ocupada = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<SesionBloc>().state.usuario;
    return PantallaBase(
      titulo: 'Detalle de novedad',
      conNavegacion: false,
      cuerpo: FutureBuilder<Novedad?>(
        future: _novedad,
        initialData: widget.inicial,
        builder: (context, snapshot) {
          final novedad = snapshot.data;
          if (snapshot.hasError || novedad == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    snapshot.hasError
                        ? 'No se pudo consultar la novedad.'
                        : 'La novedad no está disponible.',
                  ),
                  TextButton(
                    onPressed: _actualizar,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final cargando = snapshot.connectionState == ConnectionState.waiting;
          final puedeDecidir =
              usuario != null &&
              usuario.puedeEntrar &&
              usuario.plantaId == novedad.plantaId &&
              usuario.rol.puedeOperar &&
              novedad.puedeConvertirse;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (cargando || _ocupada) const LinearProgressIndicator(),
              Align(
                alignment: Alignment.centerLeft,
                child: PillEstado(
                  texto: novedad.estado.etiqueta,
                  color: novedad.estado.color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                novedad.descripcion,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('${novedad.categoria.etiqueta} · ${novedad.autor.nombre}'),
              Text('${novedad.grupo} · ${novedad.hora}'),
              if (novedad.zonaNombre.isNotEmpty) Text(novedad.zonaNombre),
              if (novedad.evidencias.isNotEmpty) ...[
                const SeccionHeader(titulo: 'Fotos'),
                GaleriaFotos(
                  urls: [
                    for (final foto in novedad.evidencias)
                      context.read<UrlDeEvidencia>().ejecutar(foto.ruta),
                  ],
                ),
              ],
              if (novedad.revisadaPor case final revisor?) ...[
                const SizedBox(height: 16),
                Text('Revisada por ${revisor.nombre}'),
              ],
              if (novedad.motivoDescarte case final motivo?) ...[
                const SeccionHeader(titulo: 'Motivo del descarte'),
                Text(motivo),
              ],
              if (novedad.ordenId case final id?) ...[
                const SizedBox(height: 20),
                BotonAncho(
                  texto: 'Ver orden vinculada',
                  icono: Icons.assignment_outlined,
                  onTap: _ocupada || cargando ? null : () => _verOrden(id),
                ),
              ],
              if (puedeDecidir) ...[
                const SizedBox(height: 20),
                BotonAncho(
                  texto: 'Convertir en orden',
                  icono: Icons.assignment_add,
                  onTap: _ocupada || cargando
                      ? null
                      : () => _convertir(novedad),
                ),
                const SizedBox(height: 10),
                BotonAncho(
                  texto: 'Descartar novedad',
                  estilo: EstiloBoton.borde,
                  color: AppColors.rojo,
                  onTap: _ocupada || cargando
                      ? null
                      : () => _descartar(novedad),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
