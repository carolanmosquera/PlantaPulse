import 'package:flutter_test/flutter_test.dart';
import 'package:plantapulse/src/core/core.dart';
import 'package:plantapulse/src/features/ordenes/ordenes.dart';

import 'fakes.dart';

void main() {
  final antigua = DateTime.utc(2020, 1, 1);
  Orden orden(
    String id,
    String planta,
    String equipo,
    String titulo,
    String descripcion, {
    bool eliminada = false,
  }) => Orden(
    id: id,
    codigo: id,
    plantaId: planta,
    equipoId: equipo,
    equipoNombre: equipo,
    titulo: titulo,
    descripcion: descripcion,
    creadoPor: const UsuarioRef(uid: 'sup', nombre: 'Supervisor'),
    estado: EstadoOrden.completada,
    createdAt: antigua,
    fechaLimite: antigua,
    ultimaActividad: antigua,
    eliminadaEn: eliminada ? antigua : null,
  );

  test(
    'busca descripción en órdenes antiguas y completadas, combinada con equipo',
    () async {
      final repo = FakeOrdenRepository();
      final equipos = FakeEquipoRepository();
      equipos.equipos.addAll([
        const Equipo(id: 'eq1', plantaId: 'p1', nombre: 'Bomba', activo: false),
        const Equipo(id: 'eq2', plantaId: 'p1', nombre: 'Motor'),
        const Equipo(id: 'eq3', plantaId: 'p2', nombre: 'Ajeno'),
      ]);
      repo.ordenes.addAll([
        orden('o1', 'p1', 'eq1', 'Revisión', 'Cavitación del impulsor'),
        orden('o2', 'p1', 'eq2', 'Ajuste', 'Cavitación de la línea'),
        orden('o3', 'p2', 'eq3', 'Ajena', 'Cavitación'),
        orden('o4', 'p1', 'eq1', 'Eliminada', 'Cavitación', eliminada: true),
      ]);
      final bloc = HistorialBloc(repo, equipos);
      addTearDown(bloc.close);
      bloc.add(const HistorialIniciado('p1'));
      final inicial = await bloc.stream.firstWhere(
        (s) => !s.cargando && s.plantaId == 'p1',
      );
      expect(inicial.equipos.map((e) => e.id), ['eq1', 'eq2']);
      expect(inicial.ordenes.map((o) => o.id), unorderedEquals(['o1', 'o2']));

      bloc.add(const HistorialBuscado('cavitación', null));
      final texto = await bloc.stream.firstWhere(
        (s) => !s.cargando && s.texto == 'cavitación',
      );
      expect(texto.ordenes.map((o) => o.id), unorderedEquals(['o1', 'o2']));

      bloc.add(const HistorialBuscado('cavitación', 'eq1'));
      final combinado = await bloc.stream.firstWhere(
        (s) => !s.cargando && s.equipoId == 'eq1',
      );
      expect(combinado.ordenes.map((o) => o.id), ['o1']);

      bloc.add(const HistorialBuscado('sin coincidencias', 'eq1'));
      final vacio = await bloc.stream.firstWhere(
        (s) => !s.cargando && s.texto == 'sin coincidencias',
      );
      expect(vacio.ordenes, isEmpty);
    },
  );

  test('carga páginas siguientes sin perder órdenes antiguas', () async {
    final repo = FakeOrdenRepository();
    for (var i = 0; i < 35; i++) {
      repo.ordenes.add(
        orden('o$i', 'p1', 'eq1', 'Mantenimiento', 'Rodamiento'),
      );
    }
    final bloc = HistorialBloc(repo, FakeEquipoRepository());
    addTearDown(bloc.close);
    bloc.add(const HistorialIniciado('p1'));
    final primera = await bloc.stream.firstWhere(
      (s) => !s.cargando && s.plantaId == 'p1',
    );
    expect(primera.ordenes, hasLength(30));
    expect(primera.hayMas, isTrue);
    bloc.add(const HistorialSiguientePagina());
    final segunda = await bloc.stream.firstWhere(
      (s) => !s.cargando && s.ordenes.length == 35,
    );
    expect(segunda.ordenes.map((o) => o.id).toSet(), hasLength(35));
    expect(segunda.hayMas, isFalse);
  });
}
