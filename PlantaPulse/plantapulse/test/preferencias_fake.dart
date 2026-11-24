import 'dart:async';
import 'package:plantapulse/src/core/core.dart';
import 'package:plantapulse/src/features/perfil/perfil.dart';

class PreferenciasFake implements PreferenciasRepositorio {
  final cuentas = <String, PreferenciasUsuario>{};
  final lecturas = <String>[];
  bool fallaLectura = false;
  bool fallaEscritura = false;
  Completer<void>? pausa;
  int escrituras = 0;

  @override
  Future<PreferenciasUsuario> obtener(String uid) async {
    lecturas.add(uid);
    if (fallaLectura) throw const FalloRed();
    return cuentas[uid] ?? const PreferenciasUsuario();
  }

  @override
  Future<PreferenciasUsuario> cambiar(
    String uid,
    Preferencia campo,
    bool valor,
  ) async {
    escrituras++;
    await pausa?.future;
    if (fallaEscritura) throw const FalloRed();
    return cuentas[uid] = (cuentas[uid] ?? const PreferenciasUsuario()).cambiar(
      campo,
      valor,
    );
  }
}
