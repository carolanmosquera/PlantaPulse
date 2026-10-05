// test/ordenes_flujo_test.dart
// Tajada 2: órdenes de trabajo con repositorios falsos en memoria.
// El flujo clave: el supervisor publica y la orden aparece en el feed
// por stream, sin Navigator.pop ni recarga.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantapulse/main.dart';
import 'package:plantapulse/src/core/core.dart';
import 'package:plantapulse/src/features/ordenes/ordenes.dart';

import 'fakes.dart';

void main() {
  late FakeAuthService auth;
  late FakeUsuarioRepository usuarios;
  late FakeOrdenRepository ordenes;
  late FakeEquipoRepository equipos;

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

  /// Una orden ya existente en Firestore.
  Orden sembrar(String id, String titulo, {
    String codigo = 'WO-2026-0001',
    EstadoOrden estado = EstadoOrden.pendiente,
    Prioridad prioridad = Prioridad.media,
    String asignadoA = 'tec1',
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
      asignadoA: UsuarioRef(uid: asignadoA, nombre: asignadoA),
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
  Future<void> publicarOrden(WidgetTester tester) async {
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

    // P2: prioridad crítica y técnico responsable
    await tocar(tester, 'CRÍTICA');
    await tocar(tester, 'Seleccionar técnico');
    await tester.tap(find.text('Luis Pérez • Mecánico').last);
    await tester.pumpAndSettle();
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
    final doc = ordenes.escrituras.single;
    expect(doc['prioridad'], 'critica');
    expect(doc['estado'], 'pendiente');
  });

  // 6
  probar('la orden guarda la zona del equipo, no su código', (tester) async {
    await entrarComo(tester, 'sup1');
    await publicarOrden(tester);
    final doc = ordenes.escrituras.single;
    expect(doc['zonaId'], 'zona-comp');
    expect(doc['zonaNombre'], 'Sección Compresores');
    expect(doc['equipoId'], 'eq-ga75');
    expect(doc['equipoNombre'], 'Compresor GA75');
    expect(doc['plantaId'], 'p1');
    expect(doc['codigo'], matches(RegExp(r'^WO-\d{4}-\d{4}$')));
  });

  // 7
  probar('la orden se asigna al técnico elegido, no al supervisor',
      (tester) async {
    await entrarComo(tester, 'sup1');
    await publicarOrden(tester);
    final doc = ordenes.escrituras.single;
    expect((doc['asignadoA'] as Map)['uid'], 'tec1');
    expect((doc['asignadoA'] as Map)['nombre'], 'Luis Pérez');
    expect(doc['asignadoAUid'], 'tec1');
    expect((doc['creadoPor'] as Map)['uid'], 'sup1');
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
}
