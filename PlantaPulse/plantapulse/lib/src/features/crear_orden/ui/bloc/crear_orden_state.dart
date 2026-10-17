// lib/src/features/crear_orden/ui/bloc/crear_orden_state.dart
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/categoria.dart';
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
  final List<Categoria> categorias;
  final List<Equipo> equipos;
  final List<Usuario> tecnicos;

  // Borrador
  final String descripcion;
  final String categoria;          // el NOMBRE: es lo que guarda la orden
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
    this.categorias = const [],
    this.equipos = const [],
    this.tecnicos = const [],
    this.descripcion = '',
    this.categoria = '',
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

  /// El técnico NO es obligatorio: una orden puede nacer sin asignar.
  bool get paso2Valido => paso1Valido;

  bool get publicando => status == EstadoCrearOrden.publicando;

  CrearOrdenState copyWith({
    EstadoCrearOrden? status,
    String? plantaId,
    List<Categoria>? categorias,
    List<Equipo>? equipos,
    List<Usuario>? tecnicos,
    String? descripcion,
    String? categoria,
    Equipo? equipo,
    Prioridad? prioridad,
    DateTime? fechaLimite,
    Usuario? tecnico,
    String? observaciones,
    String? mensajeError,
    String? ordenIdCreada,
    String? codigoCreado,
    bool limpiarError = false,
    // `?? this.x` no puede volver un campo a null: si el supervisor quita
    // el técnico, sin esta bandera se publicaría con el anterior.
    bool limpiarTecnico = false,
    bool limpiarEquipo = false,
  }) =>
      CrearOrdenState(
        status: status ?? this.status,
        plantaId: plantaId ?? this.plantaId,
        categorias: categorias ?? this.categorias,
        equipos: equipos ?? this.equipos,
        tecnicos: tecnicos ?? this.tecnicos,
        descripcion: descripcion ?? this.descripcion,
        categoria: categoria ?? this.categoria,
        equipo: limpiarEquipo ? null : (equipo ?? this.equipo),
        prioridad: prioridad ?? this.prioridad,
        fechaLimite: fechaLimite ?? this.fechaLimite,
        tecnico: limpiarTecnico ? null : (tecnico ?? this.tecnico),
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
        categorias,
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
