// lib/src/models/borrador_orden.dart
import 'orden.dart';

class BorradorOrden {
  String descripcion = '';
  CategoriaOrden categoria = CategoriaOrden.mecanico;
  String? equipoNombre;
  String? equipoCodigo;
  String prioridad = 'MEDIA';
  DateTime? fecha;
  List<String> fotos = [];
  String observaciones = '';
}