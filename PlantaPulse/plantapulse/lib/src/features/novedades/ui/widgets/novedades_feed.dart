import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../../domain/repositories/novedad_repositorio.dart';
import '../screens/detalle_novedad_screen.dart';
import '../screens/reportar_novedad_screen.dart';

class NovedadesFeed extends StatefulWidget {
  final Usuario usuario;

  const NovedadesFeed({super.key, required this.usuario});

  @override
  State<NovedadesFeed> createState() => _NovedadesFeedState();
}

class _NovedadesFeedState extends State<NovedadesFeed>
    with AutomaticKeepAliveClientMixin {
  static const _cantidadResumen = 2;
  late Stream<List<Novedad>> _novedades;
  bool _expandida = false;
  Novedad? _recienPublicada;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _novedades = _consultarNovedades();
  }

  Stream<List<Novedad>> _consultarNovedades() =>
      context.read<NovedadRepositorio>().deLaPlanta(widget.usuario.plantaId);

  Future<void> _reportar() async {
    final publicada = await Navigator.push<Novedad>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportarNovedadScreen(usuario: widget.usuario),
      ),
    );
    if (!mounted || publicada == null) return;
    setState(() {
      _recienPublicada = publicada;
      _novedades = _consultarNovedades();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Novedad publicada')));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<Novedad>>(
      stream: _novedades,
      builder: (context, snapshot) {
        final recibidas = snapshot.data ?? const <Novedad>[];
        final publicada = _recienPublicada;
        final novedades =
            publicada != null &&
                !recibidas.any((novedad) => novedad.id == publicada.id)
            ? [publicada, ...recibidas]
            : recibidas;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SeccionHeader(
              titulo: 'Novedades de la planta',
              accion: 'Reportar novedad',
              iconoAccion: Icons.add_comment_outlined,
              onAccion: _reportar,
            ),
            if (snapshot.hasError) ...[
              const Text('No se pudieron actualizar las novedades.'),
              TextButton(
                onPressed: () =>
                    setState(() => _novedades = _consultarNovedades()),
                child: const Text('Reintentar'),
              ),
            ] else if (!snapshot.hasData && novedades.isEmpty)
              const LinearProgressIndicator()
            else if (novedades.isEmpty)
              const Text('Aún no hay novedades publicadas.'),
            for (final novedad
                in _expandida ? novedades : novedades.take(_cantidadResumen))
              ListTile(
                contentPadding: EdgeInsets.zero,
                isThreeLine: true,
                leading: Icon(novedad.categoria.icono),
                title: Text(
                  novedad.descripcion,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${novedad.categoria.etiqueta} · ${novedad.estado.etiqueta}\n'
                  '${novedad.autor.nombre} · ${fechaCorta(novedad.createdAt)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetalleNovedadScreen(inicial: novedad),
                  ),
                ),
              ),
            if (novedades.length > _cantidadResumen)
              TextButton(
                onPressed: () => setState(() => _expandida = !_expandida),
                child: Text(
                  _expandida ? 'Ver menos' : 'Ver todas las novedades',
                ),
              ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}
