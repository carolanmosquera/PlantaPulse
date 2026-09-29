// lib/src/components/pantalla_base.dart
import 'package:flutter/material.dart';
import 'package:plantapulse/src/theme/app_colors.dart';
import 'package:plantapulse/src/theme/rutas.dart';

class PantallaBase extends StatelessWidget {
  final String titulo;
  final Widget cuerpo;
  final bool mostrarAtras;
  final bool mostrarMenu;
  final List<Widget>? accionesExtra;
  final Widget? fab;
  final Widget? barraInferiorFija; // el campo de comentario del detalle
  final int tabActiva;
  final bool conNavegacion;

  const PantallaBase({
    super.key,
    required this.titulo,
    required this.cuerpo,
    this.mostrarAtras = true,
    this.mostrarMenu = false,
    this.accionesExtra,
    this.fab,
    this.barraInferiorFija,
    this.tabActiva = 0,
    this.conNavegacion = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: AppColors.fondo,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: mostrarAtras
            ? IconButton(
                icon: const Icon(Icons.chevron_left, size: 28),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(titulo, style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.texto)),
        actions: [
          ...?accionesExtra,
          if (mostrarMenu)
            IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borde),
        ),
      ),
      body: cuerpo,
      floatingActionButton: fab,
      bottomNavigationBar: conNavegacion
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (barraInferiorFija != null) barraInferiorFija!,
                _navInferior(context),
              ],
            )
          : barraInferiorFija,
    );
  }

  // Destino de cada pestaña, en el mismo orden que los items
  static const _destinos = [Rutas.feed, Rutas.alertas, Rutas.perfil];

  void _irAPestana(BuildContext context, int i) {
    final destino = _destinos[i];
    // Se compara con la ruta actual y no con tabActiva: Ajustes marca
    // Perfil como activa, pero desde ahí sí debe poder volver al perfil.
    if (ModalRoute.of(context)?.settings.name == destino) return;

    if (destino == Rutas.feed) {
      // El feed es la base: se vacía la pila por completo
      Navigator.pushNamedAndRemoveUntil(context, Rutas.feed, (r) => false);
    } else {
      // Las otras pestañas se apilan sobre el feed, sin acumular historial:
      // "atrás" siempre regresa al feed
      Navigator.pushNamedAndRemoveUntil(
          context, destino, (r) => r.settings.name == Rutas.feed);
    }
  }

  Widget _navInferior(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: tabActiva,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.azul,
      unselectedItemColor: AppColors.textoGris,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (i) => _irAPestana(context, i),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "Feed"),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: "Alertas"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Perfil"),
      ],
    );
  }
}