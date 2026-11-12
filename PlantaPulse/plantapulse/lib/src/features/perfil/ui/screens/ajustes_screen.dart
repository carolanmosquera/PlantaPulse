// lib/src/features/perfil/ui/screens/ajustes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../../../notificaciones/notificaciones.dart';
import '../../domain/usecases/actualizar_perfil.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});
  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  // Avisos (KAN-100): se guardan en el perfil, no en la pantalla.
  PreferenciasAvisos _avisos = const PreferenciasAvisos();
  bool _guardando = false;

  bool _modoOscuro = false;
  bool _modoOffline = false;

  @override
  void initState() {
    super.initState();
    // Se muestra al instante lo que trajo la sesión y enseguida se lee el
    // perfil guardado: así, al volver a abrir la app o esta pantalla, el
    // interruptor refleja lo último que el usuario eligió.
    _avisos = context.read<SesionBloc>().state.usuario?.preferenciasAvisos ??
        const PreferenciasAvisos();
    _cargarGuardadas();
  }

  Future<void> _cargarGuardadas() async {
    final uid = context.read<SesionBloc>().state.usuario?.uid;
    if (uid == null) return;
    try {
      final perfil = await context.read<UsuarioRepositorio>().obtener(uid);
      if (!mounted || perfil == null || _guardando) return;
      setState(() => _avisos = perfil.preferenciasAvisos);
    } catch (_) {
      // Sin red: se queda lo que trajo la sesión
    }
  }

  /// Aplica el cambio al instante y lo guarda en el perfil. Si no se
  /// puede guardar, el interruptor vuelve a su valor anterior.
  Future<void> _cambiar(PreferenciasAvisos nuevas) async {
    final uid = context.read<SesionBloc>().state.usuario?.uid;
    if (uid == null) return;
    final anteriores = _avisos;
    final mensajes = ScaffoldMessenger.of(context);
    final actualizar = context.read<ActualizarPerfil>();
    final push = context.read<SincronizarTokenPush>();

    setState(() {
      _avisos = nuevas;
      _guardando = true;
    });
    try {
      await actualizar.ejecutar(uid, {'preferenciasAvisos': nuevas.toJson()});
      // Push apagado: el token sale del perfil y el teléfono deja de
      // recibir avisos. Al encenderlo, se registra de nuevo.
      if (nuevas.push != anteriores.push) {
        if (nuevas.push) {
          await push.iniciar(uid);
        } else {
          await push.detener();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _avisos = anteriores);
      mensajes.showSnackBar(SnackBar(
          content: Text(
              'No se pudo guardar tu preferencia. ${FalloApp.mensajeDe(e)}')));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<SesionBloc>().state.usuario;
    return PantallaBase(
      titulo: 'Ajustes de PlantaPulse',
      tabActiva: 2,
      cuerpo: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 12),
          TarjetaOscura(
            icono: const CircleAvatar(radius: 22, backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white)),
            etiqueta: 'PRO',
            titulo: usuario?.nombre ?? 'Mi cuenta',
            subtitulo: usuario?.rol.etiqueta ?? '',
          ),

          const SeccionHeader(titulo: 'NOTIFICACIONES'),
          _switch(Icons.notifications_none, 'Notificaciones Push',
            'Recibir alertas generales en el dispositivo',
            _avisos.push, (v) => _cambiar(_avisos.copyWith(push: v)),
            clave: 'switch-push'),
          const SizedBox(height: 10),
          _switch(Icons.build_outlined, 'Alertas de Mantenimiento',
            'Estatus de órdenes de trabajo',
            _avisos.mantenimiento,
            (v) => _cambiar(_avisos.copyWith(mantenimiento: v)),
            clave: 'switch-mantenimiento'),
          const SizedBox(height: 10),
          _switch(Icons.warning_amber_rounded, 'Solo Críticas',
            'Filtrar alertas por prioridad alta/urgente',
            _avisos.soloCriticas,
            (v) => _cambiar(_avisos.copyWith(soloCriticas: v)),
            clave: 'switch-criticas'),

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
            onTap: () {
              // Cierra la sesión en Supabase y vacía la pila
              context.read<SesionBloc>().add(const AuthCerrarSesion());
              Navigator.pushNamedAndRemoveUntil(
                context, Rutas.login, (r) => false);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _switch(IconData icono, String titulo, String subtitulo,
                 bool valor, ValueChanged<bool> onCambio, {String? clave}) {
    return FilaOpcion(
      icono: icono,
      titulo: titulo,
      subtitulo: subtitulo,
      trailing: Switch(
        key: clave == null ? null : Key(clave),
        value: valor,
        activeColor: AppColors.azul,
        onChanged: onCambio,
      ),
    );
  }
}