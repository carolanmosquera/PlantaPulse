// test/ordenes_flujo_test.dart
// Tajada 2: órdenes de trabajo con repositorios falsos en memoria.
// El flujo clave: el supervisor publica y la orden aparece en el feed
// por stream, sin Navigator.pop ni recarga.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantapulse/main.dart';
import 'package:plantapulse/src/core/core.dart';
import 'package:plantapulse/src/features/crear_orden/crear_orden.dart';
import 'package:plantapulse/src/features/ordenes/ordenes.dart';

import 'fakes.dart';

void main() {
  late FakeAuthService auth;
  late FakeUsuarioRepository usuarios;
  late FakeOrdenRepository ordenes;
  late FakeEquipoRepository equipos;
  late FakeCategoriaRepository categorias;
  late FakeZonaRepository zonas;

  const supervisor = UsuarioRef(uid: 'sup1', nombre: 'Laura Vega');

  void crearCuenta(String uid, String nombre, RolUsuario rol,
      {String especialidad = ''}) {
    auth.cuentas['$uid@planta.com'] = ('clave1234', uid);
    usuarios.perfiles[uid] = Usuario(
      uid: uid,
      nombre: nombre,
      email: '$uid@planta.com',
      rol: rol,
      especialidad: especialidad,
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
    zonas = FakeZonaRepository();

    // Desordenadas a propósito: el repositorio las entrega por nombre
    categorias.categorias.addAll(const [
      Categoria(id: 'cat-elec', plantaId: 'p1', nombre: 'Eléctrico', icono: 'rayo'),
      Categoria(id: 'cat-mec', plantaId: 'p1', nombre: 'Mecánico', icono: 'llave'),
      Categoria(id: 'cat-hid', plantaId: 'p1', nombre: 'Hidráulico', icono: 'gota'),
      Categoria(id: 'cat-otra', plantaId: 'p2', nombre: 'De otra planta'),
    ]);

    crearCuenta('sup1', 'Laura Vega', RolUsuario.supervisor);
    crearCuenta('tec1', 'Luis Pérez', RolUsuario.tecnico,
        especialidad: 'Mecánico');
    crearCuenta('tec2', 'Ana Ruiz', RolUsuario.tecnico,
        especialidad: 'Eléctrico');

    equipos.equipos.addAll(const [
      Equipo(
        id: 'eq-ga75',
        plantaId: 'p1',
        zonaId: 'zona-comp',
        zonaNombre: 'Sección Compresores',
        nombre: 'Compresor GA75',
        serial: 'AC-88291-K',
      ),
      Equipo(
        id: 'eq-otra',
        plantaId: 'p2',     // otra planta: no debe aparecer
        nombre: 'Equipo Ajeno',
      ),
    ]);
  });

  /// Una orden ya existente en la base de datos.
  Orden sembrar(String id, String titulo, {
    String codigo = 'WO-2026-0001',
    EstadoOrden estado = EstadoOrden.pendiente,
    Prioridad prioridad = Prioridad.media,
    String? asignadoA = 'tec1',          // null = orden sin asignar
    String zona = 'Línea A',
  }) {
    final ahora = DateTime.now();
    final orden = Orden(
      id: id,
      codigo: codigo,
      plantaId: 'p1',
      titulo: titulo,
      zonaNombre: zona,
      creadoPor: supervisor,
      asignadoA:
          asignadoA == null ? null : UsuarioRef(uid: asignadoA, nombre: asignadoA),
      asignadoAUid: asignadoA,
      estado: estado,
      prioridad: prioridad,
      createdAt: ahora,
      fechaLimite: ahora.add(const Duration(days: 1)),
      ultimaActividad: ahora,
    );
    ordenes.ordenes.add(orden);
    return orden;
  }

  /// Igual que en auth_flujo_test: ignora solo los avisos de desborde
  /// que provoca la fuente de pruebas (Ahem).
  void probar(String nombre, Future<void> Function(WidgetTester) cuerpo) {
    testWidgets(nombre, (tester) async {
      final original = FlutterError.onError;
      FlutterError.onError = (detalles) {
        if (detalles.toString().contains('overflowed')) return;
        original?.call(detalles);
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

  /// Arranca la app, pasa el splash e inicia sesión hasta el feed.
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
      zonaRepositorio: zonas,
    ));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '$uid@planta.com');
    await tester.enterText(find.byType(TextField).at(1), 'clave1234');
    await tocar(tester, 'Iniciar Sesión');
    expect(find.text('PlantaPulse Feed'), findsOneWidget);
  }

  Future<void> buscar(WidgetTester tester, String texto) async {
    await tester.enterText(find.byType(TextField).first, texto);
    await tester.pumpAndSettle();
  }

  /// Recorre el asistente completo como supervisor, con prioridad crítica.
  /// Con [conTecnico] en false la orden se publica sin responsable.
  Future<void> publicarOrden(WidgetTester tester, {bool conTecnico = true}) async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Crear Nueva Orden'), findsOneWidget);

    // P1: equipos de la planta, no los quemados ni los de otra planta
    expect(find.text('Compresor GA75'), findsOneWidget);
    expect(find.text('Sección Compresores • AC-88291-K'), findsOneWidget);
    expect(find.text('Equipo Ajeno'), findsNothing);

    await tester.enterText(
        find.byType(TextField).first, 'Fuga de aceite en sello del motor');
    await tocar(tester, 'Compresor GA75');
    await tocar(tester, 'Estructurar con IA');
    expect(find.text('Nueva Orden: Paso 2'), findsOneWidget);

    // P2: prioridad crítica y técnico responsable (opcional)
    await tocar(tester, 'CRÍTICA');
    if (conTecnico) {
      // El campo dice "Sin asignar" hasta elegir; abre el selector
      await tocar(tester, 'Sin asignar');
      await tester.tap(find.text('Luis Pérez').last);
      await tester.pumpAndSettle();
      expect(find.text('Luis Pérez • Mecánico'), findsOneWidget);
    }
    // El ListView de P2 es perezoso: hay que desplazarse hasta el botón
    await tester.scrollUntilVisible(find.text('PUBLICAR ORDEN'), 300,
        scrollable: find.byType(Scrollable).first);
    await tocar(tester, 'PUBLICAR ORDEN');
  }

  // 1
  probar('feed sin órdenes muestra el mensaje de planta vacía', (tester) async {
    await entrarComo(tester, 'tec1');
    expect(find.text('Aún no hay órdenes publicadas en esta planta'),
        findsOneWidget);
    expect(find.text('No hay órdenes que coincidan'), findsNothing);
  });

  // 2
  probar('un técnico activo NO ve el botón de crear orden', (tester) async {
    await entrarComo(tester, 'tec1');
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  // 3
  probar('un supervisor activo SÍ ve el botón de crear orden', (tester) async {
    await entrarComo(tester, 'sup1');
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  // 4
  probar('el supervisor publica y la orden aparece en el feed por stream',
      (tester) async {
    await entrarComo(tester, 'sup1');
    expect(find.text('Aún no hay órdenes publicadas en esta planta'),
        findsOneWidget);
    final consultasAntes = ordenes.consultas;

    await publicarOrden(tester);

    // De vuelta en el feed, sin historial del asistente
    expect(find.text('PlantaPulse Feed'), findsOneWidget);
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    expect(nav.canPop(), isFalse);

    // La orden llegó por la suscripción ya abierta, no por una consulta nueva
    expect(find.text('Fuga de aceite en sello del motor'), findsOneWidget);
    expect(find.text('Aún no hay órdenes publicadas en esta planta'),
        findsNothing);
    expect(ordenes.consultas, consultasAntes);
    expect(find.textContaining('publicada'), findsOneWidget);
  });

  // 5
  probar('la orden se guarda pendiente aunque la prioridad sea crítica',
      (tester) async {
    await entrarComo(tester, 'sup1');
    await publicarOrden(tester);
    final orden = ordenes.creadas.single;
    expect(orden.prioridad, Prioridad.critica);
    expect(orden.estado, EstadoOrden.pendiente);
  });

  // 6
  probar('la orden guarda la zona del equipo, no su código', (tester) async {
    await entrarComo(tester, 'sup1');
    await publicarOrden(tester);
    final orden = ordenes.creadas.single;
    expect(orden.zonaId, 'zona-comp');
    expect(orden.zonaNombre, 'Sección Compresores');
    expect(orden.equipoId, 'eq-ga75');
    expect(orden.equipoNombre, 'Compresor GA75');
    expect(orden.plantaId, 'p1');
    expect(orden.codigo, matches(RegExp(r'^WO-\d{4}-\d{4}$')));
  });

  // 7
  probar('la orden se asigna al técnico elegido, no al supervisor',
      (tester) async {
    await entrarComo(tester, 'sup1');
    await publicarOrden(tester);
    final orden = ordenes.creadas.single;
    expect(orden.asignadoA?.uid, 'tec1');
    expect(orden.asignadoA?.nombre, 'Luis Pérez');
    expect(orden.asignadoAUid, 'tec1');
    expect(orden.creadoPor.uid, 'sup1');
  });

  // 8
  probar('el chip "Pendiente" reduce la lista sin lanzar otra consulta',
      (tester) async {
    sembrar('o1', 'Cambio de rodamientos', estado: EstadoOrden.pendiente);
    sembrar('o2', 'Revisión de tablero', codigo: 'WO-2026-0002',
        estado: EstadoOrden.enProgreso);
    await entrarComo(tester, 'tec1');
    expect(find.text('Cambio de rodamientos'), findsOneWidget);
    expect(find.text('Revisión de tablero'), findsOneWidget);
    final consultasAntes = ordenes.consultas;

    await tocar(tester, 'Pendiente');
    expect(find.text('Cambio de rodamientos'), findsOneWidget);
    expect(find.text('Revisión de tablero'), findsNothing);
    expect(find.text('Mostrando 1 tarea para hoy'), findsOneWidget);
    expect(ordenes.consultas, consultasAntes);
  });

  // 9
  probar('el buscador filtra por título y por código', (tester) async {
    sembrar('o1', 'Cambio de rodamientos', codigo: 'WO-2026-0001');
    sembrar('o2', 'Revisión de tablero', codigo: 'WO-2026-0777');
    await entrarComo(tester, 'tec1');

    await buscar(tester, 'RODAMIENTOS');
    expect(find.text('Cambio de rodamientos'), findsOneWidget);
    expect(find.text('Revisión de tablero'), findsNothing);

    await buscar(tester, '0777');
    expect(find.text('Cambio de rodamientos'), findsNothing);
    expect(find.text('Revisión de tablero'), findsOneWidget);
  });

  // 10
  probar('búsqueda sin coincidencias muestra un mensaje distinto al vacío',
      (tester) async {
    sembrar('o1', 'Cambio de rodamientos');
    await entrarComo(tester, 'tec1');

    await buscar(tester, 'xyz no existe');
    expect(find.text('No hay órdenes que coincidan'), findsOneWidget);
    expect(find.text('Aún no hay órdenes publicadas en esta planta'),
        findsNothing);
  });

  // 11
  probar('"Mis Tareas" del técnico solo muestra las asignadas a él',
      (tester) async {
    sembrar('o1', 'Tarea de Luis', asignadoA: 'tec1');
    sembrar('o2', 'Tarea de Ana', asignadoA: 'tec2');
    await entrarComo(tester, 'tec1');
    // En el feed están las dos: es de toda la planta
    expect(find.text('Tarea de Luis'), findsOneWidget);
    expect(find.text('Tarea de Ana'), findsOneWidget);

    Navigator.of(tester.element(find.text('PlantaPulse Feed')))
        .pushNamed(Rutas.misTareas);
    await tester.pumpAndSettle();

    expect(find.text('Mis Tareas'), findsOneWidget);
    expect(find.text('Tarea de Luis'), findsOneWidget);
    expect(find.text('Tarea de Ana'), findsNothing);
    expect(find.text('ÓRDENES ASIGNADAS (1)'), findsOneWidget);
  });

  // 12
  probar('si el stream falla, la lista sigue visible y aparece el aviso',
      (tester) async {
    sembrar('o1', 'Cambio de rodamientos');
    await entrarComo(tester, 'tec1');
    expect(find.text('Cambio de rodamientos'), findsOneWidget);

    ordenes.fallar(Exception('unavailable'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudieron actualizar las órdenes'), findsOneWidget);
    expect(find.text('Cambio de rodamientos'), findsOneWidget);
  });

  // 13
  test('close() cancela la suscripción al stream', () async {
    sembrar('o1', 'Cambio de rodamientos');
    final bloc = ordenesBlocDe(ordenes);

    bloc.add(const OrdenesSuscritas('p1'));
    await bloc.stream.firstWhere((s) => s.status == EstadoOrdenes.listo);
    expect(ordenes.suscripcionesActivas, 1);
    expect(bloc.state.ordenes, hasLength(1));

    // Cambiar de consulta no deja la anterior viva
    bloc.add(const MisTareasSuscritas(plantaId: 'p1', uid: 'tec1'));
    await bloc.stream.firstWhere((s) => s.status == EstadoOrdenes.listo);
    expect(ordenes.suscripcionesActivas, 1);

    await bloc.close();
    expect(ordenes.suscripcionesActivas, 0);
  });

  // ═══════════ Catálogos y órdenes sin técnico ═══════════

  // 14
  probar('una orden publicada sin técnico llega sin responsable',
      (tester) async {
    await entrarComo(tester, 'sup1');
    await publicarOrden(tester, conTecnico: false);

    final orden = ordenes.creadas.single;
    expect(orden.asignadoA, isNull);
    expect(orden.asignadoAUid, isNull);
    // Y nace pendiente: "sin asignar" no es un estado
    expect(orden.estado, EstadoOrden.pendiente);
  });

  // 15
  test('copyWith(limpiarTecnico: true) deja el técnico en null', () {
    final tecnico = usuarios.perfiles['tec1']!;
    final conTecnico = CrearOrdenState.inicial().copyWith(tecnico: tecnico);
    expect(conTecnico.tecnico?.uid, 'tec1');

    // La trampa: `tecnico ?? this.tecnico` no puede volver a null
    expect(conTecnico.copyWith().tecnico?.uid, 'tec1');
    expect(conTecnico.copyWith(limpiarTecnico: true).tecnico, isNull);
    // Sin técnico el paso 2 sigue siendo válido si el 1 lo es
    expect(conTecnico.copyWith(limpiarTecnico: true).paso2Valido,
        conTecnico.paso1Valido);
  });

  // 16
  test('el filtro 4 del feed devuelve solo las órdenes sin asignar', () {
    sembrar('o1', 'Asignada a Luis', asignadoA: 'tec1');
    sembrar('o2', 'Nadie la tiene', codigo: 'WO-2026-0002', asignadoA: null);
    sembrar('o3', 'Tampoco', codigo: 'WO-2026-0003', asignadoA: null,
        estado: EstadoOrden.enProgreso);

    final estado = OrdenesState(
      status: EstadoOrdenes.listo,
      ordenes: ordenes.ordenes,
      filtro: 4,
    );
    expect(estado.visibles.map((o) => o.id), unorderedEquals(['o2', 'o3']));
  });

  // 17
  test('CrearOrdenIniciada carga las tres listas y marca la primera categoría',
      () async {
    final bloc = crearOrdenBlocDe(
      categorias: categorias,
      equipos: equipos,
      usuarios: usuarios,
      ordenes: ordenes,
    );
    addTearDown(bloc.close);

    bloc.add(const CrearOrdenIniciada('p1'));
    final listo =
        await bloc.stream.firstWhere((s) => s.status == EstadoCrearOrden.listo);

    // Solo las de la planta, por nombre
    expect(listo.categorias.map((c) => c.nombre),
        ['Eléctrico', 'Hidráulico', 'Mecánico']);
    expect(listo.equipos.map((e) => e.id), ['eq-ga75']);
    expect(listo.tecnicos.map((u) => u.uid), unorderedEquals(['tec1', 'tec2']));
    expect(listo.categoria, 'Eléctrico');
  });

  // 18
  test('crear una categoría la añade al estado y la selecciona', () async {
    final bloc = crearOrdenBlocDe(
      categorias: categorias,
      equipos: equipos,
      usuarios: usuarios,
      ordenes: ordenes,
    );
    addTearDown(bloc.close);
    bloc.add(const CrearOrdenIniciada('p1'));
    await bloc.stream.firstWhere((s) => s.status == EstadoCrearOrden.listo);

    // Lo mismo que hace el formulario: guardar y avisar al Bloc
    final crear = CrearCategoria(categorias);
    final creada = await crear.ejecutar(const Categoria(
        id: '', plantaId: 'p1', nombre: ' Neumático ', icono: 'engranaje',
        creadaPor: supervisor));
    bloc.add(CategoriaAgregada(creada));
    final despues =
        await bloc.stream.firstWhere((s) => s.categoria == 'Neumático');

    expect(despues.categorias.map((c) => c.nombre),
        ['Eléctrico', 'Hidráulico', 'Mecánico', 'Neumático']);

    // Repetirla con otras mayúsculas da el mensaje de duplicada
    await expectLater(
      crear.ejecutar(const Categoria(id: '', plantaId: 'p1', nombre: 'NEUMÁTICO')),
      throwsA(isA<FalloApp>().having((f) => f.mensaje, 'mensaje',
          'Ya existe una categoría con ese nombre.')),
    );
  });

  // 19 — flujo de la prueba manual, paso 4
  probar('registrar un equipo desde "BUSCAR TODOS" lo deja seleccionado',
      (tester) async {
    zonas.zonas.add(const Zona(
        id: 'zona-comp', plantaId: 'p1', nombre: 'Sección Compresores'));
    equipos.nombresDeZona['zona-comp'] = 'Sección Compresores';
    await entrarComo(tester, 'sup1');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tocar(tester, 'BUSCAR TODOS');
    expect(find.text('Equipos de la planta'), findsOneWidget);
    await tocar(tester, 'Registrar equipo nuevo');

    Future<void> llenar(String serial) async {
      await tester.enterText(
          find.widgetWithText(TextField, 'Ej: Compresor Atlas Copco GA75'),
          'Bomba de prueba');
      await tester.enterText(
          find.widgetWithText(TextField, 'Ej: AC-88291-K'), serial);
      await tocar(tester, 'Seleccionar zona');
      await tester.tap(find.text('Sección Compresores').last);
      await tester.pumpAndSettle();
      await tocar(tester, 'GUARDAR');
    }

    // Serial repetido: el mensaje lo dice y la hoja sigue abierta
    await llenar('AC-88291-K');
    expect(find.text('Ya hay un equipo con ese serial en esta planta.'),
        findsOneWidget);
    expect(find.text('Registrar equipo nuevo'), findsWidgets);

    // Serial nuevo: se guarda, se cierran las dos hojas y queda marcado
    await tester.enterText(
        find.widgetWithText(TextField, 'AC-88291-K'), 'BP-0001');
    await tocar(tester, 'GUARDAR');
    expect(find.text('Equipos de la planta'), findsNothing);
    final nuevo = equipos.equipos.singleWhere((e) => e.serial == 'BP-0001');
    expect(nuevo.zonaNombre, 'Sección Compresores');   // la puso el "servidor"
    expect(find.text('Bomba de prueba'), findsOneWidget);
    expect(find.text('Estructurar con IA'), findsOneWidget);
    // Seleccionado: el paso 1 ya es válido con la descripción
    await tester.enterText(
        find.byType(TextField).first, 'Fuga de aceite en sello del motor');
    await tocar(tester, 'Estructurar con IA');
    expect(find.text('Bomba de prueba'), findsOneWidget);   // la tarjeta de P2
  });

  // 20 — flujo de la prueba manual, pasos 7 y 8
  probar('"Asignar técnico" desde el detalle la saca de "Sin asignar" sola',
      (tester) async {
    sembrar('o1', 'Revisar compresor sin dueño', asignadoA: null);
    await entrarComo(tester, 'sup1');

    // La tarjeta lo dice donde iría el responsable
    expect(find.text('Sin asignar'), findsWidgets);
    await tocar(tester, 'Revisar compresor sin dueño');

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tocar(tester, 'Asignar técnico');
    await tester.tap(find.text('Luis Pérez').last);
    await tester.pumpAndSettle();

    // Sin recargar: el cambio llega por el stream
    expect(ordenes.ordenes.single.asignadoAUid, 'tec1');
    expect(find.text('Luis Pérez'), findsOneWidget);
  });
}
