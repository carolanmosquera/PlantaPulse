// test/alertas_avisos_test.dart
// KAN-90: enviar una alerta crítica con la ubicación y que los supervisores
//         la reciban.
// KAN-100: elegir qué avisos recibir y que la elección se conserve.
// Todo con repositorios falsos en memoria: no hay Supabase ni GPS.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantapulse/main.dart';
import 'package:plantapulse/src/core/core.dart';
import 'package:plantapulse/src/features/novedades/novedades.dart';

import 'fakes.dart';
import 'push_test.dart' show FakePush;

class FakeAlertaCriticaRepository implements AlertaCriticaRepositorio {
  final List<AlertaCritica> enviadas = [];
  final _abiertas = StreamController<List<AlertaCritica>>.broadcast();
  Object? fallo;

  @override
  Future<void> enviar(AlertaCritica alerta) async {
    if (fallo != null) throw fallo!;
    enviadas.add(alerta);
  }

  @override
  Stream<List<AlertaCritica>> abiertasDeLaPlanta(String plantaId) =>
      _abiertas.stream;

  /// Lo que recibiría el supervisor desde la base de datos.
  void llega(List<AlertaCritica> lista) => _abiertas.add(lista);
}

class FakeUbicacion implements UbicacionRepositorio {
  final PuntoGps? punto;
  FakeUbicacion(this.punto);

  @override
  Future<PuntoGps?> actual() async => punto;
}

/// Perfiles que guardan de verdad los cambios, como la tabla usuarios.
class UsuariosConAjustes extends FakeUsuarioRepository {
  final List<String> pasos = [];
  Object? falloAlGuardar;

  @override
  Future<void> actualizar(String uid, Map<String, dynamic> cambios) async {
    if (falloAlGuardar != null) throw falloAlGuardar!;
    final json = cambios['preferenciasAvisos'];
    perfiles[uid] = perfiles[uid]!
        .copyWith(preferenciasAvisos: PreferenciasAvisos.fromJson(json));
    pasos.add('actualizar');
  }

  @override
  Future<void> guardarTokenPush(String uid, String token) async =>
      pasos.add('token+');

  @override
  Future<void> borrarTokenPush(String uid) async => pasos.add('token-');
}

void main() {
  late FakeAuthService auth;
  late UsuariosConAjustes usuarios;
  late FakeAlertaCriticaRepository alertas;
  late FakePush push;

  Usuario cuenta(String uid, RolUsuario rol, {String planta = 'p1'}) {
    auth.cuentas['$uid@planta.com'] = ('clave1234', uid);
    return usuarios.perfiles[uid] = Usuario(
      uid: uid,
      nombre: 'Persona $uid',
      email: '$uid@planta.com',
      rol: rol,
      plantaId: planta,
      estado: EstadoCuenta.activo,
      createdAt: DateTime(2026),
    );
  }

  setUp(() {
    auth = FakeAuthService();
    usuarios = UsuariosConAjustes();
    alertas = FakeAlertaCriticaRepository();
    push = FakePush();
    cuenta('tec1', RolUsuario.tecnico);
    cuenta('sup1', RolUsuario.supervisor);
  });

  void probar(String nombre, Future<void> Function(WidgetTester) cuerpo) {
    testWidgets(nombre, (tester) async {
      final original = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.toString().contains('overflowed')) return;
        original?.call(d);
      };
      try {
        await cuerpo(tester);
      } finally {
        FlutterError.onError = original;
      }
    });
  }

  Future<void> arrancar(WidgetTester tester, String uid,
      {PuntoGps? gps = const PuntoGps(3.58, -76.49)}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(PlantaPulseApp(
      authBloc: authBlocDe(auth, usuarios),
      usuarioRepository: usuarios,
      plantaRepository: FakePlantaRepository(),
      ordenRepository: FakeOrdenRepository(),
      equipoRepository: FakeEquipoRepository(),
      categoriaRepositorio: FakeCategoriaRepository(),
      zonaRepositorio: FakeZonaRepository(),
      reporteRepositorio: FakeReporteRepository(),
      almacenamientoRepositorio: FakeAlmacenamientoRepository(),
      pushRepositorio: push,
      alertaCriticaRepositorio: alertas,
      ubicacionRepositorio: FakeUbicacion(gps),
    ));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    if (find.text('Iniciar Sesión').evaluate().isNotEmpty) {
      await tester.enterText(find.byType(TextField).at(0), '$uid@planta.com');
      await tester.enterText(find.byType(TextField).at(1), 'clave1234');
      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pumpAndSettle();
    }
    expect(find.text('PlantaPulse Feed'), findsOneWidget);
  }

  Future<void> tocar(WidgetTester tester, Finder f) async {
    // Las listas son perezosas: lo que está fuera de pantalla aún no existe
    if (f.evaluate().isEmpty) {
      await tester.scrollUntilVisible(f, 300,
          scrollable: find.byType(Scrollable).first);
    }
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  /// Deja correr la cadena de awaits (guardar, borrar token...) que
  /// pumpAndSettle no espera porque no agenda cuadros.
  Future<void> esperarCadena(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Future<void> abrirEmergencia(WidgetTester tester) async {
    await tocar(tester, find.byTooltip('Reportar emergencia'));
    expect(find.text('Reporte de Emergencia'), findsOneWidget);
  }

  // ─────────────── KAN-90 ───────────────

  group('KAN-90 alerta crítica', () {
    test('el caso de uso arma la alerta con planta, autor y ubicación', () async {
      final usuario = usuarios.perfiles['tec1']!;
      await EnviarAlertaCritica(alertas).ejecutar(
        usuario: usuario,
        tipo: TipoEmergencia.fuego,
        descripcion: '  Humo en la bodega 3  ',
        ubicacion: const PuntoGps(3.58, -76.49),
      );
      final a = alertas.enviadas.single;
      expect(a.plantaId, 'p1');
      expect(a.creadoPor.uid, 'tec1');
      expect(a.tipo, TipoEmergencia.fuego);
      expect(a.descripcion, 'Humo en la bodega 3');
      expect(a.estado, EstadoAlerta.abierta);
      expect(a.ubicacionGps!.latitude, 3.58);
    });

    test('rechaza una descripción muy corta o muy larga', () async {
      final usuario = usuarios.perfiles['tec1']!;
      final caso = EnviarAlertaCritica(alertas);
      await expectLater(
          caso.ejecutar(
              usuario: usuario, tipo: TipoEmergencia.fuga, descripcion: 'fuga'),
          throwsA(isA<FalloApp>()));
      await expectLater(
          caso.ejecutar(
              usuario: usuario,
              tipo: TipoEmergencia.fuga,
              descripcion: 'x' * 201),
          throwsA(isA<FalloApp>()));
      expect(alertas.enviadas, isEmpty);
    });

    probar('criterio 1: elige categoría, describe y envía con su ubicación',
        (tester) async {
      await arrancar(tester, 'tec1');
      await abrirEmergencia(tester);

      // Sin descripción no se puede enviar
      final enviar = find.text('ENVIAR ALERTA AHORA');
      await tester.scrollUntilVisible(enviar, 300,
          scrollable: find.byType(Scrollable).first);
      final boton = find.ancestor(
          of: enviar, matching: find.bySubtype<ElevatedButton>());
      expect(tester.widget<ElevatedButton>(boton).onPressed, isNull);

      // La ubicación ya se detectó
      expect(find.text('GPS: 3.58000, -76.49000'), findsOneWidget);

      await tocar(tester, find.text('Falla Eléctrica'));
      await tester.enterText(find.byType(TextField),
          'Chispas y olor a quemado en el tablero principal');
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(boton).onPressed, isNotNull);

      await tocar(tester, enviar);
      await tocar(tester, find.text('ENVIAR')); // confirma el diálogo

      final a = alertas.enviadas.single;
      expect(a.tipo, TipoEmergencia.electrico);
      expect(a.creadoPor.uid, 'tec1');
      expect(a.plantaId, 'p1');
      expect(a.ubicacionGps!.longitude, -76.49);
      expect(find.text('Alerta enviada a supervisores'), findsOneWidget);
      expect(find.text('PlantaPulse Feed'), findsOneWidget); // volvió al feed
    });

    probar('sin GPS la alerta se envía igual', (tester) async {
      await arrancar(tester, 'tec1', gps: null);
      await abrirEmergencia(tester);
      expect(find.textContaining('Ubicación no disponible'), findsOneWidget);

      await tester.enterText(
          find.byType(TextField), 'Fuga de agua en el sótano de calderas');
      await tester.pumpAndSettle();
      await tocar(tester, find.text('ENVIAR ALERTA AHORA'));
      await tocar(tester, find.text('ENVIAR'));

      expect(alertas.enviadas.single.ubicacionGps, isNull);
    });

    probar('si no se puede guardar, avisa y se queda para reintentar',
        (tester) async {
      alertas.fallo = const FalloRed();
      await arrancar(tester, 'tec1');
      await abrirEmergencia(tester);

      await tester.enterText(
          find.byType(TextField), 'Falla mecánica en la banda 2 de empaque');
      await tester.pumpAndSettle();
      await tocar(tester, find.text('ENVIAR ALERTA AHORA'));
      await tocar(tester, find.text('ENVIAR'));

      expect(find.text('Sin conexión. Revisa tu internet.'), findsOneWidget);
      expect(find.text('Reporte de Emergencia'), findsOneWidget);
      expect(alertas.enviadas, isEmpty);

      // Reintenta cuando vuelve la red
      alertas.fallo = null;
      await tocar(tester, find.text('ENVIAR ALERTA AHORA'));
      await tocar(tester, find.text('ENVIAR'));
      expect(alertas.enviadas, hasLength(1));
    });

    probar('criterio 2: el supervisor conectado recibe la alerta nueva',
        (tester) async {
      await arrancar(tester, 'sup1');
      final vieja = AlertaCritica(
        id: 'a0',
        plantaId: 'p1',
        tipo: TipoEmergencia.mecanico,
        descripcion: 'Ya estaba abierta antes',
        creadoPor: const UsuarioRef(uid: 'tec1', nombre: 'Persona tec1'),
        createdAt: DateTime(2026),
      );
      alertas.llega([vieja]); // lo que ya había: no se avisa
      await tester.pump();
      expect(find.textContaining('ALERTA CRÍTICA'), findsNothing);

      final nueva = AlertaCritica(
        id: 'a1',
        plantaId: 'p1',
        tipo: TipoEmergencia.fuego,
        descripcion: 'Incendio en bodega 3',
        creadoPor: const UsuarioRef(uid: 'tec1', nombre: 'Persona tec1'),
        createdAt: DateTime(2026, 2),
      );
      alertas.llega([nueva, vieja]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('ALERTA CRÍTICA · Fuego / Incendio'),
          findsOneWidget);
      expect(find.textContaining('Incendio en bodega 3'), findsOneWidget);

      // "VER" lleva a la lista de alertas, donde queda la alerta abierta
      await tester.pump(const Duration(seconds: 1)); // termina de aparecer
      await tester.tap(find.text('VER'));
      await tester.pumpAndSettle();
      expect(find.text('Alertas de Planta'), findsOneWidget);
      alertas.llega([nueva, vieja]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('ALERTAS CRÍTICAS ABIERTAS'), findsOneWidget);
    });

    probar('el técnico no recibe el aviso de alertas de sus compañeros',
        (tester) async {
      await arrancar(tester, 'tec1');
      alertas.llega([]);
      await tester.pump();
      alertas.llega([
        AlertaCritica(
          id: 'a1',
          plantaId: 'p1',
          tipo: TipoEmergencia.fuego,
          descripcion: 'Incendio en bodega 3',
          creadoPor: const UsuarioRef(uid: 'otro', nombre: 'Otro'),
          createdAt: DateTime(2026),
        )
      ]);
      await tester.pump();
      expect(find.textContaining('ALERTA CRÍTICA'), findsNothing);
    });
  });

  // ─────────────── KAN-100 ───────────────

  group('KAN-100 configuración de avisos', () {
    test('las preferencias viajan en JSON y lo que falta vale el valor por defecto',
        () {
      const p = PreferenciasAvisos(push: false, soloCriticas: true);
      expect(PreferenciasAvisos.fromJson(p.toJson()), p);
      expect(PreferenciasAvisos.fromJson(null), const PreferenciasAvisos());
      expect(PreferenciasAvisos.fromJson({'push': false}).mantenimiento, isTrue);
    });

    Future<void> abrirAjustes(WidgetTester tester) async {
      PlantaPulseApp.navegador.currentState!.pushNamed(Rutas.ajustes);
      await tester.pumpAndSettle();
      expect(find.text('Ajustes de PlantaPulse'), findsOneWidget);
    }

    bool encendido(WidgetTester tester, String clave) =>
        tester.widget<Switch>(find.byKey(Key(clave))).value;

    probar('criterios 1 y 3: la preferencia se conserva al cerrar y reabrir',
        (tester) async {
      await arrancar(tester, 'tec1');
      await abrirAjustes(tester);
      expect(encendido(tester, 'switch-mantenimiento'), isTrue);

      // Criterio 2/1: apaga un tipo de aviso
      await tocar(tester, find.byKey(const Key('switch-mantenimiento')));
      expect(encendido(tester, 'switch-mantenimiento'), isFalse);
      expect(usuarios.perfiles['tec1']!.preferenciasAvisos.mantenimiento,
          isFalse);

      // "Cierra y vuelve a abrir la aplicación": app nueva, mismo perfil
      await tester.pumpWidget(const SizedBox());
      await arrancar(tester, 'tec1');
      await abrirAjustes(tester);
      expect(encendido(tester, 'switch-mantenimiento'), isFalse);
      expect(encendido(tester, 'switch-push'), isTrue); // los demás, intactos

      // Criterio 3: lo vuelve a activar y queda guardado
      await tocar(tester, find.byKey(const Key('switch-mantenimiento')));
      expect(encendido(tester, 'switch-mantenimiento'), isTrue);
      expect(usuarios.perfiles['tec1']!.preferenciasAvisos.mantenimiento,
          isTrue);
    });

    probar('apagar el push borra el token del dispositivo; encenderlo lo registra',
        (tester) async {
      await arrancar(tester, 'tec1');
      await abrirAjustes(tester);
      usuarios.pasos.clear();

      await tocar(tester, find.byKey(const Key('switch-push')));
      await esperarCadena(tester);
      expect(usuarios.pasos, ['actualizar', 'token-']);
      expect(push.desactivado, isTrue);

      await tocar(tester, find.byKey(const Key('switch-push')));
      await esperarCadena(tester);
      expect(usuarios.pasos.last, 'token+');
    });

    probar('con el push apagado, al iniciar sesión no se registra el dispositivo',
        (tester) async {
      usuarios.perfiles['tec1'] = usuarios.perfiles['tec1']!.copyWith(
          preferenciasAvisos: const PreferenciasAvisos(push: false));
      await arrancar(tester, 'tec1');
      expect(usuarios.pasos, isNot(contains('token+')));
    });

    probar('si no se puede guardar, el interruptor vuelve atrás y avisa',
        (tester) async {
      await arrancar(tester, 'tec1');
      await abrirAjustes(tester);
      usuarios.falloAlGuardar = const FalloRed();

      await tocar(tester, find.byKey(const Key('switch-criticas')));

      expect(encendido(tester, 'switch-criticas'), isFalse);
      expect(find.textContaining('No se pudo guardar tu preferencia'),
          findsOneWidget);
      expect(usuarios.perfiles['tec1']!.preferenciasAvisos.soloCriticas,
          isFalse);
    });
  });
}
