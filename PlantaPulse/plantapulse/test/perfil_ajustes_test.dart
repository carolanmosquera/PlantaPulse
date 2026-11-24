import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantapulse/main.dart';
import 'package:plantapulse/src/core/core.dart';
import 'package:plantapulse/src/features/perfil/perfil.dart';
import 'fakes.dart';

class UsuariosConFallo extends FakeUsuarioRepository {
  bool fallar = false;
  @override
  Future<Usuario?> obtener(String uid) async {
    if (fallar) throw const FalloRed();
    return super.obtener(uid);
  }
}

void main() {
  late FakeAuthService auth;
  late UsuariosConFallo usuarios;
  late PreferenciasFake preferencias;

  Usuario cuenta(
    String uid,
    RolUsuario rol, {
    String planta = 'p2',
    String especialidad = 'Electrónica',
  }) => Usuario(
    uid: uid,
    nombre: 'Nombre $uid',
    email: '$uid@example.com',
    rol: rol,
    plantaId: planta,
    especialidad: especialidad,
    turno: 'Nocturno',
    estado: EstadoCuenta.activo,
    createdAt: DateTime(2026),
  );

  setUp(() {
    auth = FakeAuthService();
    usuarios = UsuariosConFallo();
    preferencias = PreferenciasFake();
    for (final uid in ['a', 'b']) {
      usuarios.perfiles[uid] = cuenta(uid, RolUsuario.tecnico);
      auth.cuentas['$uid@example.com'] = ('clave-prueba', uid);
    }
  });

  Future<void> arrancar(WidgetTester tester, [String uid = 'a']) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await auth.entrar(email: '$uid@example.com', password: 'clave-prueba');
    await tester.pumpWidget(
      PlantaPulseApp(
        key: UniqueKey(),
        authBloc: authBlocDe(auth, usuarios),
        usuarioRepository: usuarios,
        plantaRepository: FakePlantaRepository(),
        ordenRepository: FakeOrdenRepository(),
        equipoRepository: FakeEquipoRepository(),
        reporteRepositorio: FakeReporteRepository(),
        almacenamientoRepositorio: FakeAlmacenamientoRepository(),
        preferenciasRepositorio: preferencias,
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  Future<void> tocar(WidgetTester tester, String texto) async {
    final finder = find.text(texto);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> abrirAjustes(WidgetTester tester) async {
    await tocar(tester, 'Perfil');
    await tocar(tester, 'Ajustes de Cuenta');
    expect(find.text('Ajustes de PlantaPulse'), findsOneWidget);
  }

  Key clave(Preferencia campo) => switch (campo) {
    Preferencia.notificacionesPush => const Key('switch-push'),
    Preferencia.alertasMantenimiento => const Key('switch-mantenimiento'),
    Preferencia.soloCriticas => const Key('switch-criticas'),
    _ => ValueKey(campo),
  };

  Switch interruptor(WidgetTester tester, Preferencia campo) =>
      tester.widget<Switch>(find.byKey(clave(campo)));

  for (final rol in RolUsuario.values) {
    testWidgets('perfil de ${rol.name}: datos de la cuenta y gestión según rol', (
      tester,
    ) async {
      usuarios.perfiles['a'] = cuenta('a', rol);
      await arrancar(tester);
      // El perfil debe consultar el repositorio, no reutilizar un nombre antiguo de sesión.
      usuarios.perfiles['a'] = usuarios.perfiles['a']!.copyWith(
        nombre: 'Nombre actualizado',
      );
      await tocar(tester, 'Perfil');
      expect(find.text('Nombre actualizado'), findsOneWidget);
      expect(find.text(rol.etiqueta), findsOneWidget);
      expect(find.text('Planta Sur'), findsOneWidget);
      expect(find.text('Electrónica'), findsOneWidget);
      expect(find.text('a@example.com'), findsOneWidget);
      expect(find.text('Nocturno'), findsOneWidget);
      expect(
        find.text('Solicitudes de registro'),
        rol.esAdmin ? findsOneWidget : findsNothing,
      );
      expect(find.textContaining('Carlos'), findsNothing);
      expect(find.textContaining('EMP-'), findsNothing);
      expect(find.byType(StatCard), findsNothing);
      expect(find.text('Ajustes de Cuenta'), findsOneWidget);
    });
  }

  testWidgets('perfil sin planta ni especialidad muestra textos explicativos', (
    tester,
  ) async {
    usuarios.perfiles['a'] = cuenta(
      'a',
      RolUsuario.tecnico,
      planta: '',
      especialidad: '  ',
    );
    await arrancar(tester);
    await tocar(tester, 'Perfil');
    expect(find.text('Sin planta asignada'), findsOneWidget);
    expect(find.text('Sin especialidad registrada'), findsOneWidget);
  });

  testWidgets('error al consultar perfil y reintento', (tester) async {
    await arrancar(tester);
    usuarios.fallar = true;
    await tocar(tester, 'Perfil');
    expect(find.text('Nombre a'), findsNothing);
    expect(find.text('Reintentar'), findsOneWidget);
    usuarios.fallar = false;
    await tocar(tester, 'Reintentar');
    expect(find.text('Nombre a'), findsOneWidget);
  });

  testWidgets(
    'cinco interruptores persisten al volver, reiniciar y cambiar de cuenta',
    (tester) async {
      await arrancar(tester);
      await abrirAjustes(tester);
      expect(find.text('Nombre a'), findsOneWidget);
      expect(find.text(RolUsuario.tecnico.etiqueta), findsOneWidget);
      for (final campo in Preferencia.values) {
        final control = find.byKey(clave(campo));
        await tester.ensureVisible(control);
        await tester.tap(control);
        await tester.pumpAndSettle();
        expect(
          interruptor(tester, campo).value,
          !const PreferenciasUsuario().valor(campo),
        );
      }
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      await tocar(tester, 'Ajustes de Cuenta');
      for (final campo in Preferencia.values) {
        expect(
          interruptor(tester, campo).value,
          !const PreferenciasUsuario().valor(campo),
        );
      }
      expect(preferencias.lecturas, ['a', 'a', 'a']);
      expect(
        Theme.of(
          tester.element(find.text('Ajustes de PlantaPulse')),
        ).brightness,
        Brightness.dark,
      );
      // Cerrar sesión desde ajustes sigue funcionando y lleva al login.
      await tocar(tester, 'CERRAR SESIÓN');
      expect(auth.uidActual, isNull);
      expect(find.text('Acceso al Sistema'), findsOneWidget);
      // El login existente tiene una fila sin Expanded que desborda con Ahem,
      // la fuente de test. Solo consumimos ese error en el login; los errores
      // de Perfil y Ajustes siguen haciendo fallar la prueba.
      final errorLogin = tester.takeException();
      if (errorLogin != null) {
        expect(errorLogin.toString(), contains('A RenderFlex overflowed'));
      }
      await arrancar(tester, 'b');
      await abrirAjustes(tester);
      expect(
        Theme.of(
          tester.element(find.text('Ajustes de PlantaPulse')),
        ).brightness,
        Brightness.light,
      );
      expect(find.text('Nombre b'), findsOneWidget);
      for (final campo in Preferencia.values) {
        expect(
          interruptor(tester, campo).value,
          const PreferenciasUsuario().valor(campo),
        );
      }
      await tester.pumpWidget(const SizedBox());
      await arrancar(tester, 'a');
      expect(
        Theme.of(tester.element(find.text('PlantaPulse Feed'))).brightness,
        Brightness.dark,
      );
      await abrirAjustes(tester);
      for (final campo in Preferencia.values) {
        expect(
          interruptor(tester, campo).value,
          !const PreferenciasUsuario().valor(campo),
        );
      }
    },
  );

  testWidgets(
    'guardado pendiente bloquea controles y navegación; error restaura el valor',
    (tester) async {
      await arrancar(tester);
      await abrirAjustes(tester);
      preferencias.pausa = Completer<void>();
      preferencias.fallaEscritura = true;
      await tester.tap(find.byKey(clave(Preferencia.notificacionesPush)));
      await tester.pump();
      expect(find.text('Guardando…'), findsOneWidget);
      expect(
        interruptor(tester, Preferencia.notificacionesPush).value,
        isFalse,
      );
      expect(interruptor(tester, Preferencia.modoOscuro).onChanged, isNull);
      await tester.tap(find.text('Perfil'), warnIfMissed: false);
      await tester.tap(find.byIcon(Icons.chevron_left), warnIfMissed: false);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Ajustes de PlantaPulse'), findsOneWidget);
      preferencias.pausa!.complete();
      await tester.pumpAndSettle();
      expect(interruptor(tester, Preferencia.notificacionesPush).value, isTrue);
      expect(find.text('Volver a cargar'), findsOneWidget);
      preferencias.cuentas['a'] = const PreferenciasUsuario(modoOscuro: true);
      await tocar(tester, 'Volver a cargar');
      expect(interruptor(tester, Preferencia.modoOscuro).value, isTrue);
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.text('Mi Perfil'), findsOneWidget);
    },
  );

  testWidgets(
    'modo oscuro cambia toda la ruta y se restaura si falla el guardado',
    (tester) async {
      await arrancar(tester);
      await abrirAjustes(tester);
      preferencias.pausa = Completer<void>();
      preferencias.fallaEscritura = true;
      await tester.tap(find.byKey(const ValueKey(Preferencia.modoOscuro)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        Theme.of(
          tester.element(find.text('Ajustes de PlantaPulse')),
        ).brightness,
        Brightness.dark,
      );
      expect(
        tester
            .widget<Scaffold>(find.byType(Scaffold))
            .backgroundColor!
            .computeLuminance(),
        lessThan(0.1),
      );
      preferencias.pausa!.complete();
      await tester.pumpAndSettle();
      expect(
        Theme.of(
          tester.element(find.text('Ajustes de PlantaPulse')),
        ).brightness,
        Brightness.light,
      );
      expect(interruptor(tester, Preferencia.modoOscuro).value, isFalse);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        AppColors.fondo,
      );
    },
  );

  testWidgets(
    'carga fallida no muestra interruptores como si estuvieran guardados',
    (tester) async {
      preferencias.fallaLectura = true;
      await arrancar(tester);
      await abrirAjustes(tester);
      expect(find.byType(Switch), findsNothing);
      preferencias.fallaLectura = false;
      await tocar(tester, 'Volver a cargar');
      expect(find.byType(Switch), findsNWidgets(5));
    },
  );
}
