// lib/src/features/ordenes/ui/bloc/ordenes_state.dart
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/orden.dart';

enum EstadoOrdenes { inicial, cargando, listo, error }

/// `ordenes` es lo que llegó de Firestore; `visibles` es lo que se pinta.
/// El filtro y la búsqueda se aplican en memoria: Firestore no busca texto
/// dentro de un campo, y los chips no justifican lecturas extra.
class OrdenesState extends Equatable {
  final EstadoOrdenes status;
  final List<Orden> ordenes;
  final int filtro;
  final String busqueda;
  final String? mensajeError;

  const OrdenesState({
    this.status = EstadoOrdenes.inicial,
    this.ordenes = const [],
    this.filtro = 0,
    this.busqueda = '',
    this.mensajeError,
  });

  /// Filtro de chips y luego búsqueda de texto. Se calcula, no se guarda.
  List<Orden> get visibles {
    var lista = ordenes;

    switch (filtro) {
      case 1:
        lista = lista.where((o) => o.estado == EstadoOrden.pendiente).toList();
      case 2:
        lista = lista.where((o) => o.estado == EstadoOrden.enProgreso).toList();
      case 3:
        lista = lista.where((o) => o.prioridad == Prioridad.critica).toList();
    }

    final texto = busqueda.trim().toLowerCase();
    if (texto.isNotEmpty) {
      lista = lista.where((o) =>
          o.titulo.toLowerCase().contains(texto) ||
          o.codigo.toLowerCase().contains(texto) ||
          o.ubicacion.toLowerCase().contains(texto)).toList();
    }

    return lista;
  }

  /// "Todavía no hay órdenes en la planta".
  bool get vacioTotal => status == EstadoOrdenes.listo && ordenes.isEmpty;

  /// "Hay órdenes, pero el filtro o la búsqueda no encontró ninguna".
  bool get sinResultados =>
      status == EstadoOrdenes.listo && ordenes.isNotEmpty && visibles.isEmpty;

  OrdenesState copyWith({
    EstadoOrdenes? status,
    List<Orden>? ordenes,
    int? filtro,
    String? busqueda,
    String? mensajeError,
    bool limpiarError = false,
  }) =>
      OrdenesState(
        status: status ?? this.status,
        ordenes: ordenes ?? this.ordenes,
        filtro: filtro ?? this.filtro,
        busqueda: busqueda ?? this.busqueda,
        mensajeError: limpiarError ? null : (mensajeError ?? this.mensajeError),
      );

  @override
  List<Object?> get props => [status, ordenes, filtro, busqueda, mensajeError];
}
