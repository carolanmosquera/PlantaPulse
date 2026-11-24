import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/core.dart';
import '../../domain/usecases/consultar_perfil.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<SesionBloc, AuthState>(
    builder: (context, sesion) {
      final usuario = sesion.usuario;
      if (usuario == null || sesion.sesion != EstadoSesion.activa) {
        return const PantallaBase(
          titulo: 'Mi Perfil',
          conNavegacion: false,
          mostrarAtras: false,
          cuerpo: Center(
            child: Text('Inicia sesión para consultar tu perfil.'),
          ),
        );
      }
      return _PerfilVista(key: ValueKey(usuario.uid), uid: usuario.uid);
    },
  );
}

class _PerfilVista extends StatefulWidget {
  final String uid;
  const _PerfilVista({super.key, required this.uid});

  @override
  State<_PerfilVista> createState() => _PerfilVistaState();
}

class _PerfilVistaState extends State<_PerfilVista> {
  late Future<DatosPerfil> _datos;

  @override
  void initState() {
    super.initState();
    _datos = context.read<ConsultarPerfil>().ejecutar(widget.uid);
  }

  void _recargar() => setState(() {
    _datos = context.read<ConsultarPerfil>().ejecutar(widget.uid);
  });

  @override
  Widget build(BuildContext context) => PantallaBase(
    titulo: 'Mi Perfil',
    mostrarAtras: false,
    tabActiva: 2,
    accionesExtra: [
      IconButton(
        tooltip: 'Actualizar perfil',
        onPressed: _recargar,
        icon: const Icon(Icons.refresh),
      ),
    ],
    cuerpo: FutureBuilder<DatosPerfil>(
      future: _datos,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    FalloApp.mensajeDe(snapshot.error!),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: _recargar,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        final datos = snapshot.data!;
        final usuario = datos.usuario;
        final planta = usuario.plantaId.isEmpty
            ? 'Sin planta asignada'
            : datos.planta?.nombre ?? 'Planta no disponible';
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 46,
                backgroundColor: AppColors.borde.segunTema(context),
                child: Icon(Icons.person, size: 46, color: AppColors.textoGris.segunTema(context)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                usuario.nombre,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppColors.texto.segunTema(context),
                ),
              ),
            ),
            const SeccionHeader(titulo: 'INFORMACIÓN DEL PERFIL'),
            TarjetaBlanca(
              child: Column(
                children: [
                  MetaRow(
                    icono: Icons.badge_outlined,
                    texto: 'Rol',
                    valor: usuario.rol.etiqueta,
                  ),
                  const SizedBox(height: 14),
                  MetaRow(
                    icono: Icons.place_outlined,
                    texto: 'Planta',
                    valor: planta,
                  ),
                  const SizedBox(height: 14),
                  MetaRow(
                    icono: Icons.build_outlined,
                    texto: 'Especialidad',
                    valor: usuario.especialidad.trim().isEmpty
                        ? 'Sin especialidad registrada'
                        : usuario.especialidad,
                  ),
                  if (usuario.email.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    MetaRow(
                      icono: Icons.mail_outline,
                      texto: 'Correo',
                      valor: usuario.email,
                    ),
                  ],
                  if (usuario.turno.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    MetaRow(
                      icono: Icons.schedule,
                      texto: 'Turno',
                      valor: usuario.turno,
                    ),
                  ],
                ],
              ),
            ),
            const SeccionHeader(titulo: 'CONFIGURACIÓN Y GESTIÓN'),
            if (usuario.rol.esAdmin)
              FilaOpcion(
                icono: Icons.how_to_reg_outlined,
                titulo: 'Solicitudes de registro',
                subtitulo: 'Aprobar o rechazar cuentas nuevas',
                color: AppColors.ambar,
                onTap: () => Navigator.pushNamed(context, Rutas.solicitudes),
              ),
            FilaOpcion(
              icono: Icons.settings_outlined,
              titulo: 'Ajustes de Cuenta',
              subtitulo: 'Consultar y guardar tus preferencias',
              onTap: () => Navigator.pushNamed(context, Rutas.ajustes),
            ),
            FilaOpcion(
              icono: Icons.logout,
              titulo: 'CERRAR SESIÓN',
              subtitulo: 'Desconectar del sistema central',
              color: AppColors.rojo,
              onTap: () => _confirmarSalida(context),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    ),
  );

  void _confirmarSalida(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Se desconectará del sistema central.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SesionBloc>().add(const AuthCerrarSesion());
              Navigator.pushNamedAndRemoveUntil(
                context,
                Rutas.login,
                (_) => false,
              );
            },
            child: Text('Salir', style: TextStyle(color: AppColors.rojo.segunTema(context))),
          ),
        ],
      ),
    );
  }
}