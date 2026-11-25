// test/cola_reportes_test.dart
// KAN-98 · reportes sin conexión: si no hay señal al enviar, el reporte
// queda guardado en el teléfono y se envía solo después, sin duplicarse.
// La cola usa la implementación real sobre un almacenamiento en memoria.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantapulse/src/core/core.dart';
import 'package:plantapulse/src/core/data/data.dart';
import 'package:plantapulse/src/features/reportes/reportes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// Un servidor de reportes al que se le dice qué responder a cada envío.
class _Servidor implements ReporteRepositorio {
  /// null = acepta; si no, lanza ese error. Se consume en orden; vacío =
  /// acepta todo.
  final List<Object?> respuestas = [];
  final List<Reporte> recibidos = [];

  @override
  Future<void> crear(Reporte reporte) async {
    final r = respuestas.isEmpty ? null : respuestas.removeAt(0);
    if (r != null) throw r;
    recibidos.add(reporte);
  }

  @override
  Stream<List<Reporte>> deLaOrden(String ordenId) => const Stream.empty();
}

const tecnico = UsuarioRef(uid: 'tec1', nombre: 'Luis Pérez');

Reporte reporte(String detalles, {String id = '', String orden = 'o1'}) =>
    Reporte(
      id: id,
      ordenId: orden,
      autor: tecnico,
      detalles: detalles,
      createdAt: DateTime(2026, 11, 24, 10),
    );

void main() {
  late ColaReportesRepositorioImpl cola;
  late _Servidor servidor;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cola = ColaReportesRepositorioImpl(ColaReportesFuenteLocal());
    servidor = _Servidor();
  });

  group('la cola en el teléfono', () {
    test('guarda, lee en orden y quita; cada usuario tiene la suya', () async {
      await cola.guardar(reporte('primero', id: 'r1'));
      await cola.guardar(Reporte(
        id: 'r9',
        ordenId: 'o1',
        autor: const UsuarioRef(uid: 'otro', nombre: 'Otro'),
        detalles: 'de otra cuenta',
        createdAt: DateTime(2026, 11, 24, 9),
      ));
      await cola.guardar(reporte('segundo', id: 'r2'));
      await cola.guardar(reporte('primero', id: 'r1')); // repetido: una copia

      final mios = await cola.pendientes('tec1');
      expect(mios.map((r) => r.id), ['r1', 'r2']);
      expect(mios.first.detalles, 'primero');
      expect(mios.first.autor.nombre, 'Luis Pérez');

      await cola.quitar('tec1', 'r1');
      expect((await cola.pendientes('tec1')).map((r) => r.id), ['r2']);
      expect((await cola.pendientes('otro')).single.id, 'r9');
    });

    test('el id fijado por la app viaja al servidor; si no hay, no se manda',
        () {
      expect(ReporteModelo.desdeEntidad(reporte('x', id: 'r1')).toJson()['id'],
          'r1');
      expect(ReporteModelo.desdeEntidad(reporte('x')).toJson()
          .containsKey('id'), isFalse);
    });
  });

  group('publicar', () {
    test('con conexión se publica y no queda nada en cola', () async {
      final r = await PublicarReporte(servidor, cola: cola)
          .ejecutar(reporte('cambié el rodamiento'));
      expect(r, ResultadoPublicacion.publicado);
      expect(servidor.recibidos.single.id, isNotEmpty); // id fijado antes
      expect(await cola.pendientes('tec1'), isEmpty);
    });

    test('sin conexión queda en cola, con el mismo id del intento', () async {
      servidor.respuestas.add(const FalloRed());
      final r = await PublicarReporte(servidor, cola: cola)
          .ejecutar(reporte('cambié el rodamiento'));

      expect(r, ResultadoPublicacion.enCola);
      final guardado = (await cola.pendientes('tec1')).single;
      expect(guardado.detalles, 'cambié el rodamiento');
      expect(guardado.id, isNotEmpty);
    });

    test('sin cola (como antes) el error de red se propaga', () async {
      servidor.respuestas.add(const FalloRed());
      expect(() => PublicarReporte(servidor).ejecutar(reporte('x')),
          throwsA(isA<FalloRed>()));
    });

    test('un error que no es de red no se guarda: se muestra', () async {
      servidor.respuestas.add(const FalloPermisos());
      await expectLater(
          PublicarReporte(servidor, cola: cola).ejecutar(reporte('x')),
          throwsA(isA<FalloPermisos>()));
      expect(await cola.pendientes('tec1'), isEmpty);
    });
  });

  group('sincronizar', () {
    test('envía en orden y vacía la cola', () async {
      await cola.guardar(reporte('uno', id: 'r1'));
      await cola.guardar(reporte('dos', id: 'r2'));

      final r = await SincronizarReportesPendientes(servidor, cola)
          .ejecutar('tec1');
      expect(r.enviados, 2);
      expect(r.pendientes, 0);
      expect(servidor.recibidos.map((x) => x.id), ['r1', 'r2']);
      expect(await cola.pendientes('tec1'), isEmpty);
    });

    test('si ya había llegado (duplicado), sale de la cola sin repetirse',
        () async {
      await cola.guardar(reporte('uno', id: 'r1'));
      servidor.respuestas.add(const FalloDuplicado());

      final r = await SincronizarReportesPendientes(servidor, cola)
          .ejecutar('tec1');
      expect(r.enviados, 1);
      expect(servidor.recibidos, isEmpty);
      expect(await cola.pendientes('tec1'), isEmpty);
    });

    test('sin conexión se detiene y conserva el resto', () async {
      await cola.guardar(reporte('uno', id: 'r1'));
      await cola.guardar(reporte('dos', id: 'r2'));
      servidor.respuestas.addAll([null, const FalloRed()]);

      final r = await SincronizarReportesPendientes(servidor, cola)
          .ejecutar('tec1');
      expect(r.enviados, 1);
      expect(r.pendientes, 1);
      expect((await cola.pendientes('tec1')).single.id, 'r2');
    });

    test('si el servidor lo rechaza, sale de la cola con su motivo y no traba '
        'a los demás', () async {
      await cola.guardar(reporte('en orden invalidada', id: 'r1'));
      await cola.guardar(reporte('válido', id: 'r2'));
      servidor.respuestas.add(
          const FalloApp('La orden fue invalidada y ya no recibe reportes.'));

      final r = await SincronizarReportesPendientes(servidor, cola)
          .ejecutar('tec1');
      expect(r.rechazados,
          ['La orden fue invalidada y ya no recibe reportes.']);
      expect(r.enviados, 1);
      expect(servidor.recibidos.single.id, 'r2');
      expect(await cola.pendientes('tec1'), isEmpty);
    });
  });

  test('el bloc del reporte termina en "en cola" si no hay conexión',
      () async {
    servidor.respuestas.add(const FalloRed());
    final bloc = LlenarReporteBloc(
      subirEvidencia: SubirEvidencia(FakeAlmacenamientoRepository()),
      publicarReporte: PublicarReporte(servidor, cola: cola),
      redactarReporte: RedactarReporte(FakeIaRepositorio()),
      ordenId: 'o1',
      plantaId: 'p1',
    );
    addTearDown(bloc.close);
    bloc
      ..add(const DetallesCambiados('Cambié el rodamiento del motor'))
      ..add(const ReportePublicado(tecnico));
    final fin = await bloc.stream.firstWhere((s) =>
        s.status == EstadoLlenarReporte.enCola ||
        s.status == EstadoLlenarReporte.error ||
        s.status == EstadoLlenarReporte.publicado);
    expect(fin.status, EstadoLlenarReporte.enCola);
    expect((await cola.pendientes('tec1')).single.detalles,
        'Cambié el rodamiento del motor');
  });

  testWidgets('el aviso muestra los pendientes y "Reintentar" los envía',
      (tester) async {
    await tester.runAsync(() async {
      await cola.guardar(reporte('uno', id: 'r1'));
      await cola.guardar(reporte('dos', id: 'r2'));
    });
    // Primero no hay conexión: los dos se quedan
    servidor.respuestas.add(const FalloRed());

    final cubit = ColaReportesCubit(
      sincronizar: SincronizarReportesPendientes(servidor, cola),
      contar: ContarReportesPendientes(cola),
      intervalo: const Duration(hours: 1),
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: const AvisoReportesPendientes(),
        ),
      ),
    ));
    expect(find.byKey(const ValueKey('aviso-reportes-pendientes')),
        findsNothing);

    await tester.runAsync(() async {
      cubit.iniciar('tec1');
      await cubit.stream.firstWhere((s) => !s.sincronizando && s.pendientes > 0);
    });
    await tester.pump();
    expect(find.text('2 reportes sin enviar'), findsOneWidget);

    // Vuelve la señal: "Reintentar" los envía y el aviso desaparece
    await tester.tap(find.text('Reintentar'));
    await tester.runAsync(() =>
        cubit.stream.firstWhere((s) => !s.sincronizando && s.pendientes == 0));
    await tester.pump();
    expect(find.byKey(const ValueKey('aviso-reportes-pendientes')),
        findsNothing);
    expect(servidor.recibidos.map((r) => r.id), ['r1', 'r2']);
    expect(cubit.state.enviados, 2);

    await cubit.close();
  });
}
