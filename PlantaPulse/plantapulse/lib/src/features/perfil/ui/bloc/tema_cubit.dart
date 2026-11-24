import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/preferencias_casos.dart';

/// Estado visual global; la persistencia sigue perteneciendo a Ajustes.
class TemaCubit extends Cubit<bool> {
  final ObtenerPreferencias obtener;
  String? _uid;
  int _revision = 0;

  TemaCubit(this.obtener) : super(false);

  Future<void> cambiarCuenta(String? uid) async {
    if (_uid == uid) return;
    _uid = uid;
    final revision = ++_revision;
    emit(false);
    if (uid == null) return;
    try {
      final preferencias = await obtener.ejecutar(uid);
      if (!isClosed && revision == _revision) emit(preferencias.modoOscuro);
    } catch (_) {
      // Un fallo de red no impide entrar en la app. Ajustes permite reintentar
      // y muestra el error; aquí no se escribe ningún valor predeterminado.
    }
  }

  /// También recibe la restauración de Ajustes cuando falla un guardado.
  void aplicar(String uid, bool oscuro) {
    if (isClosed || uid != _uid) return;
    ++_revision; // Una lectura anterior no puede deshacer un cambio reciente.
    emit(oscuro);
  }
}
