// lib/src/features/notificaciones/data/repositories/push_repositorio_impl.dart
import '../../../../core/domain/repositories/push_repositorio.dart';
import '../datasources/push_fuente_fcm.dart';

/// Implementación del contrato. Traduce los datos crudos de cada
/// notificación a lo que le importa a la app: el id de la orden.
///
/// Acuerdo con quien envía las notificaciones (KAN-97 y KAN-95): la orden
/// viaja en el campo data con la clave 'orden_id'.
class PushRepositorioImpl implements PushRepositorio {
  static const claveOrden = 'orden_id';

  final PushFuenteFcm _fuente;

  PushRepositorioImpl(this._fuente);

  @override
  Future<String?> activar() => _fuente.pedirPermisoYToken();

  @override
  Stream<String> get tokenRenovado => _fuente.tokenRenovado;

  @override
  Future<void> desactivar() => _fuente.borrarToken();

  @override
  Future<String?> ordenQueAbrioLaApp() async =>
      _ordenDe(await _fuente.datosMensajeInicial());

  @override
  Stream<String> get ordenesTocadas => _fuente.datosMensajesTocados
      .map(_ordenDe)
      .where((id) => id != null)
      .cast<String>();

  /// Las notificaciones sin orden (por ejemplo, un aviso general) no abren
  /// ninguna pantalla.
  static String? _ordenDe(Map<String, dynamic>? datos) {
    final id = datos?[claveOrden];
    return id is String && id.isNotEmpty ? id : null;
  }
}
