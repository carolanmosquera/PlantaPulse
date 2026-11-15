// lib/src/features/crear_orden/ui/bloc/crear_orden_state.dart
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/categoria.dart';
import '../../../../core/domain/entities/equipo.dart';
import '../../../../core/domain/entities/evidencia.dart';
import '../../../../core/domain/entities/foto_pendiente.dart';
import '../../../../core/domain/entities/orden.dart';
import '../../../../core/domain/entities/usuario.dart';

enum EstadoCrearOrden { cargando, listo, publicando, publicada, error }

/// Campos del paso 2 que vinieron del asistente y nadie ha tocado todavía.
enum CampoIa { titulo, descripcion, categoria, prioridad }

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

  // Asistente de IA (KAN-92)
  /// Título de la orden. Vacío = se publica con la nota de P1 como título,
  /// igual que antes de la IA.
  final String titulo;

  /// Descripción técnica propuesta por la IA (o escrita a mano). Se guarda
  /// junto a las observaciones; la nota de P1 no se pisa.
  final String descripcionTecnica;

  /// Esperando al asistente: el botón se deshabilita y muestra progreso.
  final bool estructurando;

  /// El asistente falló. Se sigue igual: P2 se llena a mano.
  final String? errorIa;

  /// La última estructuración salió bien: se guarda generada_por_ia.
  final bool generadaPorIa;

  /// La nota tal como la escribió el supervisor, antes de estructurarla.
  final String? notaOriginal;

  /// Categoría que propuso la IA y NO existe en la planta. No se crea
  /// sola: se muestra y el supervisor decide.
  final String? categoriaSugeridaIa;

  /// Campos que propuso la IA y nadie ha cambiado (para marcarlos).
  final Set<CampoIa> marcasIa;

  /// Fotos del hallazgo (P2, "Evidencia y notas"). Máximo 30.
  final List<FotoPendiente> fotos;

  /// Progreso de la subida: "Subiendo [subiendo] de [totalSubir]".
  final int subiendo;
  final int totalSubir;

  /// Id que la app reservó para la orden y con el que subió las fotos.
  /// Se conserva entre reintentos: las fotos ya subidas están en la
  /// carpeta de ESE id, y la orden no se puede crear con otro.
  final String? ordenIdReservado;

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
    this.titulo = '',
    this.descripcionTecnica = '',
    this.estructurando = false,
    this.errorIa,
    this.generadaPorIa = false,
    this.notaOriginal,
    this.categoriaSugeridaIa,
    this.marcasIa = const {},
    this.fotos = const [],
    this.subiendo = 0,
    this.totalSubir = 0,
    this.ordenIdReservado,
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

  /// El título que llevará la orden: el del paso 2 o, si quedó vacío, la
  /// nota de P1 (como antes de la IA).
  String get tituloFinal =>
      titulo.trim().isNotEmpty ? titulo.trim() : descripcion.trim();

  bool marcadoPorIa(CampoIa campo) => marcasIa.contains(campo);

  bool get puedeAgregarFoto => fotos.length < maxFotosPorReporte && !publicando;

  String? get progresoTexto => publicando && totalSubir > 0
      ? 'Subiendo $subiendo de $totalSubir'
      : null;

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
    String? titulo,
    String? descripcionTecnica,
    bool? estructurando,
    String? errorIa,
    bool? generadaPorIa,
    String? notaOriginal,
    String? categoriaSugeridaIa,
    Set<CampoIa>? marcasIa,
    List<FotoPendiente>? fotos,
    int? subiendo,
    int? totalSubir,
    String? ordenIdReservado,
    String? mensajeError,
    String? ordenIdCreada,
    String? codigoCreado,
    bool limpiarError = false,
    // `?? this.x` no puede volver un campo a null: si el supervisor quita
    // el técnico, sin esta bandera se publicaría con el anterior.
    bool limpiarTecnico = false,
    bool limpiarEquipo = false,
    bool limpiarErrorIa = false,
    bool limpiarNotaOriginal = false,
    bool limpiarCategoriaSugerida = false,
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
        titulo: titulo ?? this.titulo,
        descripcionTecnica: descripcionTecnica ?? this.descripcionTecnica,
        estructurando: estructurando ?? this.estructurando,
        errorIa: limpiarErrorIa ? null : (errorIa ?? this.errorIa),
        generadaPorIa: generadaPorIa ?? this.generadaPorIa,
        notaOriginal:
            limpiarNotaOriginal ? null : (notaOriginal ?? this.notaOriginal),
        categoriaSugeridaIa: limpiarCategoriaSugerida
            ? null
            : (categoriaSugeridaIa ?? this.categoriaSugeridaIa),
        marcasIa: marcasIa ?? this.marcasIa,
        fotos: fotos ?? this.fotos,
        subiendo: subiendo ?? this.subiendo,
        totalSubir: totalSubir ?? this.totalSubir,
        ordenIdReservado: ordenIdReservado ?? this.ordenIdReservado,
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
        titulo,
        descripcionTecnica,
        estructurando,
        errorIa,
        generadaPorIa,
        notaOriginal,
        categoriaSugeridaIa,
        marcasIa,
        fotos,
        subiendo,
        totalSubir,
        ordenIdReservado,
        mensajeError,
        ordenIdCreada,
        codigoCreado,
      ];
}
