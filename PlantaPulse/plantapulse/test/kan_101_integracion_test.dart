
import 'package:flutter_test/flutter_test.dart';

import 'package:plantapulse/src/core/core.dart';
import 'package:plantapulse/src/features/auth/auth.dart';
import 'package:plantapulse/src/features/crear_orden/crear_orden.dart';
import 'package:plantapulse/src/features/ordenes/ordenes.dart';
import 'package:plantapulse/src/features/reportes/reportes.dart';

import 'fakes.dart';

void main() {
  group('KAN-101 - Pruebas de integración', () {

    test(
      'Flujo completo: autenticación, órdenes y reportes',
      () async {
        // Repositorios falsos para evitar usar Supabase real.
        final auth = FakeAuthService();
        final usuarios = FakeUsuarioRepository();
        final ordenes = FakeOrdenRepository();
        final reportes = FakeReporteRepository();

        // =====================================
        // 1. REGISTRO Y AUTENTICACIÓN
        // =====================================

        final registro = await RegistrarSolicitud(
          auth,
          usuarios,
        ).ejecutar(
          nombre: 'Anderson Técnico',
          email: 'tecnico@planta.com',
          password: 'clave12345',
        );

        // La cuenta debe quedar pendiente.
        expect(registro.estado, EstadoCuenta.pendiente);

        // La contraseña no debe guardarse en el perfil.
        for (final datos in usuarios.escrituras) {
          expect(datos.containsKey('password'), isFalse);
          expect(datos.values.contains('clave12345'), isFalse);
        }

        // El administrador aprueba la cuenta.
        await AprobarSolicitud(usuarios).ejecutar(
          registro.uid,
          rol: RolUsuario.tecnico,
          plantaId: 'p1',
          aprobadoPor: adminRef,
        );

        // Cerramos la sesión del registro.
        await CerrarSesion(auth).ejecutar();

        // Iniciamos sesión con la cuenta aprobada.
        final tecnico = await IniciarSesion(
          auth,
          usuarios,
        ).ejecutar(
          email: 'tecnico@planta.com',
          password: 'clave12345',
        );

        expect(tecnico.estado, EstadoCuenta.activo);
        expect(tecnico.rol, RolUsuario.tecnico);
        expect(tecnico.plantaId, 'p1');
        expect(auth.uidActual, tecnico.uid);

        // =====================================
        // 2. CREACIÓN DE ORDEN
        // =====================================

        final fecha = DateTime.utc(2026, 11, 23);

        final orden = Orden(
          id: ordenes.nuevoId(),
          codigo: 'WO-2026-101',
          plantaId: 'p1',
          titulo: 'Mantenimiento preventivo',
          descripcion: 'Inspección del motor principal',
          categoria: 'Mecánica',
          creadoPor: adminRef,
          asignadoA: UsuarioRef.desdeUsuario(tecnico),
          asignadoAUid: tecnico.uid,
          estado: EstadoOrden.pendiente,
          prioridad: Prioridad.media,
          createdAt: fecha,
          fechaLimite: fecha.add(
            const Duration(days: 2),
          ),
          ultimaActividad: fecha,
        );

        final ordenId = await PublicarOrden(
          ordenes,
        ).ejecutar(orden);

        expect(ordenId, isNotEmpty);
        expect(ordenes.creadas, hasLength(1));

        // =====================================
        // 3. CONSULTAR MIS TAREAS
        // =====================================

        final tareas = await ObservarMisTareas(
          ordenes,
        ).ejecutar(
          uid: tecnico.uid,
          plantaId: 'p1',
        ).first;

        expect(tareas, hasLength(1));
        expect(tareas.first.id, ordenId);
        expect(tareas.first.asignadoAUid, tecnico.uid);

        // La orden también debe aparecer en el feed.
        final feed = await ObservarOrdenesDePlanta(
          ordenes,
        ).ejecutar('p1').first;

        expect(
          feed.any((o) => o.id == ordenId),
          isTrue,
        );

        // =====================================
        // 4. PUBLICACIÓN DE REPORTE
        // =====================================

        final reporte = Reporte(
          id: '',
          ordenId: ordenId,
          autor: UsuarioRef.desdeUsuario(tecnico),
          detalles:
              'Se realizó la inspección y el mantenimiento '
              'preventivo del motor principal.',
          estadoTrabajo: EstadoTrabajo.resuelto,
          createdAt: fecha,
        );

        await PublicarReporte(
          reportes,
        ).ejecutar(reporte);

        // Comprobamos que el reporte se guardó.
        expect(reportes.creadas, hasLength(1));

        final historial = await reportes
            .deLaOrden(ordenId)
            .first;

        expect(historial, hasLength(1));
        expect(historial.first.ordenId, ordenId);
        expect(historial.first.autor.uid, tecnico.uid);
        expect(
          historial.first.estadoTrabajo,
          EstadoTrabajo.resuelto,
        );

        // Publicar un reporte no modifica directamente
        // el estado de la orden. Eso lo hace el servidor.
        expect(ordenes.mutaciones, 0);

        // =====================================
        // 5. VALIDACIÓN DEL SUPERVISOR
        // =====================================

        await CerrarOrden(ordenes).ejecutar(
          ordenId: ordenId,
          validadaPor: adminRef,
          observaciones: 'Trabajo revisado y aprobado',
        );

        expect(ordenes.cierre, isNotNull);
        expect(ordenes.cierre?.ordenId, ordenId);
        expect(
          ordenes.cierre?.validadaPor.uid,
          adminRef.uid,
        );

        // Se registró una operación de cierre.
        expect(ordenes.mutaciones, 1);

        // =====================================
        // 6. CIERRE DE SESIÓN
        // =====================================

        await CerrarSesion(auth).ejecutar();

        final sesion = await ComprobarSesion(
          auth,
          usuarios,
        ).ejecutar();

        expect(sesion, isNull);
        expect(auth.uidActual, isNull);
      },
    );

    // =========================================
    // PRUEBA 2: ERROR AL PUBLICAR REPORTE
    // =========================================

    test(
      'Si falla la publicación no se registra el reporte',
      () async {
        final reportes = FakeReporteRepository();
        final ordenes = FakeOrdenRepository();

        // Simulamos un error al publicar.
        reportes.fallarAlCrear = true;

        final reporte = Reporte(
          id: '',
          ordenId: 'orden-error',
          autor: const UsuarioRef(
            uid: 'tec1',
            nombre: 'Técnico',
          ),
          detalles:
              'Reporte de mantenimiento que no pudo publicarse.',
          estadoTrabajo: EstadoTrabajo.enProgreso,
          createdAt: DateTime.utc(2026, 11, 23),
        );

        await expectLater(
          PublicarReporte(reportes).ejecutar(reporte),
          throwsA(isA<FalloApp>()),
        );

        // No debe existir un reporte guardado.
        expect(reportes.creadas, isEmpty);

        // Tampoco se debe modificar la orden.
        expect(ordenes.mutaciones, 0);
      },
    );

    // =========================================
    // PRUEBA 3: AUTENTICACIÓN INCORRECTA
    // =========================================

    test(
      'No permite ingresar con contraseña incorrecta',
      () async {
        final auth = FakeAuthService();
        final usuarios = FakeUsuarioRepository();

        // Creamos una cuenta de prueba.
        await RegistrarSolicitud(
          auth,
          usuarios,
        ).ejecutar(
          nombre: 'Usuario de prueba',
          email: 'usuario@planta.com',
          password: 'correcta123',
        );

        await CerrarSesion(auth).ejecutar();

        // Intentamos iniciar con otra contraseña.
        await expectLater(
          IniciarSesion(
            auth,
            usuarios,
          ).ejecutar(
            email: 'usuario@planta.com',
            password: 'incorrecta123',
          ),
          throwsA(isA<FalloAutenticacion>()),
        );

        // No debe quedar una sesión activa.
        expect(auth.uidActual, isNull);
      },
    );
  });
}
