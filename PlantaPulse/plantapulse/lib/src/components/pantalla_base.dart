// lib/src/components/pantalla_base.dart
import 'package:flutter/material.dart';
import 'package:plantapulse/src/theme/app_colors.dart';

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
                _navInferior(),
              ],
            )
          : barraInferiorFija,
    );
  }

  Widget _navInferior() {
    return BottomNavigationBar(
      currentIndex: tabActiva,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.azul,
      unselectedItemColor: AppColors.textoGris,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (i) {},
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "Feed"),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: "Alertas"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Perfil"),
      ],
    );
  }
}