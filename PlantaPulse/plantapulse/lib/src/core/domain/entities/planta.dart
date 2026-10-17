// lib/src/core/domain/entities/planta.dart

class Planta {
  final String id;
  final String nombre;      // "Planta Norte"
  final String ubicacion;   // ciudad o dirección
  final bool activo;

  const Planta({
    required this.id,
    required this.nombre,
    this.ubicacion = '',
    this.activo = true,
  });

}

class Zona {
  final String id;
  final String plantaId;
  final String nombre;      // "Sector de Empaque"
  final String codigo;      // "ZN-04"
  final String descripcion;
  final bool activo;        // se da de baja, no se borra

  const Zona({
    required this.id,
    required this.plantaId,
    required this.nombre,
    this.codigo = '',
    this.descripcion = '',
    this.activo = true,
  });

}