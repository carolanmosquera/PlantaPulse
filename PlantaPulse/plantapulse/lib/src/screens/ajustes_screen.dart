// lib/src/screens/ajustes_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/rutas.dart';
import '../components/widgets.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});
  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  bool _push = true;
  bool _mantenimiento = true;
  bool _soloCriticas = false;
  bool _modoOscuro = false;
  bool _modoOffline = false;

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: 'Ajustes de PlantaPulse',
      tabActiva: 2,
      cuerpo: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 12),
          const TarjetaOscura(
            icono: CircleAvatar(radius: 22, backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white)),
            etiqueta: 'PRO',
            titulo: 'Ing. Carlos Méndez',
            subtitulo: 'Supervisor de Planta • ID: #44892',
          ),

          const SeccionHeader(titulo: 'NOTIFICACIONES'),
          _switch(Icons.notifications_none, 'Notificaciones Push',
            'Recibir alertas generales en el dispositivo',
            _push, (v) => setState(() => _push = v)),
          const SizedBox(height: 10),
          _switch(Icons.build_outlined, 'Alertas de Mantenimiento',
            'Estatus de órdenes de trabajo',
            _mantenimiento, (v) => setState(() => _mantenimiento = v)),
          const SizedBox(height: 10),
          _switch(Icons.warning_amber_rounded, 'Solo Críticas',
            'Filtrar alertas por prioridad alta/urgente',
            _soloCriticas, (v) => setState(() => _soloCriticas = v)),

          const SeccionHeader(titulo: 'PREFERENCIAS TÉCNICAS'),
          _switch(Icons.dark_mode_outlined, 'Modo Oscuro',
            'Ahorro de batería y confort visual',
            _modoOscuro, (v) => setState(() => _modoOscuro = v)),
          const SizedBox(height: 10),
          _switch(Icons.storage_outlined, 'Modo Offline',
            'Sincronizar datos al recuperar conexión',
            _modoOffline, (v) => setState(() => _modoOffline = v)),
          const SizedBox(height: 10),
          FilaOpcion(
            icono: Icons.translate,
            titulo: 'Idioma de Interfaz',
            subtitulo: 'Español (Latinoamérica)',
            onTap: () {},
          ),

          const SeccionHeader(titulo: 'CUENTA Y SEGURIDAD'),
          FilaOpcion(icono: Icons.person_outline, titulo: 'Editar Perfil',
            subtitulo: 'Nombre, cargo y firma digital', onTap: () {}),
          const SizedBox(height: 10),
          FilaOpcion(icono: Icons.shield_outlined,
            titulo: 'Privacidad y Seguridad',
            subtitulo: 'Cambiar contraseña y 2FA', onTap: () {}),
          const SizedBox(height: 10),
          FilaOpcion(icono: Icons.phone_android,
            titulo: 'Dispositivos Vinculados',
            subtitulo: 'Gestionar terminales de mano y tablets',
            onTap: () {}),

          const SeccionHeader(titulo: 'SOPORTE'),
          FilaOpcion(icono: Icons.help_outline, titulo: 'Centro de Ayuda',
            subtitulo: 'Guías de mantenimiento preventivo', onTap: () {}),

          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Versión del Sistema',
                    style: TextStyle(fontSize: 12.5, color: AppColors.texto)),
                  Text('v3.4.1-build.920',
                    style: TextStyle(fontSize: 11,
                                     color: AppColors.textoGris)),
                ],
              ),
              const PillEstado(texto: 'Actualizado', color: AppColors.verde),
            ],
          ),

          const SizedBox(height: 20),
          BotonAncho(
            texto: 'CERRAR SESIÓN',
            icono: Icons.logout,
            estilo: EstiloBoton.peligro,
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context, Rutas.login, (r) => false),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _switch(IconData icono, String titulo, String subtitulo,
                 bool valor, ValueChanged<bool> onCambio) {
    return FilaOpcion(
      icono: icono,
      titulo: titulo,
      subtitulo: subtitulo,
      trailing: Switch(
        value: valor,
        activeColor: AppColors.azul,
        onChanged: onCambio,
      ),
    );
  }
}