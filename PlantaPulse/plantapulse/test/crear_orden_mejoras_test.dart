// test/crear_orden_mejoras_test.dart
// Fotos del hallazgo al crear la orden, y ficha de equipo (ver, editar,
// dar de baja). La lista de equipos de P1 en una ventana de 5.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantapulse/main.dart';
import 'package:plantapulse/src/core/core.dart';
import 'package:plantapulse/src/core/data/models/orden_modelo.dart';
import 'package:plantapulse/src/features/crear_orden/crear_orden.dart';

import 'fakes.dart';

void main() {
  const supervisor = UsuarioRef(uid: 'sup1', nombre: 'Laura Vega');

  late FakeAuthService auth;
  late FakeUsuarioRepository usuarios;
  late FakeOrdenRepository ordenes;
  late FakeEquipoRepository equipos;
  late FakeCategoriaRepository categorias;
  late FakeZonaRepository zonas;
  late FakeAlmacenamientoRepository almacen;

  setUp(() {
    auth = FakeAuthService();
    usuarios = FakeUsuarioRepository();
    ordenes = FakeOrdenRepository();
    equipos = FakeEquipoRepository();
    categorias = FakeCategoriaRepository();
    zonas = FakeZonaRepository();
    almacen = FakeAlmacenamientoRepository();

    auth.cuentas['sup1@planta.com'] = ('clave1234', 'sup1');
    usuarios.perfiles['sup1'] = Usuario(
      uid: 'sup1', nombre: 'Laura Vega', email: 'sup1@planta.com',
      rol: RolUsuario.supervisor, plantaId: 'p1',
      estado: EstadoCuenta.activo, createdAt: DateTime(2026),
    );
    categorias.categorias.add(const Categoria(
        id: 'cat-mec', plantaId: 'p1', nombre: 'Mecánico', icono: 'llave'));
    zonas.zonas.addAll(const [
      Zona(id: 'zona-comp', plantaId: 'p1', nombre: 'Sección Compresores'),
      Zona(id: 'zona-emp', plantaId: 'p1', nombre: 'Línea de Empaque'),
    ]);
    equipos.nombresDeZona.addAll({
      'zona-comp': 'Sección Compresores',
      'zona-emp': 'Línea de Empaque',
    });
    equipos.equipos.add(const Equipo(
      id: 'eq-ga75', plantaId: 'p1', zonaId: 'zona-comp',
      zonaNombre: 'Sección Compresores', nombre: 'Compresor GA75',
      serial: 'AC-88291-K',
    ));
  });

  CrearOrdenBloc nuevoBloc() => crearOrdenBlocDe(
        categorias: categorias,
        equipos: equipos,
        usuarios: usuarios,
        ordenes: ordenes,
        almacen: almacen,
      );

  /// Arranca el asistente, llena lo mínimo y deja el Bloc listo.
  Future<CrearOrdenBloc> asistenteListo() async {
    final bloc = nuevoBloc();
    addTearDown(bloc.close);
    bloc.add(const CrearOrdenIniciada('p1'));
    await bloc.stream.firstWhere((s) => s.status == EstadoCrearOrden.listo);
    bloc.add(const DescripcionCambiada('Fuga de aceite en el sello del motor'));
    bloc.add(EquipoSeleccionado(equipos.equipos.first));
    // Los eventos se procesan después: se espera a que el paso 1 quede listo
    await bloc.stream.firstWhere((s) => s.paso1Valido);
    return bloc;
  }

  Future<CrearOrdenState> publicar(CrearOrdenBloc bloc) {
    bloc.add(const OrdenPublicada(supervisor));
    return bloc.stream.firstWhere((s) =>
        s.status == EstadoCrearOrden.publicada ||
        s.status == EstadoCrearOrden.error);
  }

  // ═══════════ Fotos del hallazgo ═══════════

  test('las fotos se suben ANTES de crear la orden, a la carpeta de su id',
      () async {
    final bloc = await asistenteListo();
    bloc.add(FotoHallazgoAgregada(Uint8List.fromList([1]), 'jpg'));
    bloc.add(FotoHallazgoAgregada(Uint8List.fromList([2]), 'jpg'));

    final fin = await publicar(bloc);
    expect(fin.status, EstadoCrearOrden.publicada);

    final orden = ordenes.creadas.single;
    // El id lo reservó la app, y las dos fotos están en SU carpeta
    expect(orden.id, 'ord-reservado-1');
    expect(fin.ordenIdCreada, 'ord-reservado-1');
    expect(almacen.subidas, hasLength(2));
    for (final ruta in almacen.subidas) {
      expect(ruta, startsWith('p1/ord-reservado-1/'));
    }
    // La orden nace ya con sus fotos (rutas, no URLs) y su portada
    expect(orden.evidencias.map((e) => e.ruta), almacen.subidas);
    expect(orden.evidencias.every((e) => e.autorUid == 'sup1'), isTrue);
    expect(orden.portadaUrl, almacen.subidas.last);
  });

  test('si una foto no sube, la orden no se crea; el reintento usa el mismo id '
      'y no repite la que ya subió', () async {
    almacen.fallarEnLlamada = 2;
    final bloc = await asistenteListo();
    bloc.add(FotoHallazgoAgregada(Uint8List.fromList([1]), 'jpg'));
    bloc.add(FotoHallazgoAgregada(Uint8List.fromList([2]), 'jpg'));

    final fallo = await publicar(bloc);
    expect(fallo.status, EstadoCrearOrden.error);
    expect(fallo.mensajeError, contains('La orden no se publicó'));
    expect(ordenes.creadas, isEmpty);                  // nada a medias

    almacen.fallarEnLlamada = null;
    final fin = await publicar(bloc);
    expect(fin.status, EstadoCrearOrden.publicada);
    expect(almacen.subidas, hasLength(2));             // solo subió la que faltaba
    expect(ordenes.creadas.single.id, 'ord-reservado-1');   // el mismo id
    expect(almacen.subidas.every((r) => r.startsWith('p1/ord-reservado-1/')),
        isTrue);
  });

  test('una orden sin fotos no envía la columna evidencias', () async {
    final bloc = await asistenteListo();
    await publicar(bloc);

    final orden = ordenes.creadas.single;
    expect(orden.evidencias, isEmpty);
    expect(orden.portadaUrl, isNull);
    // Así crear órdenes sin fotos funciona aunque la columna aún no exista
    final json = OrdenModelo.desdeEntidad(orden).toJson();
    expect(json.containsKey('evidencias'), isFalse);
    expect(json['id'], 'ord-reservado-1');
  });

  test('no se pasa de 4 fotos', () async {
    final bloc = await asistenteListo();
    for (var i = 0; i < 6; i++) {
      bloc.add(FotoHallazgoAgregada(Uint8List.fromList([i]), 'jpg'));
    }
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.fotos, hasLength(maxFotosPorReporte));
    expect(bloc.state.puedeAgregarFoto, isFalse);
  });

  // ═══════════ Equipos ═══════════

  test('editar el equipo elegido lo actualiza en la lista y en la selección',
      () async {
    final bloc = await asistenteListo();
    final editado = await EditarEquipo(equipos).ejecutar(const Equipo(
      id: 'eq-ga75', plantaId: 'p1', zonaId: 'zona-emp',
      nombre: 'Compresor GA75 (línea nueva)', serial: 'AC-88291-K',
    ));
    // La zona la resolvió el "servidor"
    expect(editado.zonaNombre, 'Línea de Empaque');

    bloc.add(EquipoActualizado(editado));
    final s = await bloc.stream.firstWhere(
        (s) => s.equipo?.nombre == 'Compresor GA75 (línea nueva)');
    expect(s.equipos.single.zonaNombre, 'Línea de Empaque');
  });

  test('dar de baja el equipo elegido lo saca de la lista y quita la selección',
      () async {
    final bloc = await asistenteListo();
    expect(bloc.state.paso1Valido, isTrue);

    await DarDeBajaEquipo(equipos).ejecutar('eq-ga75');
    bloc.add(const EquipoDadoDeBaja('eq-ga75'));
    final s = await bloc.stream.firstWhere((s) => s.equipos.isEmpty);

    expect(s.equipo, isNull);
    expect(s.paso1Valido, isFalse);           // no hay orden sobre un equipo de baja
    // No se borró: queda inactivo, y el asistente ya no lo ofrece
    expect(equipos.equipos.single.activo, isFalse);
    expect(await equipos.deLaPlanta('p1'), isEmpty);
  });

  // ═══════════ En pantalla ═══════════

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

  Future<void> abrirAsistente(WidgetTester tester) async {
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
      zonaRepositorio: zonas,
      reporteRepositorio: FakeReporteRepository(),
      almacenamientoRepositorio: almacen,
    ));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'sup1@planta.com');
    await tester.enterText(find.byType(TextField).at(1), 'clave1234');
    await tocar(tester, 'Iniciar Sesión');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
  }

  probar('la ficha del equipo deja editarlo y darlo de baja', (tester) async {
    await abrirAsistente(tester);
    expect(find.text('Compresor GA75'), findsOneWidget);

    // Ver: la ficha con sus datos
    await tester.tap(find.byTooltip('Ver detalle del equipo'));
    await tester.pumpAndSettle();
    expect(find.text('AC-88291-K'), findsOneWidget);
    expect(find.text('Sin registro'), findsOneWidget);   // último mantenimiento

    // Editar: cambia el nombre y la lista lo refleja sin reabrir nada
    await tocar(tester, 'EDITAR EQUIPO');
    expect(find.text('Editar equipo'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextField, 'Compresor GA75'), 'Compresor GA75-B');
    await tocar(tester, 'GUARDAR');
    expect(find.text('Compresor GA75-B'), findsWidgets);  // ficha y lista

    // Dar de baja: confirma, cierra la ficha y desaparece de la lista
    await tocar(tester, 'DAR DE BAJA');
    await tocar(tester, 'Dar de baja');
    expect(find.text('Compresor GA75-B dado de baja'), findsOneWidget);
    expect(find.text('No hay equipos activos en esta planta'), findsOneWidget);
    expect(equipos.equipos.single.activo, isFalse);
  });

  probar('la lista de equipos de P1 cabe en una ventana de 5 y se desliza',
      (tester) async {
    for (var i = 1; i <= 8; i++) {
      equipos.equipos.add(Equipo(
        id: 'eq-$i', plantaId: 'p1', zonaId: 'zona-emp',
        zonaNombre: 'Línea de Empaque', nombre: 'Empacadora $i',
      ));
    }
    await abrirAsistente(tester);

    // El ListView de la pantalla es perezoso: se baja hasta el aviso
    final aviso = find.text('9 equipos · desliza la lista o usa BUSCAR TODOS');
    await tester.scrollUntilVisible(aviso, 300,
        scrollable: find.byType(Scrollable).first);
    expect(aviso, findsOneWidget);
    // La lista interna mide como mucho 5 filas
    final lista = find.ancestor(
        of: find.text('Compresor GA75'), matching: find.byType(ListView)).first;
    expect(tester.getSize(lista).height, lessThanOrEqualTo(76.0 * 5));
    // Y el último equipo está dentro, al deslizarla
    await tester.drag(lista, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Empacadora 8'), findsOneWidget);
  });
}
