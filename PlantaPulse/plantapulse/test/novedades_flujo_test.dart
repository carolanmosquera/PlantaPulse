import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantapulse/main.dart';
import 'package:plantapulse/src/core/core.dart';
import 'package:plantapulse/src/features/novedades/domain/repositories/novedad_repositorio.dart';

import 'fakes.dart';

void main() {
  late FakeAuthService auth;
  late FakeUsuarioRepository usuarios;
  late FakeOrdenRepository ordenes;
  late FakeAlmacenamientoRepository almacen;
  late _NovedadesFalsas novedades;

  Usuario cuenta(String uid, RolUsuario rol) => Usuario(
    uid: uid,
    nombre: uid == 'tec' ? 'Ana Ruiz' : 'Laura Vega',
    email: '$uid@planta.com',
    rol: rol,
    plantaId: 'p1',
    estado: EstadoCuenta.activo,
    createdAt: DateTime(2026),
  );

  setUp(() {
    auth = FakeAuthService();
    usuarios = FakeUsuarioRepository();
    ordenes = FakeOrdenRepository();
    almacen = FakeAlmacenamientoRepository();
    novedades = _NovedadesFalsas(ordenes);
    addTearDown(novedades.cerrar);

    for (final usuario in [
      cuenta('tec', RolUsuario.tecnico),
      cuenta('sup', RolUsuario.supervisor),
    ]) {
      usuarios.perfiles[usuario.uid] = usuario;
      auth.cuentas[usuario.email] = ('clave1234', usuario.uid);
    }
  });

  Future<void> tocar(WidgetTester tester, String texto) async {
    final buscador = find.text(texto);
    await tester.ensureVisible(buscador);
    await tester.tap(buscador);
    await tester.pumpAndSettle();
  }

  Future<void> entrar(WidgetTester tester, String uid) async {
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final equipos = FakeEquipoRepository()
      ..equipos.add(
        const Equipo(
          id: 'bomba',
          plantaId: 'p1',
          nombre: 'Bomba principal',
          zonaNombre: 'Línea A',
        ),
      );
    await tester.pumpWidget(
      PlantaPulseApp(
        authBloc: authBlocDe(auth, usuarios),
        usuarioRepository: usuarios,
        plantaRepository: FakePlantaRepository(),
        ordenRepository: ordenes,
        equipoRepository: equipos,
        categoriaRepositorio: FakeCategoriaRepository(),
        reporteRepositorio: FakeReporteRepository(),
        almacenamientoRepositorio: almacen,
        preferenciasRepositorio: PreferenciasFake(),
        novedadRepositorio: novedades,
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    // El login existente desborda con Ahem, la fuente de las pruebas.
    final errorLogin = tester.takeException();
    if (errorLogin != null) {
      expect(errorLogin.toString(), contains('A RenderFlex overflowed'));
    }
    await tester.enterText(find.byType(TextField).at(0), '$uid@planta.com');
    await tester.enterText(find.byType(TextField).at(1), 'clave1234');
    await tocar(tester, 'Iniciar Sesión');
  }

  Future<Novedad> sembrar({
    String descripcion = 'Falla',
    String plantaId = 'p1',
  }) => novedades.publicar(
    Novedad(
      id: novedades.nuevoId(),
      plantaId: plantaId,
      descripcion: descripcion,
      autor: usuarios.perfiles['tec']!.ref,
      createdAt: DateTime.now(),
    ),
  );

  testWidgets('una técnica publica con categoría y foto desde el feed', (
    tester,
  ) async {
    final foto = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==',
    );
    almacen.fotoDelDispositivo = FotoElegida(bytes: foto, extension: 'png');
    await sembrar(descripcion: 'Novedad de otra planta', plantaId: 'p2');
    await entrar(tester, 'tec');
    expect(find.text('Novedad de otra planta'), findsNothing);

    await tocar(tester, 'Reportar novedad');
    await tocar(tester, 'Categoría');
    await tocar(tester, 'Seguridad');
    await tester.enterText(find.byType(TextField), '  Luz! ');
    await tester.pumpAndSettle();
    final publicar = find.widgetWithText(BotonAncho, 'Publicar novedad');
    expect(tester.widget<BotonAncho>(publicar).onTap, isNull);
    expect(find.text('Escribe al menos 5 caracteres (falta 1).'), findsOneWidget);
    expect(
      find.text(
        'Para publicar, describe la novedad con al menos 5 caracteres.',
      ),
      findsOneWidget,
    );
    await tester.tap(publicar, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Reportar novedad'), findsOneWidget);
    expect(novedades.filas.values.where((n) => n.plantaId == 'p1'), isEmpty);

    await tester.enterText(find.byType(TextField), '  Luz rota ');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('novedad-requisitos')), findsNothing);
    expect(find.textContaining('Escribe al menos'), findsNothing);
    await tocar(tester, 'Agregar foto');
    await tocar(tester, 'Elegir de la galería');
    await tocar(tester, 'Publicar novedad');

    expect(find.text('PlantaPulse Feed'), findsOneWidget);
    expect(find.text('Luz rota'), findsOneWidget);
    final novedad = novedades.filas.values.singleWhere(
      (n) => n.plantaId == 'p1',
    );
    expect(novedad.descripcion, 'Luz rota');
    expect(novedad.autor.uid, 'tec');
    expect(novedad.categoria, CategoriaNovedad.seguridad);
    expect(novedad.evidencias.single.ruta, almacen.subidas.single);
  });

  testWidgets('sin categoría ni texto el formulario explica qué falta', (
    tester,
  ) async {
    await entrar(tester, 'tec');
    await tocar(tester, 'Reportar novedad');
    expect(
      find.text(
        'Para publicar, describe la novedad con al menos 5 caracteres '
        'y elige una categoría.',
      ),
      findsOneWidget,
    );
    // Solo espacios no cuentan como descripción.
    await tester.enterText(find.byType(TextField), '        ');
    await tester.pumpAndSettle();
    expect(find.text('Escribe al menos 5 caracteres (faltan 5).'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Fuga de aceite');
    await tester.pumpAndSettle();
    expect(find.text('Para publicar, elige una categoría.'), findsOneWidget);
    final publicar = find.widgetWithText(BotonAncho, 'Publicar novedad');
    expect(tester.widget<BotonAncho>(publicar).onTap, isNull);
    expect(novedades.filas, isEmpty);
  });

  testWidgets('lo que publica una técnica lo ve otra persona de la planta', (
    tester,
  ) async {
    await entrar(tester, 'tec');
    await tocar(tester, 'Reportar novedad');
    await tocar(tester, 'Categoría');
    await tocar(tester, 'Infraestructura');
    await tester.enterText(find.byType(TextField), 'Ventana agrietada');
    await tester.pumpAndSettle();
    await tocar(tester, 'Publicar novedad');
    expect(find.text('Ventana agrietada'), findsOneWidget);

    // Otra sesión, con otro rol, en la misma planta.
    await auth.salir();
    await tester.pumpWidget(const SizedBox());
    await entrar(tester, 'sup');
    expect(find.text('Ventana agrietada'), findsOneWidget);
    expect(find.textContaining('Infraestructura · REPORTADA'), findsOneWidget);
    expect(find.textContaining('Ana Ruiz · Hoy'), findsOneWidget);
  });

  testWidgets('el supervisor convierte y vuelve a la novedad vinculada', (
    tester,
  ) async {
    final novedad = await sembrar();
    await entrar(tester, 'sup');
    await tocar(tester, novedad.descripcion);
    await tocar(tester, 'Convertir en orden');
    expect(find.widgetWithText(TextField, novedad.descripcion), findsOneWidget);
    await tocar(tester, 'Bomba principal');
    await tocar(tester, 'Continuar');

    await tester.scrollUntilVisible(
      find.text('PUBLICAR ORDEN'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final publicar = find.widgetWithText(BotonAncho, 'PUBLICAR ORDEN');
    expect(tester.widget<BotonAncho>(publicar).onTap, isNull);
    await tocar(tester, 'Selecciona un técnico');
    await tocar(tester, 'Ana Ruiz');
    await tocar(tester, 'PUBLICAR ORDEN');

    expect(find.text('Detalle de novedad'), findsOneWidget);
    expect(find.text('CONVERTIDA'), findsOneWidget);
    final orden = ordenes.ordenes.single;
    expect(orden.titulo, novedad.descripcion);
    expect(orden.asignadoAUid, 'tec');
    expect(novedades.filas[novedad.id]!.ordenId, orden.id);
    await tocar(tester, 'Ver orden vinculada');
    expect(find.text('Orden #${orden.codigo}'), findsOneWidget);
  });

  testWidgets('el supervisor descarta con un motivo obligatorio', (
    tester,
  ) async {
    final novedad = await sembrar();
    await entrar(tester, 'sup');
    await tocar(tester, novedad.descripcion);
    await tocar(tester, 'Descartar novedad');

    final confirmar = find.widgetWithText(FilledButton, 'Confirmar descarte');
    expect(tester.widget<FilledButton>(confirmar).onPressed, isNull);
    await tester.enterText(find.byType(TextField), '  Ya se atendió ');
    await tester.pumpAndSettle();
    await tocar(tester, 'Confirmar descarte');

    expect(find.text('DESCARTADA'), findsOneWidget);
    expect(find.text('Ya se atendió'), findsOneWidget);
    expect(find.text('Convertir en orden'), findsNothing);
    expect(novedades.filas[novedad.id]!.motivoDescarte, 'Ya se atendió');
    expect(ordenes.ordenes, isEmpty);
  });

  testWidgets('una técnica puede leer una novedad pendiente de la planta', (
    tester,
  ) async {
    final novedad = await sembrar();
    await entrar(tester, 'tec');
    await tocar(tester, novedad.descripcion);
    expect(find.text('REPORTADA'), findsOneWidget);
    expect(find.text('Convertir en orden'), findsNothing);
    expect(find.text('Descartar novedad'), findsNothing);
  });
}

class _NovedadesFalsas implements NovedadRepositorio {
  final FakeOrdenRepository _ordenes;
  final filas = <String, Novedad>{};
  final _cambios = StreamController<void>.broadcast();
  int _siguiente = 0;

  _NovedadesFalsas(this._ordenes);

  Future<void> cerrar() => _cambios.close();

  @override
  String nuevoId() => 'nov-${++_siguiente}';

  @override
  Future<Novedad?> obtener(String id) async => filas[id];

  @override
  Stream<List<Novedad>> deLaPlanta(String plantaId) async* {
    List<Novedad> dePlanta() =>
        filas.values.where((novedad) => novedad.plantaId == plantaId).toList();
    yield dePlanta();
    yield* _cambios.stream.map((_) => dePlanta());
  }

  @override
  Future<Novedad> publicar(Novedad novedad) async {
    filas[novedad.id] = novedad;
    _cambios.add(null);
    return novedad;
  }

  @override
  Future<String> convertir(String id, Orden orden) async {
    final ordenId = await _ordenes.crear(orden);
    _revisar(id, EstadoNovedad.convertida, ordenId: ordenId);
    return ordenId;
  }

  @override
  Future<void> descartar(String id, String motivo) async =>
      _revisar(id, EstadoNovedad.descartada, motivo: motivo);

  void _revisar(
    String id,
    EstadoNovedad estado, {
    String? ordenId,
    String? motivo,
  }) {
    final novedad = filas[id]!;
    filas[id] = Novedad(
      id: id,
      plantaId: novedad.plantaId,
      descripcion: novedad.descripcion,
      categoria: novedad.categoria,
      autor: novedad.autor,
      evidencias: novedad.evidencias,
      estado: estado,
      ordenId: ordenId,
      motivoDescarte: motivo,
      createdAt: novedad.createdAt,
    );
    _cambios.add(null);
  }
}
