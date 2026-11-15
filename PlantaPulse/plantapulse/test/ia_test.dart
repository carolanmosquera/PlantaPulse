// test/ia_test.dart
// El asistente de IA: la capa compartida (fuente y repositorio contra un
// cliente HTTP falso) y su uso en crear orden (KAN-92) y en el reporte del
// técnico (KAN-93). Ninguna prueba sale a la red ni gasta cuota.
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plantapulse/main.dart';
import 'package:plantapulse/src/core/core.dart';
import 'package:plantapulse/src/core/data/data.dart';
import 'package:plantapulse/src/features/crear_orden/crear_orden.dart';
import 'package:plantapulse/src/features/reportes/reportes.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'fakes.dart';

/// Un cliente de Supabase que no sale a la red: cada petición la contesta
/// [responder] y queda guardada en [peticiones].
sb.SupabaseClient clienteFalso(
  List<http.Request> peticiones,
  http.Response Function(http.Request) responder,
) =>
    sb.SupabaseClient(
      'https://proyecto.supabase.co',
      'clave-publicable-falsa',
      httpClient: MockClient((peticion) async {
        peticiones.add(peticion);
        final r = responder(peticion);
        return http.Response(r.body, r.statusCode,
            headers: r.headers, request: peticion);
      }),
      authOptions: const sb.AuthClientOptions(autoRefreshToken: false),
    );

http.Response jsonResp(Object cuerpo, [int status = 200]) => http.Response(
      jsonEncode(cuerpo),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// Lo que lanzó [accion], para revisar el tipo y el mensaje.
Future<Object?> fallaCon(Future<void> Function() accion) async {
  try {
    await accion();
  } catch (e) {
    return e;
  }
  return null;
}

void main() {
  // ═══════════ 1 · La fuente ═══════════

  group('IaFuenteSupabase', () {
    test('arma el cuerpo correcto para cada uno de los tres tipos', () async {
      final peticiones = <http.Request>[];
      final fuente = IaFuenteSupabase(
          cliente: clienteFalso(peticiones, (_) => jsonResp({'ok': true})));

      await fuente.estructurarOrden('suena raro el motor 3');
      await fuente.redactarReporte(
          notas: 'cambie el rodamiento', equipo: 'Compresor GA75');
      await fuente.resumenTurno({'pendientes': 4, 'completadas': 9});

      expect(peticiones, hasLength(3));
      for (final p in peticiones) {
        // functions_client 2.4.0 lo manda como 'post' (HttpMethod.post.name)
        expect(p.method.toUpperCase(), 'POST');
        expect(p.url.path, '/functions/v1/ia');
      }
      expect(jsonDecode(peticiones[0].body), {
        'tipo': 'estructurar_orden',
        'datos': {'nota': 'suena raro el motor 3'},
      });
      expect(jsonDecode(peticiones[1].body), {
        'tipo': 'redactar_reporte',
        'datos': {'notas': 'cambie el rodamiento', 'equipo': 'Compresor GA75'},
      });
      expect(jsonDecode(peticiones[2].body), {
        'tipo': 'resumen_turno',
        'datos': {
          'cifras': {'pendientes': 4, 'completadas': 9},
        },
      });
    });

    test('un 429 se traduce al mensaje de cuota agotada, no al genérico',
        () async {
      // Con el cuerpo de nuestra función...
      final conCuerpo = IaFuenteSupabase(
          cliente: clienteFalso([], (_) => jsonResp(
              {'error': 'Se agotó la cuota del asistente por hoy.'}, 429)));
      final e1 = await fallaCon(() => conCuerpo.estructurarOrden('nota'));
      expect(e1, isA<FalloApp>());
      expect((e1 as FalloApp).mensaje, 'Se agotó la cuota del asistente por hoy.');

      // ...y aunque el 429 venga sin cuerpo (lo pone la pasarela)
      final sinCuerpo = IaFuenteSupabase(
          cliente: clienteFalso([], (_) => http.Response('', 429)));
      final e2 = await fallaCon(() => sinCuerpo.estructurarOrden('nota'));
      expect((e2 as FalloApp).mensaje, mensajeCuotaAgotada);
      expect(e2.mensaje, isNot(contains('inesperado')));
    });

    test('el mensaje del campo "error" llega tal cual al usuario', () async {
      final fuente = IaFuenteSupabase(
          cliente: clienteFalso([], (_) => jsonResp(
              {'error': 'El asistente devolvió una respuesta ilegible.'}, 502)));
      final e = await fallaCon(() => fuente.redactarReporte(
          notas: 'cambie el rodamiento', equipo: ''));
      expect((e as FalloApp).mensaje,
          'El asistente devolvió una respuesta ilegible.');
    });

    test('sin sesión válida (401) es un fallo de permisos en español',
        () async {
      final fuente = IaFuenteSupabase(
          cliente: clienteFalso(
              [], (_) => jsonResp({'msg': 'Invalid JWT'}, 401)));
      final e = await fallaCon(() => fuente.estructurarOrden('nota'));
      expect(e, isA<FalloPermisos>());
      expect((e as FalloApp).mensaje, contains('sesión'));
    });

    test('sin conexión es un FalloRed, y no se reintenta', () async {
      var llamadas = 0;
      final fuente = IaFuenteSupabase(
        cliente: sb.SupabaseClient(
          'https://proyecto.supabase.co',
          'clave-publicable-falsa',
          httpClient: MockClient((_) async {
            llamadas++;
            throw http.ClientException('Failed host lookup');
          }),
          authOptions: const sb.AuthClientOptions(autoRefreshToken: false),
        ),
      );
      final e = await fallaCon(() => fuente.estructurarOrden('nota'));
      expect(e, isA<FalloRed>());
      expect(llamadas, 1);
    });
  });

  // ═══════════ 2 · El repositorio ═══════════

  group('IaRepositorioImpl', () {
    IaRepositorioImpl repoQueResponde(Object? prioridad) => IaRepositorioImpl(
          IaFuenteSupabase(
            cliente: clienteFalso([], (_) => jsonResp({
                  'titulo': 'Fuga en sello mecánico',
                  'descripcion': 'Revisar el sello del motor principal.',
                  'categoria_sugerida': 'Mecánico',
                  'prioridad_sugerida': prioridad,
                })),
          ),
        );

    test('"alta" se convierte en Prioridad.alta y lo desconocido en media',
        () async {
      final alta = await repoQueResponde('alta').estructurarNota('nota');
      expect(alta.prioridadSugerida, Prioridad.alta);
      expect(alta.titulo, 'Fuga en sello mecánico');
      expect(alta.categoriaSugerida, 'Mecánico');

      expect((await repoQueResponde('urgentisima').estructurarNota('n'))
          .prioridadSugerida, Prioridad.media);
      expect((await repoQueResponde(null).estructurarNota('n'))
          .prioridadSugerida, Prioridad.media);
    });

    test('la IA nunca deja una orden en crítica, aunque lo pida', () async {
      final b = await repoQueResponde('critica').estructurarNota('nota');
      expect(b.prioridadSugerida, Prioridad.media);
    });
  });

  // ═══════════ 3 y 4 · En pantalla ═══════════

  late FakeAuthService auth;
  late FakeUsuarioRepository usuarios;
  late FakeOrdenRepository ordenes;
  late FakeEquipoRepository equipos;
  late FakeCategoriaRepository categorias;
  late FakeReporteRepository reportes;
  late FakeIaRepositorio ia;

  const nota = 'Fuga de aceite en sello del motor';

  void crearCuenta(String uid, String nombre, RolUsuario rol) {
    auth.cuentas['$uid@planta.com'] = ('clave1234', uid);
    usuarios.perfiles[uid] = Usuario(
      uid: uid,
      nombre: nombre,
      email: '$uid@planta.com',
      rol: rol,
      plantaId: 'p1',
      estado: EstadoCuenta.activo,
      createdAt: DateTime(2026),
    );
  }

  setUp(() {
    auth = FakeAuthService();
    usuarios = FakeUsuarioRepository();
    ordenes = FakeOrdenRepository();
    equipos = FakeEquipoRepository();
    categorias = FakeCategoriaRepository();
    reportes = FakeReporteRepository();
    ia = FakeIaRepositorio();

    categorias.categorias.addAll(const [
      Categoria(id: 'cat-elec', plantaId: 'p1', nombre: 'Eléctrico', icono: 'rayo'),
      Categoria(id: 'cat-mec', plantaId: 'p1', nombre: 'Mecánico', icono: 'llave'),
    ]);
    equipos.equipos.add(const Equipo(
      id: 'eq-ga75',
      plantaId: 'p1',
      zonaId: 'zona-comp',
      zonaNombre: 'Sección Compresores',
      nombre: 'Compresor GA75',
      serial: 'AC-88291-K',
    ));
    crearCuenta('sup1', 'Laura Vega', RolUsuario.supervisor);
    crearCuenta('tec1', 'Luis Pérez', RolUsuario.tecnico);
  });

  /// Ignora solo los avisos de desborde de la fuente de pruebas (Ahem).
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

  Future<void> tocar(WidgetTester tester, String texto) async {
    final boton = find.text(texto);
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();
  }

  Future<void> bajarHasta(WidgetTester tester, Finder f) =>
      tester.scrollUntilVisible(f, 250,
          scrollable: find.byType(Scrollable).first);

  Future<void> entrarComo(WidgetTester tester, String uid) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(PlantaPulseApp(
      authBloc: authBlocDe(auth, usuarios),
      usuarioRepository: usuarios,
      plantaRepository: FakePlantaRepository(),
      ordenRepository: ordenes,
      equipoRepository: equipos,
      categoriaRepositorio: categorias,
      zonaRepositorio: FakeZonaRepository(),
      reporteRepositorio: reportes,
      almacenamientoRepositorio: FakeAlmacenamientoRepository(),
      iaRepositorio: ia,
    ));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '$uid@planta.com');
    await tester.enterText(find.byType(TextField).at(1), 'clave1234');
    await tocar(tester, 'Iniciar Sesión');
  }

  /// Feed → P1, con la nota escrita y el equipo elegido.
  Future<void> abrirP1ConNota(WidgetTester tester) async {
    await entrarComo(tester, 'sup1');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, nota);
    await tocar(tester, 'Compresor GA75');
  }

  Future<void> publicar(WidgetTester tester) async {
    await bajarHasta(tester, find.text('PUBLICAR ORDEN'));
    await tocar(tester, 'PUBLICAR ORDEN');
  }

  group('KAN-92 · estructurar la nota', () {
    probar('si la IA falla, el asistente llega igual al paso 2 y se publica',
        (tester) async {
      ia.fallo = const FalloApp('Se agotó la cuota del asistente por hoy.');
      await abrirP1ConNota(tester);

      await tocar(tester, 'Estructurar con IA');

      // Llegó a P2, con el error en rojo y los campos vacíos
      expect(find.text('Nueva Orden: Paso 2'), findsOneWidget);
      expect(find.textContaining('Se agotó la cuota del asistente por hoy.'),
          findsOneWidget);
      expect(find.text('SUGERIDO POR IA'), findsNothing);
      expect(ia.notas, [nota]);                         // una sola llamada

      // Y se puede publicar a mano, sin marcarla como generada por IA
      await publicar(tester);
      final orden = ordenes.creadas.single;
      expect(orden.titulo, nota);
      expect(orden.generadaPorIA, isFalse);
      expect(orden.notaOriginal, isNull);
    });

    probar('la IA prerrellena P2, marca lo propuesto y guarda la nota original',
        (tester) async {
      ia.borrador = const BorradorOrdenIa(
        titulo: 'Fuga de aceite en sello mecánico del motor principal',
        descripcion: 'Inspeccionar el sello y el nivel de aceite.',
        categoriaSugerida: 'mecánico',          // coincide sin mayúsculas
        prioridadSugerida: Prioridad.alta,
      );
      await abrirP1ConNota(tester);
      await tocar(tester, 'Estructurar con IA');

      expect(find.text('Nueva Orden: Paso 2'), findsOneWidget);
      await bajarHasta(tester, find.text('Categoría'));
      // Título, descripción, categoría y prioridad vinieron de la IA
      expect(find.text('SUGERIDO POR IA'), findsNWidgets(4));
      expect(find.text('Mecánico'), findsOneWidget);
      expect(categorias.categorias, hasLength(2));       // no creó nada

      await publicar(tester);
      final orden = ordenes.creadas.single;
      expect(orden.titulo, 'Fuga de aceite en sello mecánico del motor principal');
      expect(orden.descripcion, 'Inspeccionar el sello y el nivel de aceite.');
      expect(orden.categoria, 'Mecánico');
      expect(orden.prioridad, Prioridad.alta);
      expect(orden.generadaPorIA, isTrue);
      expect(orden.notaOriginal, nota);                 // lo que escribió la persona
    });

    probar('mientras la IA piensa, el botón se deshabilita y lo dice',
        (tester) async {
      ia.pausa = Completer<void>();
      ia.borrador = const BorradorOrdenIa(
        titulo: 'Fuga', descripcion: 'Revisar', categoriaSugerida: '',
        prioridadSugerida: Prioridad.media,
      );
      await abrirP1ConNota(tester);
      await tester.ensureVisible(find.text('Estructurar con IA'));
      await tester.tap(find.text('Estructurar con IA'));
      await tester.pump();

      expect(find.text('Estructurando...'), findsOneWidget);
      // Un segundo toque no lanza otra llamada (no se gasta cuota doble)
      await tester.tap(find.text('Estructurando...'), warnIfMissed: false);
      await tester.pump();
      expect(ia.notas, hasLength(1));

      ia.pausa!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Nueva Orden: Paso 2'), findsOneWidget);
    });

    probar('una categoría sugerida que no existe NO se inserta en la tabla',
        (tester) async {
      ia.borrador = const BorradorOrdenIa(
        titulo: 'Pinchazo en montacargas',
        descripcion: 'Cambiar la rueda delantera.',
        categoriaSugerida: 'Neumático',
        prioridadSugerida: Prioridad.baja,
      );
      await abrirP1ConNota(tester);
      await tocar(tester, 'Estructurar con IA');

      final aviso = find.textContaining('«Neumático»');
      await bajarHasta(tester, aviso);
      expect(aviso, findsOneWidget);
      expect(categorias.categorias.map((c) => c.nombre),
          isNot(contains('Neumático')));

      // El supervisor la descarta: la orden sale con la que ya estaba
      await tocar(tester, 'Descartar');
      expect(aviso, findsNothing);
      await publicar(tester);
      expect(categorias.categorias, hasLength(2));
      expect(ordenes.creadas.single.categoria, 'Eléctrico');
    });

    test('editar un campo propuesto le quita la marca de IA', () async {
      ia.borrador = const BorradorOrdenIa(
        titulo: 'Título de la IA', descripcion: 'Descripción de la IA',
        categoriaSugerida: '', prioridadSugerida: Prioridad.alta,
      );
      final bloc = crearOrdenBlocDe(
        categorias: categorias, equipos: equipos, usuarios: usuarios,
        ordenes: ordenes, ia: ia,
      );
      addTearDown(bloc.close);
      bloc
        ..add(const CrearOrdenIniciada('p1'))
        ..add(const DescripcionCambiada(nota))
        ..add(EquipoSeleccionado(equipos.equipos.first));
      await bloc.stream.firstWhere((s) => s.paso1Valido);
      bloc.add(const NotaEstructurada());
      await bloc.stream.firstWhere((s) => s.generadaPorIa);
      expect(bloc.state.marcadoPorIa(CampoIa.titulo), isTrue);

      // Repetir el mismo texto (lo hace el controlador al cargar) no cuenta
      bloc.add(const TituloCambiado('Título de la IA'));
      await pumpEventQueue();
      expect(bloc.state.marcadoPorIa(CampoIa.titulo), isTrue);

      bloc
        ..add(const TituloCambiado('Título que escribí yo'))
        ..add(const PrioridadCambiada(Prioridad.critica));
      await pumpEventQueue();
      expect(bloc.state.marcadoPorIa(CampoIa.titulo), isFalse);
      expect(bloc.state.marcadoPorIa(CampoIa.prioridad), isFalse);
      expect(bloc.state.marcadoPorIa(CampoIa.descripcion), isTrue);
    });
  });

  group('KAN-93 · redactar el reporte', () {
    Future<void> abrirReporte(WidgetTester tester) async {
      final ahora = DateTime.now();
      ordenes.ordenes.add(Orden(
        id: 'o1', codigo: 'WO-2026-0001', plantaId: 'p1',
        titulo: 'Cambio de rodamientos',
        equipoId: 'eq-ga75', equipoNombre: 'Compresor GA75',
        creadoPor: const UsuarioRef(uid: 'sup1', nombre: 'Laura Vega'),
        asignadoA: const UsuarioRef(uid: 'tec1', nombre: 'Luis Pérez'),
        asignadoAUid: 'tec1', createdAt: ahora,
        fechaLimite: ahora.add(const Duration(days: 1)), ultimaActividad: ahora,
      ));
      await entrarComo(tester, 'tec1');
      await tocar(tester, 'Cambio de rodamientos');
      await tocar(tester, 'LLENAR REPORTE DE AVANCE');
    }

    TextButton botonRedactar(WidgetTester tester) => tester.widget<TextButton>(
        find.ancestor(
            of: find.text('Redactar con IA'),
            matching: find.byWidgetPredicate((w) => w is TextButton)));

    probar('el botón de redactar está deshabilitado con el campo vacío',
        (tester) async {
      ia.redactado = 'Reporte redactado';
      await abrirReporte(tester);

      expect(botonRedactar(tester).onPressed, isNull);
      await tester.tap(find.text('Redactar con IA'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(ia.redacciones, isEmpty);                 // no gastó cuota

      // Una sola palabra tampoco alcanza; unas palabras sí
      await tester.enterText(find.byType(TextField).first, 'rodamiento');
      await tester.pump();
      expect(botonRedactar(tester).onPressed, isNull);
      await tester.enterText(find.byType(TextField).first, 'cambie el rodamiento');
      await tester.pump();
      expect(botonRedactar(tester).onPressed, isNotNull);
    });

    probar('la redacción vuelve al mismo campo, editable, y se guarda la marca',
        (tester) async {
      const redactado = 'Se reemplazó el rodamiento del compresor y se '
          'verificó su funcionamiento.';
      ia.redactado = redactado;
      await abrirReporte(tester);

      final campo = find.byType(TextField).first;
      await tester.enterText(campo, 'cambie el rodamiento');
      await tocar(tester, 'Redactar con IA');

      expect(ia.redacciones.single,
          (notas: 'cambie el rodamiento', equipo: 'Compresor GA75'));
      expect(tester.widget<TextField>(campo).controller!.text, redactado);
      expect(find.text('REDACTADO CON IA'), findsOneWidget);

      // Sigue siendo editable: el técnico corrige y la marca se va
      await tester.enterText(campo, '$redactado Quedó sin vibración.');
      await tester.pump();
      expect(find.text('REDACTADO CON IA'), findsNothing);

      await bajarHasta(tester, find.text('ENVIAR REPORTE'));
      await tocar(tester, 'ENVIAR REPORTE');
      final reporte = reportes.creadas.single;
      expect(reporte.detalles, '$redactado Quedó sin vibración.');
      expect(reporte.generadoPorIA, isTrue);
    });

    test('si la redacción falla, el texto del técnico se queda como estaba',
        () async {
      final bloc = LlenarReporteBloc(
        subirEvidencia: SubirEvidencia(FakeAlmacenamientoRepository()),
        publicarReporte: PublicarReporte(reportes),
        redactarReporte: RedactarReporte(ia),        // falla por defecto
        ordenId: 'o1',
        plantaId: 'p1',
        equipo: 'Compresor GA75',
      );
      addTearDown(bloc.close);
      bloc
        ..add(const DetallesCambiados('cambie el rodamiento'))
        ..add(const DetallesRedactados());
      final s = await bloc.stream
          .firstWhere((s) => !s.redactando && s.errorIa != null);
      expect(s.detalles, 'cambie el rodamiento');
      expect(s.generadoPorIa, isFalse);
      expect(s.errorIa, contains('no está disponible'));
      expect(ia.redacciones, hasLength(1));             // sin reintento
    });
  });

  // ═══════════ 5 · Calcular progreso (supervisor) ═══════════

  group('Calcular progreso', () {
    final base = DateTime(2026, 11, 10, 8);

    Orden ordenDePrueba() => Orden(
          id: 'o1', codigo: 'WO-2026-0001', plantaId: 'p1',
          titulo: 'Cambio de rodamientos',
          equipoId: 'eq-ga75', equipoNombre: 'Compresor GA75',
          creadoPor: const UsuarioRef(uid: 'sup1', nombre: 'Laura Vega'),
          asignadoA: const UsuarioRef(uid: 'tec1', nombre: 'Luis Pérez'),
          asignadoAUid: 'tec1',
          estado: EstadoOrden.enProgreso,
          createdAt: base,
          fechaLimite: base.add(const Duration(days: 3)),
          ultimaActividad: base,
        );

    Reporte reporteDePrueba(int horas, String detalles,
            [EstadoTrabajo estado = EstadoTrabajo.enProgreso]) =>
        Reporte(
          id: 'r$horas', ordenId: 'o1',
          autor: const UsuarioRef(uid: 'tec1', nombre: 'Luis Pérez'),
          detalles: detalles,
          estadoTrabajo: estado,
          createdAt: base.add(Duration(hours: horas)),
        );

    test('manda la orden y sus reportes en orden cronológico', () async {
      final peticiones = <http.Request>[];
      final repo = IaRepositorioImpl(IaFuenteSupabase(
          cliente: clienteFalso(peticiones, (_) => jsonResp({
                'porcentaje': 60,
                'resumen': 'Se desmontó el equipo.',
                'falta': 'Instalar el repuesto.',
              }))));

      final p = await repo.calcularProgreso(orden: ordenDePrueba(), reportes: [
        reporteDePrueba(5, 'Llegó el repuesto', EstadoTrabajo.bloqueado),
        reporteDePrueba(1, 'Desmonté el equipo'),
      ]);

      final cuerpo = jsonDecode(peticiones.single.body) as Map;
      expect(cuerpo['tipo'], 'progreso_orden');
      final datos = cuerpo['datos'] as Map;
      expect((datos['orden'] as Map)['titulo'], 'Cambio de rodamientos');
      expect((datos['orden'] as Map)['equipo'], 'Compresor GA75');
      final enviados = datos['reportes'] as List;
      expect(enviados.map((r) => r['detalles']),
          ['Desmonté el equipo', 'Llegó el repuesto']);
      expect(enviados.last['estado_trabajo'], 'bloqueado');

      expect(p.porcentaje, 60);
      expect(p.resumen, 'Se desmontó el equipo.');
      expect(p.falta, 'Instalar el repuesto.');
    });

    test('el porcentaje queda entre 0 y 100 aunque el modelo se pase',
        () async {
      Future<int> con(Object? valor) async => (await IaRepositorioImpl(
                  IaFuenteSupabase(
                      cliente: clienteFalso([], (_) => jsonResp({
                            'porcentaje': valor,
                            'resumen': 'Algo se hizo.',
                            'falta': '',
                          }))))
              .calcularProgreso(orden: ordenDePrueba(), reportes: [
            reporteDePrueba(1, 'Desmonté el equipo'),
          ]))
          .porcentaje;

      expect(await con(140), 100);
      expect(await con(-5), 0);
      expect(await con('70'), 70);
      expect(await con(72.6), 73);
      expect(await fallaCon(() => con('mucho')), isA<FalloApp>());
    });

    Future<void> abrirDetalle(WidgetTester tester, String uid,
        {int reportesSembrados = 2}) async {
      ordenes.ordenes.add(ordenDePrueba());
      if (reportesSembrados > 0) {
        reportes.creadas.add(reporteDePrueba(1, 'Desmonté el equipo'));
      }
      if (reportesSembrados > 1) {
        reportes.creadas.add(reporteDePrueba(
            5, 'Falta el rodamiento nuevo', EstadoTrabajo.bloqueado));
      }
      await entrarComo(tester, uid);
      await tocar(tester, 'Cambio de rodamientos');
    }

    probar('el supervisor calcula el progreso y ve la barra con el aviso',
        (tester) async {
      ia.progreso = const ProgresoOrdenIa(
        porcentaje: 60,
        resumen: 'Se desmontó el equipo y se identificó el rodamiento dañado.',
        falta: 'Instalar el repuesto; podría cerrarse en uno o dos días.',
      );
      await abrirDetalle(tester, 'sup1');

      await bajarHasta(tester, find.text('CALCULAR PROGRESO'));
      await tocar(tester, 'CALCULAR PROGRESO');

      expect(ia.progresos.single.reportes, hasLength(2));
      expect(ia.progresos.single.orden.id, 'o1');
      expect(find.text('≈ 60 %'), findsOneWidget);
      final barra = tester.widget<LinearProgressIndicator>(find.byWidgetPredicate(
          (w) => w is LinearProgressIndicator && w.value != null));
      expect(barra.value, closeTo(0.6, 0.001));
      expect(find.textContaining('rodamiento dañado'), findsOneWidget);
      expect(find.textContaining('uno o dos días'), findsOneWidget);
      expect(find.text('Basado en 2 reportes.'), findsOneWidget);
      // El aviso de que es criterio de IA va con el resultado
      expect(find.textContaining('no debe tomarse como literal'),
          findsOneWidget);
      expect(find.text('CALCULAR PROGRESO'), findsNothing);
    });

    probar('si la IA falla, aviso en rojo, sin reintento y se puede volver a pedir',
        (tester) async {
      ia.fallo = const FalloApp('Se agotó la cuota del asistente por hoy.');
      await abrirDetalle(tester, 'sup1');

      await bajarHasta(tester, find.text('CALCULAR PROGRESO'));
      await tocar(tester, 'CALCULAR PROGRESO');

      expect(find.textContaining('Se agotó la cuota del asistente por hoy.'),
          findsOneWidget);
      expect(ia.progresos, hasLength(1));
      expect(find.text('CALCULAR PROGRESO'), findsOneWidget);
    });

    probar('el técnico no ve "Calcular progreso"', (tester) async {
      await abrirDetalle(tester, 'tec1');
      await bajarHasta(tester, find.text('Desmonté el equipo'));
      expect(find.text('CALCULAR PROGRESO'), findsNothing);
    });

    probar('sin reportes no se ofrece (no hay nada que estimar)',
        (tester) async {
      await abrirDetalle(tester, 'sup1', reportesSembrados: 0);
      await bajarHasta(tester, find.text('Aún no hay reportes de avance'));
      expect(find.text('CALCULAR PROGRESO'), findsNothing);
    });
  });
}
