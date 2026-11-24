import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantapulse/src/features/perfil/perfil.dart';
import 'package:plantapulse/src/features/perfil/ui/bloc/ajustes_bloc.dart';
import 'preferencias_fake.dart';

void main() {
  late PreferenciasFake repo;
  AjustesBloc crear([String uid = 'a']) {
    final bloc = AjustesBloc(
      uid: uid,
      obtener: ObtenerPreferencias(repo),
      cambiar: CambiarPreferencia(repo),
    );
    addTearDown(bloc.close);
    return bloc;
  }

  Future<void> cargar(AjustesBloc bloc) async {
    final listo = bloc.stream.firstWhere(
      (s) => s.estado == EstadoAjustes.listo,
    );
    bloc.add(const AjustesCargados());
    await listo;
  }

  setUp(() => repo = PreferenciasFake());

  test(
    'los cinco cambios se recuperan en una nueva instancia por cuenta',
    () async {
      final bloc = crear();
      await cargar(bloc);
      for (final campo in Preferencia.values) {
        final listo = bloc.stream.firstWhere(
          (s) => s.estado == EstadoAjustes.listo,
        );
        bloc.add(
          PreferenciaCambiada(campo, !bloc.state.preferencias!.valor(campo)),
        );
        await listo;
      }
      final nueva = crear();
      await cargar(nueva);
      expect(nueva.state.preferencias, bloc.state.preferencias);
      expect(
        nueva.state.preferencias,
        const PreferenciasUsuario(
          notificacionesPush: false,
          alertasMantenimiento: false,
          soloCriticas: true,
          modoOscuro: true,
          modoOffline: true,
        ),
      );
      final otraCuenta = crear('b');
      await cargar(otraCuenta);
      expect(otraCuenta.state.preferencias, const PreferenciasUsuario());
    },
  );

  test(
    'carga fallida no expone valores predeterminados; permite reintentar',
    () async {
      repo.fallaLectura = true;
      final bloc = crear();
      final fallo = bloc.stream.firstWhere(
        (s) => s.estado == EstadoAjustes.errorCarga,
      );
      bloc.add(const AjustesCargados());
      expect((await fallo).preferencias, isNull);
      repo.fallaLectura = false;
      repo.cuentas['a'] = const PreferenciasUsuario(modoOscuro: true);
      await cargar(bloc);
      expect(bloc.state.preferencias!.modoOscuro, isTrue);
    },
  );

  test(
    'cambio inmediato, bloqueo de cambios simultáneos y restauración ante fallo',
    () async {
      final bloc = crear();
      await cargar(bloc);
      repo.pausa = Completer<void>();
      repo.fallaEscritura = true;
      final guardando = bloc.stream.firstWhere((s) => s.guardando);
      bloc.add(const PreferenciaCambiada(Preferencia.modoOscuro, true));
      expect((await guardando).preferencias!.modoOscuro, isTrue);
      bloc.add(const PreferenciaCambiada(Preferencia.modoOffline, true));
      bloc.add(const AjustesCargados());
      await Future<void>.delayed(Duration.zero);
      expect(repo.escrituras, 1);
      expect(repo.lecturas, ['a']);
      final listo = bloc.stream.firstWhere(
        (s) => s.estado == EstadoAjustes.listo,
      );
      repo.pausa!.complete();
      final restaurado = await listo;
      expect(restaurado.preferencias, const PreferenciasUsuario());
      expect(restaurado.error, isNotEmpty);
      repo.cuentas['a'] = const PreferenciasUsuario(soloCriticas: true);
      await cargar(bloc);
      expect(bloc.state.preferencias!.soloCriticas, isTrue);
    },
  );
}
