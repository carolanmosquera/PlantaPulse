// lib/src/screens/perfil_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/rutas.dart';
import '../components/widgets.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: 'Mi Perfil',
      mostrarAtras: false,
      mostrarMenu: true,
      tabActiva: 2,
      cuerpo: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 20),

          // ══ AVATAR ══
          Center(
            child: Stack(
              children: [
                const CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.borde,
                  child: Icon(Icons.person, size: 46,
                              color: AppColors.textoGris),
                ),
                Positioned(
                  right: 2, bottom: 2,
                  child: Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.verde,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.fondo, width: 2.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Center(child: Text('Ing. Carlos Mendoza',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold,
                             color: AppColors.texto))),
          const SizedBox(height: 6),
          const Center(child: MetaRow(icono: Icons.badge_outlined,
            texto: 'Supervisor de Mantenimiento')),
          const SizedBox(height: 3),
          const Center(child: MetaRow(icono: Icons.place_outlined,
            texto: 'Planta Norte • Sector 04')),
          const SizedBox(height: 10),
          const Center(child: PillEstado(texto: 'ID: EMP-9420-B',
            color: AppColors.azul)),
          const SizedBox(height: 22),

          // ══ MÉTRICAS 2×2 ══
          const Row(children: [
            Expanded(child: StatCard(icono: Icons.check_circle_outline,
              valor: '142', etiqueta: 'ÓRDENES COMPLETADAS',
              nota: '+12% este mes')),
            SizedBox(width: 12),
            Expanded(child: StatCard(icono: Icons.schedule,
              valor: '45m', etiqueta: 'TIEMPO DE RESPUESTA',
              nota: 'Óptimo')),
          ]),
          const SizedBox(height: 12),
          const Row(children: [
            Expanded(child: StatCard(icono: Icons.shield_outlined,
              valor: '100%', etiqueta: 'ÍNDICE DE SEGURIDAD',
              nota: 'Sin incidencias', color: AppColors.verde)),
            SizedBox(width: 12),
            Expanded(child: StatCard(icono: Icons.trending_up,
              valor: '98.2%', etiqueta: 'EFICIENCIA',
              nota: 'Top Supervisor', color: AppColors.verde)),
          ]),

          // ══ CONTACTO ══
          const SeccionHeader(titulo: 'INFORMACIÓN DE CONTACTO'),
          TarjetaBlanca(
            child: Column(children: const [
              MetaRow(icono: Icons.mail_outline, texto: 'Correo Corporativo',
                valor: 'c.mendoza@plantapulse.com'),
              SizedBox(height: 14),
              MetaRow(icono: Icons.business_outlined, texto: 'Departamento',
                valor: 'Mantenimiento Industrial'),
              SizedBox(height: 14),
              MetaRow(icono: Icons.schedule, texto: 'Turno Actual',
                valor: 'Matutino (06:00 - 14:00)'),
            ]),
          ),

          // ══ CONFIGURACIÓN ══
          const SeccionHeader(titulo: 'CONFIGURACIÓN Y GESTIÓN'),
          FilaOpcion(
            icono: Icons.settings_outlined,
            titulo: 'Ajustes de Cuenta',
            subtitulo: 'Privacidad, seguridad y notificaciones',
            onTap: () => Navigator.pushNamed(context, Rutas.ajustes),
          ),
          const SizedBox(height: 10),
          FilaOpcion(
            icono: Icons.history,
            titulo: 'Historial de Actividad',
            subtitulo: 'Registros de intervenciones y cierres',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          FilaOpcion(
            icono: Icons.description_outlined,
            titulo: 'Certificaciones',
            subtitulo: 'Capacitaciones técnicas activas',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          FilaOpcion(
            icono: Icons.logout,
            titulo: 'CERRAR SESIÓN',
            subtitulo: 'Desconectar del sistema central',
            color: AppColors.rojo,
            onTap: () => _confirmarSalida(context),
          ),

          const SizedBox(height: 22),
          const Center(child: Text('Versión del Sistema: 2.4.0-build.82',
            style: TextStyle(fontSize: 10, color: AppColors.textoGris))),
          const Center(child: Text('© 2024 PlantaPulse Industrial',
            style: TextStyle(fontSize: 10, color: AppColors.textoGris))),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _confirmarSalida(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Se desconectará del sistema central.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);                      // cierra el diálogo
              Navigator.pushNamedAndRemoveUntil(       // vacía la pila
                context, Rutas.login, (r) => false);
            },
            child: const Text('Salir',
              style: TextStyle(color: AppColors.rojo)),
          ),
        ],
      ),
    );
  }
}