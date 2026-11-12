import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantapulse/src/features/perfil/perfil.dart';
import 'package:plantapulse/src/features/perfil/ui/bloc/tema_cubit.dart';
import 'preferencias_fake.dart';

class LecturaDemorada extends PreferenciasFake {
  final pendientes = <String, Completer<PreferenciasUsuario>>{};
  @override
  Future<PreferenciasUsuario> obtener(String uid) =>
      (pendientes[uid] = Completer<PreferenciasUsuario>()).future;
}

void main() {
  TemaCubit crear(PreferenciasRepositorio repo) {
    final cubit = TemaCubit(ObtenerPreferencias(repo));
    addTearDown(cubit.close);
    return cubit;
  }

  test('restaura el tema por cuenta y lo limpia al cerrar sesión', () async {
    final repo = PreferenciasFake();
    repo.cuentas['a'] = const PreferenciasUsuario(modoOscuro: true);
    final cubit = crear(repo);
    await cubit.cambiarCuenta('a');
    expect(cubit.state, isTrue);
    await cubit.cambiarCuenta(null);
    expect(cubit.state, isFalse);
    await cubit.cambiarCuenta('b');
    expect(cubit.state, isFalse);
    cubit.aplicar('a', true);
    expect(cubit.state, isFalse);
    await cubit.cambiarCuenta('a');
    expect(cubit.state, isTrue);
    expect(repo.escrituras, 0);
  });

  test(
    'una respuesta tardía no aplica el tema de una cuenta anterior',
    () async {
      final repo = LecturaDemorada();
      final cubit = crear(repo);
      final a = cubit.cambiarCuenta('a');
      final b = cubit.cambiarCuenta('b');
      repo.pendientes['b']!.complete(const PreferenciasUsuario());
      await b;
      repo.pendientes['a']!.complete(
        const PreferenciasUsuario(modoOscuro: true),
      );
      await a;
      expect(cubit.state, isFalse);
    },
  );

  test(
    'la carga inicial no deshace la selección reciente de Ajustes',
    () async {
      final repo = LecturaDemorada();
      final cubit = crear(repo);
      final carga = cubit.cambiarCuenta('a');
      cubit.aplicar('a', true);
      repo.pendientes['a']!.complete(const PreferenciasUsuario());
      await carga;
      expect(cubit.state, isTrue);
      cubit.aplicar('a', false); // Restauración al fallar un guardado.
      expect(cubit.state, isFalse);
    },
  );

  test(
    'un fallo de lectura permite entrar y no sobrescribe la preferencia',
    () async {
      final repo = PreferenciasFake()..fallaLectura = true;
      final cubit = crear(repo);
      await cubit.cambiarCuenta('a');
      expect(cubit.state, isFalse);
      expect(repo.escrituras, 0);
      cubit.aplicar('a', true); // Reintento exitoso desde Ajustes.
      expect(cubit.state, isTrue);
    },
  );
}
