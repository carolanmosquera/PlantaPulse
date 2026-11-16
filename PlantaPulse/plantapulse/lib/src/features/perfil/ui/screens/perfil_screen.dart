
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/core.dart';
import '../../domain/usecases/consultar_perfil.dart';
import '../../domain/usecases/actualizar_perfil.dart';
import '../../domain/usecases/subir_foto_perfil.dart';

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

      return _PerfilVista(
        key: ValueKey(usuario.uid),
        uid: usuario.uid,
      );
    },
  );
}

class _PerfilVista extends StatefulWidget {
  final String uid;

  const _PerfilVista({
    super.key,
    required this.uid,
  });

  @override
  State<_PerfilVista> createState() => _PerfilVistaState();
}

class _PerfilVistaState extends State<_PerfilVista> {
  late Future<DatosPerfil> _datos;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _datos = context.read<ConsultarPerfil>().ejecutar(widget.uid);
  }

  void _recargar() {
    setState(() {
      _datos = context.read<ConsultarPerfil>().ejecutar(widget.uid);
    });
  }

  Future<void> _editarPerfil(Usuario usuario) async {
    final formulario = GlobalKey<FormState>();

    String nombre = usuario.nombre;
    String especialidad = usuario.especialidad;
    FotoElegida? nuevaFoto;
    bool eligiendoFoto = false;

    final cambios = await showDialog<_CambiosPerfil>(
      context: context,
      barrierDismissible: false,
      builder: (dialogo) => StatefulBuilder(
        builder: (dialogo, actualizar) => AlertDialog(
          title: const Text('Editar mi perfil'),
          content: SingleChildScrollView(
            child: Form(
              key: formulario,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: nuevaFoto != null
                        ? MemoryImage(nuevaFoto!.bytes)
                        : (usuario.fotoUrl?.trim().isNotEmpty ?? false)
                            ? NetworkImage(usuario.fotoUrl!)
                            : null,
                    child: nuevaFoto == null &&
                            (usuario.fotoUrl?.trim().isEmpty ?? true)
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),

                  TextButton.icon(
                    onPressed: eligiendoFoto
                        ? null
                        : () async {
                            final origen = await elegirOrigenFoto(
                              dialogo,
                              camara: OrigenFoto.camara,
                              galeria: OrigenFoto.galeria,
                            );

                            if (!dialogo.mounted || origen == null) return;

                            actualizar(() => eligiendoFoto = true);

                            try {
                              final foto = await context
                                  .read<ObtenerFoto>()
                                  .ejecutar(origen);

                              if (!dialogo.mounted) return;

                              if (foto != null) {
                                actualizar(() => nuevaFoto = foto);
                              }
                            } catch (error) {
                              if (!dialogo.mounted) return;

                              ScaffoldMessenger.of(dialogo).showSnackBar(
                                SnackBar(
                                  content: Text(FalloApp.mensajeDe(error)),
                                ),
                              );
                            } finally {
                              if (dialogo.mounted) {
                                actualizar(() => eligiendoFoto = false);
                              }
                            }
                          },
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(
                      eligiendoFoto ? 'Abriendo fotos...' : 'Cambiar foto',
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    initialValue: usuario.nombre,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                    ),
                    onChanged: (valor) => nombre = valor,
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'Ingresa tu nombre';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    initialValue: usuario.especialidad,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Especialidad',
                    ),
                    onChanged: (valor) => especialidad = valor,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'El rol y la planta no se pueden modificar aquí.',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: eligiendoFoto
                  ? null
                  : () => Navigator.pop(dialogo),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: eligiendoFoto
                  ? null
                  : () {
                      if (!formulario.currentState!.validate()) return;

                      Navigator.pop(
                        dialogo,
                        _CambiosPerfil(
                          nombre: nombre.trim(),
                          especialidad: especialidad.trim(),
                          foto: nuevaFoto,
                        ),
                      );
                    },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (cambios == null || !mounted) return;

    final modificaciones = <String, dynamic>{};

    if (cambios.nombre != usuario.nombre) {
      modificaciones['nombre'] = cambios.nombre;
    }

    if (cambios.especialidad != usuario.especialidad) {
      modificaciones['especialidad'] = cambios.especialidad;
    }

    if (modificaciones.isEmpty && cambios.foto == null) return;

    setState(() => _guardando = true);

    try {
      if (cambios.foto != null) {
        final url = await context.read<SubirFotoPerfil>().ejecutar(
          uid: widget.uid,
          foto: cambios.foto!,
        );

        modificaciones['fotoUrl'] = url;
      }

      await context.read<ActualizarPerfil>().ejecutar(
        widget.uid,
        modificaciones,
      );

      if (!mounted) return;

      _recargar();

      context.read<SesionBloc>().add(
        const AuthRecargarPerfil(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(FalloApp.mensajeDe(error)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

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
          return const Center(
            child: CircularProgressIndicator(),
          );
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
                backgroundImage:
                    usuario.fotoUrl?.trim().isNotEmpty ?? false
                        ? NetworkImage(usuario.fotoUrl!)
                        : null,
                child: usuario.fotoUrl?.trim().isEmpty ?? true
                    ? Icon(
                        Icons.person,
                        size: 46,
                        color: AppColors.textoGris.segunTema(context),
                      )
                    : null,
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

            const SizedBox(height: 12),

            Center(
              child: OutlinedButton.icon(
                onPressed: _guardando
                    ? null
                    : () => _editarPerfil(usuario),
                icon: const Icon(Icons.edit_outlined),
                label: Text(
                  _guardando ? 'Guardando...' : 'Editar mi perfil',
                ),
              ),
            ),

            if (_guardando)
              const LinearProgressIndicator(),

            const SeccionHeader(
              titulo: 'INFORMACIÓN DEL PERFIL',
            ),

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

            const SeccionHeader(
              titulo: 'CONFIGURACIÓN Y GESTIÓN',
            ),

            if (usuario.rol.esAdmin)
              FilaOpcion(
                icono: Icons.how_to_reg_outlined,
                titulo: 'Solicitudes de registro',
                subtitulo: 'Aprobar o rechazar cuentas nuevas',
                color: AppColors.ambar,
                onTap: () => Navigator.pushNamed(
                  context,
                  Rutas.solicitudes,
                ),
              ),

            FilaOpcion(
              icono: Icons.settings_outlined,
              titulo: 'Ajustes de Cuenta',
              subtitulo: 'Consultar y guardar tus preferencias',
              onTap: () => Navigator.pushNamed(
                context,
                Rutas.ajustes,
              ),
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
        content: const Text(
          'Se desconectará del sistema central.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);

              context.read<SesionBloc>().add(
                const AuthCerrarSesion(),
              );

              Navigator.pushNamedAndRemoveUntil(
                context,
                Rutas.login,
                (_) => false,
              );
            },
            child: Text(
              'Salir',
              style: TextStyle(
                color: AppColors.rojo.segunTema(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CambiosPerfil {
  final String nombre;
  final String especialidad;
  final FotoElegida? foto;

  const _CambiosPerfil({
    required this.nombre,
    required this.especialidad,
    required this.foto,
  });
}
