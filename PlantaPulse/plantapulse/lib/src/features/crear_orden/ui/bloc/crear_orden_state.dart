// lib/src/features/crear_orden/ui/bloc/crear_orden_state.dart
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/equipo.dart';
import '../../../../core/domain/entities/orden.dart';
import '../../../../core/domain/entities/usuario.dart';

enum EstadoCrearOrden { cargando, listo, publicando, publicada, error }

/// El borrador de la orden mientras el supervisor recorre P1 y P2,
/// más los catálogos que alimentan los selectores.
class CrearOrdenState extends Equatable {
  final EstadoCrearOrden status;
  final String plantaId;

  // Catálogos
  final List<Equipo> equipos;
  final List<Usuario> tecnicos;

  // Borrador
  final String descripcion;
  final CategoriaOrden categoria;
  final Equipo? equipo;
  final Prioridad prioridad;
  final DateTime fechaLimite;
  final Usuario? tecnico;
  final String observaciones;

  // Resultado
  final String? mensajeError;
  final String? ordenIdCreada;
  final String? codigoCreado;   // para el SnackBar de confirmación

  const CrearOrdenState({
    this.status = EstadoCrearOrden.cargando,
    this.plantaId = '',
    this.equipos = const [],
    this.tecnicos = const [],
    this.descripcion = '',
    this.categoria = CategoriaOrden.mecanico,
    this.equipo,
    this.prioridad = Prioridad.media,
    required this.fechaLimite,
    this.tecnico,
    this.observaciones = '',
    this.mensajeError,
    this.ordenIdCreada,
    this.codigoCreado,
  });

  /// Por defecto la orden vence mañana.
  factory CrearOrdenState.inicial() => CrearOrdenState(
        fechaLimite: DateTime.now().add(const Duration(days: 1)),
      );

  bool get paso1Valido => descripcion.trim().length >= 10 && equipo != null;

  bool get paso2Valido => paso1Valido && tecnico != null;

  bool get publicando => status == EstadoCrearOrden.publicando;

  CrearOrdenState copyWith({
    EstadoCrearOrden? status,
    String? plantaId,
    List<Equipo>? equipos,
    List<Usuario>? tecnicos,
    String? descripcion,
    CategoriaOrden? categoria,
    Equipo? equipo,
    Prioridad? prioridad,
    DateTime? fechaLimite,
    Usuario? tecnico,
    String? observaciones,
    String? mensajeError,
    String? ordenIdCreada,
    String? codigoCreado,
    bool limpiarError = false,
  }) =>
      CrearOrdenState(
        status: status ?? this.status,
        plantaId: plantaId ?? this.plantaId,
        equipos: equipos ?? this.equipos,
        tecnicos: tecnicos ?? this.tecnicos,
        descripcion: descripcion ?? this.descripcion,
        categoria: categoria ?? this.categoria,
        equipo: equipo ?? this.equipo,
        prioridad: prioridad ?? this.prioridad,
        fechaLimite: fechaLimite ?? this.fechaLimite,
        tecnico: tecnico ?? this.tecnico,
        observaciones: observaciones ?? this.observaciones,
        mensajeError: limpiarError ? null : (mensajeError ?? this.mensajeError),
        ordenIdCreada: ordenIdCreada ?? this.ordenIdCreada,
        codigoCreado: codigoCreado ?? this.codigoCreado,
      );

  // Equipo y Usuario no implementan ==: se comparan por id
  @override
  List<Object?> get props => [
        status,
        plantaId,
        equipos,
        tecnicos,
        descripcion,
        categoria,
        equipo?.id,
        prioridad,
        fechaLimite,
        tecnico?.uid,
        observaciones,
        mensajeError,
        ordenIdCreada,
        codigoCreado,
      ];
}
