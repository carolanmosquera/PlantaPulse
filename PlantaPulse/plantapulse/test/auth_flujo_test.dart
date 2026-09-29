// test/auth_flujo_test.dart
// Ciclo completo de autenticación con servicios falsos:
// splash → login → registro → espera → aprobación → feed, y rechazo.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantapulse/main.dart';
import 'package:plantapulse/src/blocs/auth/auth_bloc.dart';
import 'package:plantapulse/src/models/usuario.dart';

import 'fakes.dart';

void main() {
  late FakeAuthService auth;
  late FakeUsuarioRepository repo;
  late FakePlantaRepository plantas;

  setUp(() {
    auth = FakeAuthService();
    repo = FakeUsuarioRepository();
    plantas = FakePlantaRepository();
  });

  /// testWidgets que ignora SOLO los avisos de desborde: la fuente de pruebas
  /// (Ahem) es mucho más ancha que la real y desborda filas de la maqueta
  /// que en el teléfono sí caben. Cualquier otro error sigue fallando.
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

  AuthBloc nuevoBloc() => AuthBloc(authService: auth, usuarioRepository: repo);

  /// Arranca la app y deja pasar el splash de 3 segundos.
  Future<void> arrancar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    // Una key nueva por arranque: simula cerrar y volver a abrir la app
    await tester.pumpWidget(PlantaPulseApp(
      key: UniqueKey(),
      authBloc: nuevoBloc(),
      usuarioRepository: repo,
      plantaRepository: plantas,
    ));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  Future<void> tocar(WidgetTester tester, String texto) async {
    final boton = find.text(texto);
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();
  }

  Future<void> registrarse(WidgetTester tester, String email) async {
    await tocar(tester, 'Registrar nuevo personal');
    final campos = find.byType(TextField);
    await tester.enterText(campos.at(0), 'Juan Pérez');
    await tester.enterText(campos.at(1), email);
    await tester.enterText(campos.at(2), 'secreta123');
    final casilla = find.byType(Checkbox);
    await tester.ensureVisible(casilla);
    await tester.tap(casilla);
    await tester.pumpAndSettle();
    await tocar(tester, 'COMPLETAR REGISTRO');
  }

  probar('sin sesión: splash 3 s → login', (tester) async {
    await arrancar(tester);
    expect(find.text('Acceso al Sistema'), findsOneWidget);
  });

  probar('contraseña equivocada: SnackBar en español, sigue en login',
      (tester) async {
    auth.cuentas['a@b.com'] = ('buena123', 'uidX');
    await arrancar(tester);

    await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextField).at(1), 'mala');
    await tocar(tester, 'Iniciar Sesión');

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(find.text('Acceso al Sistema'), findsOneWidget);
    // El botón vuelve a estar habilitado
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Ingresando...'), findsNothing);
  });

  probar('registro → espera → reabrir → espera → aprobado → feed',
      (tester) async {
    await arrancar(tester);
    await registrarse(tester, 'nuevo@planta.com');

    // Pantalla de espera, sin login en el historial
    expect(find.text('Solicitud enviada'), findsOneWidget);
    expect(find.text('nuevo@planta.com'), findsOneWidget);
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    expect(nav.canPop(), isFalse);

    // Perfil creado pendiente, técnico, sin planta y SIN contraseña
    final perfil = repo.perfiles.values.single;
    expect(perfil.estado, EstadoCuenta.pendiente);
    expect(perfil.rol, RolUsuario.tecnico);
    expect(perfil.plantaId, '');
    for (final doc in repo.escrituras) {
      expect(doc.keys.any((k) => k.toLowerCase().contains('pass')), isFalse);
      expect(doc.values.contains('secreta123'), isFalse);
    }

    // Reabrir la app: Firebase recuerda la sesión → espera, no login
    await arrancar(tester);
    expect(find.text('Solicitud enviada'), findsOneWidget);

    // Reintentar sin aprobación: se queda esperando
    await tocar(tester, 'Ya me aprobaron, reintentar');
    expect(find.text('Solicitud enviada'), findsOneWidget);

    // El admin aprueba y el usuario reintenta → feed
    await repo.aprobar(perfil.uid,
        rol: RolUsuario.supervisor, plantaId: 'p1', aprobadoPor: adminRef);
    await tocar(tester, 'Ya me aprobaron, reintentar');
    expect(find.text('PlantaPulse Feed'), findsOneWidget);
  });

  probar('cuenta rechazada ve "Acceso denegado" y puede cerrar sesión',
      (tester) async {
    await arrancar(tester);
    await registrarse(tester, 'otro@planta.com');
    await repo.rechazar(repo.perfiles.keys.single, adminRef);

    await tocar(tester, 'Ya me aprobaron, reintentar');
    expect(find.text('Acceso denegado'), findsOneWidget);
    expect(find.text('Ya me aprobaron, reintentar'), findsNothing);

    await tocar(tester, 'Cerrar sesión');
    expect(find.text('Acceso al Sistema'), findsOneWidget);

    // Al volver a entrar, sigue denegado
    await tester.enterText(find.byType(TextField).at(0), 'otro@planta.com');
    await tester.enterText(find.byType(TextField).at(1), 'secreta123');
    await tocar(tester, 'Iniciar Sesión');
    expect(find.text('Acceso denegado'), findsOneWidget);
  });

  probar('cuenta activa inicia sesión y entra al feed', (tester) async {
    auth.cuentas['admin@planta.com'] = ('admin1234', 'admin1');
    repo.perfiles['admin1'] = Usuario(
      uid: 'admin1',
      nombre: 'Admin',
      email: 'admin@planta.com',
      rol: RolUsuario.admin,
      plantaId: 'p1',
      estado: EstadoCuenta.activo,
      createdAt: DateTime(2026),
    );
    await arrancar(tester);

    await tester.enterText(find.byType(TextField).at(0), 'admin@planta.com');
    await tester.enterText(find.byType(TextField).at(1), 'admin1234');
    await tocar(tester, 'Iniciar Sesión');
    expect(find.text('PlantaPulse Feed'), findsOneWidget);
  });

  probar('cerrar sesión desde perfil cierra la sesión de verdad', (tester) async {
    auth.cuentas['sup@planta.com'] = ('clave1234', 'sup1');
    repo.perfiles['sup1'] = Usuario(
      uid: 'sup1',
      nombre: 'Sup',
      email: 'sup@planta.com',
      rol: RolUsuario.supervisor,
      plantaId: 'p1',
      estado: EstadoCuenta.activo,
      createdAt: DateTime(2026),
    );
    await arrancar(tester);
    await tester.enterText(find.byType(TextField).at(0), 'sup@planta.com');
    await tester.enterText(find.byType(TextField).at(1), 'clave1234');
    await tocar(tester, 'Iniciar Sesión');

    // Igual que el usuario: tocar "Perfil" en la barra inferior del feed
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Mi Perfil'), findsOneWidget);

    // Alertas y de vuelta a Perfil: "atrás" debe llevar al feed, sin historial
    await tester.tap(find.text('Alertas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Mi Perfil'), findsOneWidget);
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pop();
    await tester.pumpAndSettle();
    expect(find.text('PlantaPulse Feed'), findsOneWidget);
    expect(nav.canPop(), isFalse);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    // El ListView del perfil es perezoso: hay que desplazarse hasta el botón
    await tester.scrollUntilVisible(find.text('CERRAR SESIÓN'), 300,
        scrollable: find.byType(Scrollable).first);
    await tocar(tester, 'CERRAR SESIÓN');
    await tocar(tester, 'Salir');

    expect(find.text('Acceso al Sistema'), findsOneWidget);
    expect(auth.uidActual, isNull);

    // Al reabrir la app ya no hay sesión: va al login
    await arrancar(tester);
    expect(find.text('Acceso al Sistema'), findsOneWidget);
  });

  // ═══════════ Bandeja del admin (tarea 14) ═══════════

  void crearCuentaActiva(String uid, String email, RolUsuario rol) {
    auth.cuentas[email] = ('clave1234', uid);
    repo.perfiles[uid] = Usuario(
      uid: uid,
      nombre: 'Cuenta $uid',
      email: email,
      rol: rol,
      plantaId: 'p1',
      estado: EstadoCuenta.activo,
      createdAt: DateTime(2026),
    );
  }

  Future<void> entrar(WidgetTester tester, String email, String clave) async {
    await tester.enterText(find.byType(TextField).at(0), email);
    await tester.enterText(find.byType(TextField).at(1), clave);
    await tocar(tester, 'Iniciar Sesión');
  }

  /// Desde el feed: barra inferior → Perfil → Solicitudes de registro
  Future<void> abrirBandeja(WidgetTester tester) async {
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Solicitudes de registro'), 300,
        scrollable: find.byType(Scrollable).first);
    await tocar(tester, 'Solicitudes de registro');
  }

  Future<void> elegir(WidgetTester tester, String hint, String opcion) async {
    await tester.tap(find.text(hint));
    await tester.pumpAndSettle();
    await tester.tap(find.text(opcion).last);
    await tester.pumpAndSettle();
  }

  probar('ciclo completo: registro → admin aprueba desde la bandeja → entra',
      (tester) async {
    crearCuentaActiva('admin1', 'admin@planta.com', RolUsuario.admin);
    await arrancar(tester);

    // 1. Alguien se registra y cierra sesión
    await registrarse(tester, 'nuevo@planta.com');
    expect(find.text('Solicitud enviada'), findsOneWidget);
    await tocar(tester, 'Cerrar sesión');

    // 2. Entra el admin y abre la bandeja desde su perfil
    await entrar(tester, 'admin@planta.com', 'clave1234');
    await abrirBandeja(tester);
    expect(find.text('Juan Pérez'), findsOneWidget);

    // 3. Abre la solicitud: APROBAR deshabilitado hasta elegir rol y planta
    await tester.tap(find.text('Juan Pérez'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('APROBAR'));
    await tester.pumpAndSettle();
    expect(repo.perfiles.values.where((u) => u.estado == EstadoCuenta.pendiente),
        hasLength(1));

    await elegir(tester, 'Seleccionar rol', 'Técnico de Mantenimiento');
    // El admin no puede crear otros admins: no está en las opciones
    expect(find.text('Administrador'), findsNothing);
    await elegir(tester, 'Seleccionar planta', 'Planta Sur');
    await tocar(tester, 'APROBAR');

    // 4. Hoja cerrada, confirmación, bandeja vacía y perfil actualizado
    expect(find.textContaining('aprobado como'), findsOneWidget);
    expect(find.text('No hay solicitudes pendientes'), findsOneWidget);
    final aprobado = repo.perfiles.values
        .singleWhere((u) => u.email == 'nuevo@planta.com');
    expect(aprobado.estado, EstadoCuenta.activo);
    expect(aprobado.rol, RolUsuario.tecnico);
    expect(aprobado.plantaId, 'p2');
    expect(aprobado.aprobadoPor?.uid, 'admin1');

    // 5. El admin sale y la persona aprobada entra al feed
    Navigator.of(tester.element(find.text('No hay solicitudes pendientes')))
        .pop();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('CERRAR SESIÓN'), 300,
        scrollable: find.byType(Scrollable).first);
    await tocar(tester, 'CERRAR SESIÓN');
    await tocar(tester, 'Salir');
    await entrar(tester, 'nuevo@planta.com', 'secreta123');
    expect(find.text('PlantaPulse Feed'), findsOneWidget);
  });

  probar('el admin rechaza desde la bandeja → la cuenta ve Acceso denegado',
      (tester) async {
    crearCuentaActiva('admin1', 'admin@planta.com', RolUsuario.admin);
    await arrancar(tester);
    await registrarse(tester, 'otro@planta.com');
    await tocar(tester, 'Cerrar sesión');

    await entrar(tester, 'admin@planta.com', 'clave1234');
    await abrirBandeja(tester);
    await tester.tap(find.text('Juan Pérez'));
    await tester.pumpAndSettle();
    await tocar(tester, 'RECHAZAR');
    expect(find.textContaining('rechazada'), findsOneWidget);
    expect(find.text('No hay solicitudes pendientes'), findsOneWidget);

    Navigator.of(tester.element(find.text('No hay solicitudes pendientes')))
        .pop();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('CERRAR SESIÓN'), 300,
        scrollable: find.byType(Scrollable).first);
    await tocar(tester, 'CERRAR SESIÓN');
    await tocar(tester, 'Salir');
    await entrar(tester, 'otro@planta.com', 'secreta123');
    expect(find.text('Acceso denegado'), findsOneWidget);
  });

  probar('un técnico activo NO ve la bandeja en su perfil', (tester) async {
    crearCuentaActiva('tec1', 'tec@planta.com', RolUsuario.tecnico);
    await arrancar(tester);
    await entrar(tester, 'tec@planta.com', 'clave1234');
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Mi Perfil'), findsOneWidget);
    // Bajar hasta la sección de gestión: el ListView solo construye lo visible,
    // y sin esto la ausencia no probaría nada
    await tester.scrollUntilVisible(find.text('Ajustes de Cuenta'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Ajustes de Cuenta'), findsOneWidget);
    expect(find.text('Solicitudes de registro'), findsNothing);
  });
}
