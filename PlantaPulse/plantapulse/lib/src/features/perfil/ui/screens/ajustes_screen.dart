import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../../domain/entities/preferencias_usuario.dart';
import '../../domain/usecases/preferencias_casos.dart';
import '../bloc/ajustes_bloc.dart';
import '../bloc/tema_cubit.dart';

class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<SesionBloc, AuthState>(
    builder: (context, sesion) {
      final usuario = sesion.usuario;
      if (usuario == null || sesion.sesion != EstadoSesion.activa) {
        return const PantallaBase(
          titulo: 'Ajustes de PlantaPulse',
          conNavegacion: false,
          mostrarAtras: false,
          cuerpo: Center(
            child: Text('Inicia sesión para consultar tus ajustes.'),
          ),
        );
      }
      return BlocProvider(
        key: ValueKey(usuario.uid),
        create: (context) => AjustesBloc(
          uid: usuario.uid,
          obtener: context.read<ObtenerPreferencias>(),
          cambiar: context.read<CambiarPreferencia>(),
        )..add(const AjustesCargados()),
        child: _AjustesVista(usuario: usuario),
      );
    },
  );
}

class _AjustesVista extends StatelessWidget {
  final Usuario usuario;
  const _AjustesVista({required this.usuario});

  @override
  Widget build(BuildContext context) => BlocListener<AjustesBloc, AjustesState>(
    listener: (context, state) {
      final preferencias = state.preferencias;
      if (preferencias != null) {
        context.read<TemaCubit>().aplicar(usuario.uid, preferencias.modoOscuro);
      }
    },
    child: BlocConsumer<AjustesBloc, AjustesState>(
      listenWhen: (antes, ahora) =>
          antes.guardando && ahora.estado == EstadoAjustes.listo,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error ?? 'Preferencia guardada'),
          backgroundColor: state.error == null
              ? AppColors.verde
              : AppColors.rojo,
        ),
      ),
      builder: (context, state) => PopScope(
        canPop: !state.guardando,
        child: ExcludeFocus(
          excluding: state.guardando,
          child: AbsorbPointer(
            absorbing: state.guardando,
            child: PantallaBase(
              titulo: 'Ajustes de PlantaPulse',
              tabActiva: 2,
              cuerpo: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 12),
                  TarjetaOscura(
                    icono: const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    titulo: usuario.nombre,
                    subtitulo: usuario.rol.etiqueta,
                  ),
                  if (state.estado == EstadoAjustes.inicial ||
                      state.estado == EstadoAjustes.cargando)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (state.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.error!,
                      style: TextStyle(
                        color: AppColors.rojo.segunTema(context),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.read<AjustesBloc>().add(
                        const AjustesCargados(),
                      ),
                      child: const Text('Volver a cargar'),
                    ),
                  ],
                  if (state.preferencias != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.guardando
                          ? 'Guardando…'
                          : 'Tus preferencias se guardan en tu cuenta.',
                      style: AppText.gris.segunTema(context),
                      semanticsLabel: state.guardando
                          ? 'Guardando preferencias'
                          : null,
                    ),
                    if (state.guardando) const LinearProgressIndicator(),
                    const SeccionHeader(titulo: 'NOTIFICACIONES'),
                    _interruptor(
                      context,
                      state,
                      Preferencia.notificacionesPush,
                      Icons.notifications_none,
                      'Notificaciones Push',
                      'Recibir alertas generales en el dispositivo',
                    ),
                    _interruptor(
                      context,
                      state,
                      Preferencia.alertasMantenimiento,
                      Icons.build_outlined,
                      'Alertas de Mantenimiento',
                      'Estatus de órdenes de trabajo',
                    ),
                    _interruptor(
                      context,
                      state,
                      Preferencia.soloCriticas,
                      Icons.warning_amber_rounded,
                      'Solo Críticas',
                      'Filtrar alertas por prioridad alta/urgente',
                    ),
                    const SeccionHeader(titulo: 'PREFERENCIAS TÉCNICAS'),
                    _interruptor(
                      context,
                      state,
                      Preferencia.modoOscuro,
                      Icons.dark_mode_outlined,
                      'Modo Oscuro',
                      'Usar colores oscuros en toda la aplicación',
                    ),
                    _interruptor(
                      context,
                      state,
                      Preferencia.modoOffline,
                      Icons.storage_outlined,
                      'Modo Offline',
                      'Preferencia de trabajo sin conexión',
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'El modo oscuro cambia la apariencia de la aplicación. '
                        'Las notificaciones se administran desde tu perfil. '
                        'El modo offline guarda tu preferencia; la sincronización '
                        'sin conexión estará disponible en una próxima versión.',
                        style: AppText.gris.segunTema(context),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  BotonAncho(
                    texto: 'CERRAR SESIÓN',
                    icono: Icons.logout,
                    estilo: EstiloBoton.peligro,
                    onTap: () {
                      context.read<SesionBloc>().add(const AuthCerrarSesion());
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        Rutas.login,
                        (_) => false,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _interruptor(
    BuildContext context,
    AjustesState state,
    Preferencia campo,
    IconData icono,
    String titulo,
    String subtitulo,
  ) => FilaOpcion(
    icono: icono,
    titulo: titulo,
    subtitulo: subtitulo,
    trailing: Switch(
      key: switch (campo) {
        Preferencia.notificacionesPush => const Key('switch-push'),
        Preferencia.alertasMantenimiento => const Key('switch-mantenimiento'),
        Preferencia.soloCriticas => const Key('switch-criticas'),
        _ => ValueKey(campo),
      },
      value: state.preferencias!.valor(campo),
      activeThumbColor: AppColors.azul.segunTema(context),
      onChanged: state.guardando
          ? null
          : (valor) => context.read<AjustesBloc>().add(
              PreferenciaCambiada(campo, valor),
            ),
    ),
  );
}
