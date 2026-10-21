// test/reportes_flujo_test.dart
// Evidencia fotográfica y ciclo del reporte: el técnico documenta con
// fotos, el supervisor valida y cierra.
//
// Las pruebas 1 y 5 usan los repositorios REALES de Supabase con un
// cliente HTTP falso (MockClient): verifican la petición que se enviaría
// sin tocar ningún proyecto. El resto prueba el Bloc contra fakes.
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plantapulse/main.dart';
import 'package:plantapulse/src/core/core.dart';
import 'package:plantapulse/src/core/data/models/evidencia_modelo.dart';
import 'package:plantapulse/src/core/data/models/reporte_modelo.dart';
import 'package:plantapulse/src/core/data/repositories/almacenamiento_repositorio_supabase.dart';
import 'package:plantapulse/src/features/ordenes/data/repositories/orden_repositorio_supabase.dart';
import 'package:plantapulse/src/features/reportes/reportes.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'fakes.dart';

/// Un cliente de Supabase que no sale a la red: cada petición la contesta
/// [responder], y la última queda en [peticiones] para revisarla.
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
        // postgrest lee response.request: una respuesta armada a mano no
        // la trae y revienta con un null check
        return http.Response(r.body, r.statusCode,
            headers: r.headers, request: peticion);
      }),
      authOptions: const sb.AuthClientOptions(autoRefreshToken: false),
    );

void main() {
  const tecnico = UsuarioRef(uid: 'tec1', nombre: 'Luis Pérez');
  final foto1 = Uint8List.fromList([1, 2, 3]);
  final foto2 = Uint8List.fromList([4, 5, 6]);

  late FakeAlmacenamientoRepository almacen;
  late FakeReporteRepository reportes;
  late FakeOrdenRepository ordenes;

  setUp(() {
    almacen = FakeAlmacenamientoRepository();
    reportes = FakeReporteRepository();
    ordenes = FakeOrdenRepository();
  });

  LlenarReporteBloc nuevoBloc() => LlenarReporteBloc(
        subirEvidencia: SubirEvidencia(almacen),
        publicarReporte: PublicarReporte(reportes),
        ordenId: 'orden-1',
        plantaId: 'planta_norte',
      );

  /// Escribe el texto, agrega las fotos y publica; espera a que termine.
  Future<LlenarReporteState> publicar(
    LlenarReporteBloc bloc, {
    List<Uint8List> fotos = const [],
    String texto = 'Cambio de rodamientos y engrase del eje',
  }) async {
    bloc.add(DetallesCambiados(texto));
    for (final f in fotos) {
      bloc.add(FotoAgregada(f, 'jpg'));
    }
    bloc.add(const ReportePublicado(tecnico));
    return bloc.stream.firstWhere((s) =>
        s.status == EstadoLlenarReporte.publicado ||
        s.status == EstadoLlenarReporte.error);
  }

  // 1
  test('subir una foto devuelve una RUTA (planta/orden/...), no una URL',
      () async {
    final peticiones = <http.Request>[];
    final cliente = clienteFalso(peticiones, (p) => http.Response(
        jsonEncode({'Key': 'evidencias/lo-que-diga-storage', 'Id': 'x'}), 200,
        headers: {'content-type': 'application/json'}));
    addTearDown(cliente.dispose);
    final repo = AlmacenamientoRepositorioSupabase(cliente: cliente);

    final ruta = await repo.subir(
      plantaId: 'planta_norte',
      ordenId: 'orden-1',
      bytes: foto1,
      extension: 'JPEG',
    );

    // Lo que se guarda: la ruta que armamos, no la 'Key' (trae el bucket)
    expect(ruta, startsWith('planta_norte/orden-1/'));
    expect(ruta, endsWith('.jpg'));
    expect(ruta, isNot(contains('http')));
    expect(ruta, isNot(startsWith('evidencias/')));
    // La primera carpeta es la planta: la política del bucket lo exige
    expect(ruta.split('/').first, 'planta_norte');

    // Y es justo donde se subió, en el bucket 'evidencias', sin sobrescribir
    final subida = peticiones.single;
    expect(subida.method, 'POST');
    expect(subida.url.path, '/storage/v1/object/evidencias/$ruta');
    expect(subida.headers['x-upsert'], 'false');
    expect(subida.body, contains('image/jpeg'));

    // La URL se calcula aparte, siempre desde la ruta
    expect(repo.urlDe(ruta),
        'https://proyecto.supabase.co/storage/v1/object/public/evidencias/$ruta');
  });

  // 2
  test('un reporte con dos fotos arma evidencias con ruta, fecha y autor',
      () async {
    final bloc = nuevoBloc();
    addTearDown(bloc.close);

    final fin = await publicar(bloc, fotos: [foto1, foto2]);
    expect(fin.status, EstadoLlenarReporte.publicado);

    final reporte = reportes.creadas.single;
    expect(reporte.evidencias, hasLength(2));
    expect(reporte.evidencias.map((e) => e.ruta), almacen.subidas);
    for (final e in reporte.evidencias) {
      expect(e.ruta, startsWith('planta_norte/orden-1/'));
      expect(e.autorUid, 'tec1');
    }

    // Así viaja a la columna jsonb 'evidencias'
    final json = ReporteModelo.desdeEntidad(reporte).toJson();
    final evidencias = json['evidencias'] as List;
    expect(evidencias, hasLength(2));
    for (final e in evidencias.cast<Map<String, dynamic>>()) {
      expect(e.keys, unorderedEquals(['ruta', 'subidaEn', 'autorUid']));
      expect(e['subidaEn'], endsWith('Z'));        // UTC, como todas las fechas
      expect(EvidenciaModelo.fromJson(e).autorUid, 'tec1');
    }
    expect(json['detalles'], 'Cambio de rodamientos y engrase del eje');
  });

  // 3
  test('el Bloc de reportes no actualiza la orden: eso lo hace el servidor',
      () async {
    final bloc = nuevoBloc();
    addTearDown(bloc.close);

    // Incluso un reporte "resuelto" y de alerta crítica, que en el servidor
    // cambia el estado y los contadores
    bloc.add(const EstadoTrabajoCambiado(EstadoTrabajo.resuelto));
    bloc.add(const AlertaCriticaCambiada(true));
    final fin = await publicar(bloc, fotos: [foto1]);

    expect(fin.status, EstadoLlenarReporte.publicado);
    expect(ordenes.mutaciones, 0);
    final reporte = reportes.creadas.single;
    expect(reporte.estadoTrabajo, EstadoTrabajo.resuelto);
    expect(reporte.esAlertaCritica, isTrue);
  });

  // 4
  test('un reporte sin fotos se publica igual', () async {
    final bloc = nuevoBloc();
    addTearDown(bloc.close);

    bloc.add(const EstadoTrabajoCambiado(EstadoTrabajo.bloqueado));
    final fin = await publicar(bloc,
        texto: 'Bloqueado esperando repuesto del proveedor');

    expect(fin.status, EstadoLlenarReporte.publicado);
    expect(almacen.subidas, isEmpty);
    expect(reportes.creadas.single.evidencias, isEmpty);
    expect(reportes.creadas.single.estadoTrabajo, EstadoTrabajo.bloqueado);
  });

  // 5
  test('cerrar una orden envía validada_por y fecha_cierre en UTC', () async {
    final peticiones = <http.Request>[];
    final cliente = clienteFalso(peticiones, (_) => http.Response('', 204));
    addTearDown(cliente.dispose);
    final repo = OrdenRepositorioSupabase(cliente: cliente);

    const supervisor = UsuarioRef(uid: 'sup1', nombre: 'Laura Vega');
    final antes = DateTime.now().toUtc();
    await repo.cerrar(
      ordenId: 'orden-1',
      validadaPor: supervisor,
      observaciones: '  Buen trabajo  ',
    );

    final p = peticiones.single;
    expect(p.method, 'PATCH');                       // un update…
    expect(p.url.path, '/rest/v1/ordenes');
    expect(p.url.queryParameters['id'], 'eq.orden-1');
    expect(p.url.queryParameters.containsKey('select'), isFalse); // …sin .select()

    final cuerpo = jsonDecode(p.body) as Map<String, dynamic>;
    expect(cuerpo['estado'], 'completada');
    expect(cuerpo['validada_por'],
        {'uid': 'sup1', 'nombre': 'Laura Vega', 'fotoUrl': null});
    expect(cuerpo['observaciones_supervisor'], 'Buen trabajo');
    final cierre = cuerpo['fecha_cierre'] as String;
    expect(cierre, endsWith('Z'));                   // UTC, con aIso
    expect(DateTime.parse(cierre).isBefore(antes), isFalse);
    // El último mantenimiento del equipo NO va aquí: lo pone el trigger
    expect(cuerpo.keys, isNot(contains('ultimo_mantenimiento')));
  });

  // 6
  test('si falla la segunda subida no se inserta el reporte, y el reintento '
      'no vuelve a subir la primera', () async {
    almacen.fallarEnLlamada = 2;
    final bloc = nuevoBloc();
    addTearDown(bloc.close);

    final fallo = await publicar(bloc, fotos: [foto1, foto2]);
    expect(fallo.status, EstadoLlenarReporte.error);
    expect(fallo.mensajeError, contains('foto 2'));
    expect(reportes.creadas, isEmpty);               // nada insertado
    // La primera quedó subida y con su ruta guardada en el estado
    expect(fallo.fotos.first.subida, isTrue);
    expect(fallo.fotos.last.subida, isFalse);

    // Reintento: solo sube la que faltaba
    almacen.fallarEnLlamada = null;
    bloc.add(const ReportePublicado(tecnico));
    final fin = await bloc.stream
        .firstWhere((s) => s.status == EstadoLlenarReporte.publicado);
    expect(almacen.subidas, hasLength(2));
    expect(fin.fotos.every((f) => f.subida), isTrue);
    expect(reportes.creadas.single.evidencias, hasLength(2));
  });

  // ═══════════ Extras: límites y el flujo en pantalla ═══════════

  test('no se puede publicar con menos de 10 caracteres ni pasar de 4 fotos',
      () async {
    final bloc = nuevoBloc();
    addTearDown(bloc.close);

    bloc.add(const DetallesCambiados('corto'));
    for (var i = 0; i < 6; i++) {
      bloc.add(FotoAgregada(Uint8List.fromList([i]), 'jpg'));
    }
    bloc.add(const ReportePublicado(tecnico));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.fotos, hasLength(maxFotosPorReporte));   // tope de la base
    expect(bloc.state.puedeAgregarFoto, isFalse);
    expect(bloc.state.valido, isFalse);
    expect(reportes.creadas, isEmpty);
  });

  group('en pantalla', () {
    late FakeAuthService auth;
    late FakeUsuarioRepository usuarios;

    setUp(() {
      auth = FakeAuthService();
      usuarios = FakeUsuarioRepository();
      for (final (uid, nombre, rol) in [
        ('sup1', 'Laura Vega', RolUsuario.supervisor),
        ('tec1', 'Luis Pérez', RolUsuario.tecnico),
      ]) {
        auth.cuentas['$uid@planta.com'] = ('clave1234', uid);
        usuarios.perfiles[uid] = Usuario(
          uid: uid, nombre: nombre, email: '$uid@planta.com', rol: rol,
          plantaId: 'p1', estado: EstadoCuenta.activo,
          createdAt: DateTime(2026),
        );
      }
    });

    Orden sembrar({EstadoOrden estado = EstadoOrden.pendiente}) {
      final ahora = DateTime.now();
      final orden = Orden(
        id: 'o1', codigo: 'WO-2026-0001', plantaId: 'p1',
        titulo: 'Cambio de rodamientos', zonaNombre: 'Línea A',
        creadoPor: const UsuarioRef(uid: 'sup1', nombre: 'Laura Vega'),
        asignadoA: tecnico, asignadoAUid: 'tec1',
        estado: estado, createdAt: ahora,
        fechaLimite: ahora.add(const Duration(days: 1)),
        ultimaActividad: ahora,
      );
      ordenes.ordenes.add(orden);
      return orden;
    }

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
      final f = find.text(texto);
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    Future<void> entrarComo(WidgetTester tester, String uid) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(PlantaPulseApp(
        authBloc: authBlocDe(auth, usuarios),
        usuarioRepository: usuarios,
        plantaRepository: FakePlantaRepository(),
        ordenRepository: ordenes,
        equipoRepository: FakeEquipoRepository(),
        categoriaRepositorio: FakeCategoriaRepository(),
        zonaRepositorio: FakeZonaRepository(),
        reporteRepositorio: reportes,
        almacenamientoRepositorio: almacen,
      ));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), '$uid@planta.com');
      await tester.enterText(find.byType(TextField).at(1), 'clave1234');
      await tocar(tester, 'Iniciar Sesión');
    }

    probar('el técnico publica un reporte desde el detalle y aparece solo',
        (tester) async {
      sembrar();
      await entrarComo(tester, 'tec1');
      await tocar(tester, 'Cambio de rodamientos');
      expect(find.text('Aún no hay reportes de avance'), findsOneWidget);

      await tocar(tester, 'LLENAR REPORTE DE AVANCE');
      expect(find.text('Resumen de Intervención'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first,
          'Se cambiaron los rodamientos del eje principal');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('ENVIAR REPORTE'), 300,
          scrollable: find.byType(Scrollable).first);
      await tocar(tester, 'ENVIAR REPORTE');

      // De vuelta en el detalle: el reporte llegó por el stream
      expect(find.text('Resumen de Intervención'), findsNothing);
      expect(find.text('Se cambiaron los rodamientos del eje principal'),
          findsOneWidget);
      expect(find.text('Aún no hay reportes de avance'), findsNothing);
      expect(ordenes.mutaciones, 0);       // la orden la toca el servidor
    });

    probar('el supervisor valida y cierra una orden en "validando"',
        (tester) async {
      sembrar(estado: EstadoOrden.validando);
      reportes.creadas.add(Reporte(
        id: 'r1', ordenId: 'o1', autor: tecnico,
        detalles: 'Trabajo terminado, equipo probado',
        estadoTrabajo: EstadoTrabajo.resuelto,
        evidencias: [Evidencia(ruta: 'p1/o1/a.jpg',
            subidaEn: DateTime.now(), autorUid: 'tec1')],
        createdAt: DateTime.now(),
      ));
      await entrarComo(tester, 'sup1');
      await tocar(tester, 'Cambio de rodamientos');

      // Para una orden en validando, la acción es validar (no reportar)
      expect(find.text('LLENAR REPORTE DE AVANCE'), findsNothing);
      await tocar(tester, 'VALIDAR EVIDENCIA');
      expect(find.text('Validar Evidencia'), findsOneWidget);
      expect(find.text('Trabajo terminado, equipo probado'), findsOneWidget);

      // Devolver sin observaciones no se permite. El ListView es perezoso:
      // hay que bajar hasta los botones.
      await tester.scrollUntilVisible(find.text('SOLICITAR CORRECCIONES'), 300,
          scrollable: find.byType(Scrollable).first);
      await tocar(tester, 'SOLICITAR CORRECCIONES');
      expect(find.text('Escribe qué hay que corregir antes de devolver la orden.'),
          findsOneWidget);
      expect(ordenes.devolucion, isNull);

      await tocar(tester, 'APROBAR Y CERRAR ORDEN');
      expect(ordenes.cierre?.ordenId, 'o1');
      expect(ordenes.cierre?.validadaPor.uid, 'sup1');
      expect(find.text('Validar Evidencia'), findsNothing);   // volvió al detalle
    });
  });
}
