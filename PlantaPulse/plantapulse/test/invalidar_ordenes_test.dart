// test/invalidar_ordenes_test.dart
// "Invalidar orden" (solo admin) en la capa de datos: la fuente llama a
// invalidar_orden con lo que espera el servidor, y el repositorio saca las
// invalidadas del feed y de Mis Tareas pero las deja en el Historial y
// al abrirlas por su id. Sin red: cliente HTTP falso y fuente fija.
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plantapulse/src/core/core.dart';
import 'package:plantapulse/src/features/ordenes/data/datasources/orden_fuente_supabase.dart';
import 'package:plantapulse/src/features/ordenes/data/repositories/orden_repositorio_impl.dart';
import 'package:plantapulse/src/features/ordenes/ordenes.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'fakes.dart';

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

http.Response jsonResp(Object? cuerpo, [int status = 200]) => http.Response(
      jsonEncode(cuerpo),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> fila(String id, {bool invalidada = false}) => {
      'id': id,
      'codigo': 'WO-2026-$id',
      'planta_id': 'p1',
      'titulo': 'Orden $id',
      'creado_por': {'uid': 'sup1', 'nombre': 'Laura Vega'},
      'asignado_a': {'uid': 'tec1', 'nombre': 'Luis Pérez'},
      'asignado_a_uid': 'tec1',
      'estado': 'en_progreso',
      'prioridad': 'media',
      'created_at': '2026-11-20T10:00:00Z',
      'fecha_limite': '2026-11-30T10:00:00Z',
      'ultima_actividad': '2026-11-20T10:00:00Z',
      if (invalidada) ...{
        'invalidada_en': '2026-11-24T18:00:00Z',
        'invalidada_por': {'uid': 'adm1', 'nombre': 'Admin Planta'},
        'motivo_invalidacion': 'Reporte de prueba',
      },
    };

/// Las mismas filas para el stream, el historial y obtener(): sin red.
class _FuenteFija extends OrdenFuenteSupabase {
  final List<Map<String, dynamic>> filas;

  _FuenteFija(this.filas)
      : super(cliente: sb.SupabaseClient('https://x.supabase.co', 'k'));

  @override
  Stream<List<Map<String, dynamic>>> dePlanta(
    String plantaId,
    String columnaOrden, {
    required bool ascendente,
  }) =>
      Stream.value(filas);

  @override
  Future<Map<String, dynamic>?> obtener(String ordenId) async =>
      filas.where((f) => f['id'] == ordenId).firstOrNull;

  @override
  Future<List<Map<String, dynamic>>> buscarHistorial({
    required String plantaId,
    required String texto,
    String? equipoId,
    required int desde,
    required int limite,
  }) async =>
      filas;
}

void main() {
  test('la fuente llama a invalidar_orden con la orden y el motivo', () async {
    final peticiones = <http.Request>[];
    final repo = OrdenRepositorioImpl(OrdenFuenteSupabase(
        cliente: clienteFalso(peticiones, (_) => jsonResp(null))));

    await repo.invalidar('o1', '  Reporte de prueba ');

    final p = peticiones.single;
    expect(p.url.path, '/rest/v1/rpc/invalidar_orden');
    expect(jsonDecode(p.body),
        {'p_orden_id': 'o1', 'p_motivo': 'Reporte de prueba'});
  });

  test('si no es admin, el mensaje del servidor llega como fallo de permisos',
      () async {
    final repo = OrdenRepositorioImpl(OrdenFuenteSupabase(
        cliente: clienteFalso([], (_) => jsonResp({
              'code': '42501',
              'message': 'Solo un administrador puede invalidar órdenes.',
            }, 403))));

    Object? error;
    try {
      await repo.invalidar('o1', 'Reporte de prueba');
    } catch (e) {
      error = e;
    }
    expect(error, isA<FalloPermisos>());
  });

  group('dónde se ve una orden invalidada', () {
    final repo = OrdenRepositorioImpl(_FuenteFija([
      fila('o1'),
      fila('o2', invalidada: true),
    ]));

    test('no sale en el feed ni en Mis Tareas', () async {
      final feed = await repo.deLaPlanta('p1').first;
      expect(feed.map((o) => o.id), ['o1']);
      final mias = await repo.asignadasA('tec1', 'p1').first;
      expect(mias.map((o) => o.id), ['o1']);
    });

    test('sí sale en el Historial, con quién la invalidó y por qué', () async {
      final historial = await repo.buscarHistorial(
          plantaId: 'p1', texto: '', desde: 0, limite: 30);
      final invalidada = historial.singleWhere((o) => o.id == 'o2');
      expect(invalidada.invalidada, isTrue);
      expect(invalidada.invalidadaPor?.nombre, 'Admin Planta');
      expect(invalidada.motivoInvalidacion, 'Reporte de prueba');
    });

    test('se puede abrir por su id (p. ej. desde un aviso)', () async {
      final orden = await repo.obtener('o2');
      expect(orden?.invalidada, isTrue);
    });
  });

  test('sin motivo (menos de 5 caracteres) no llega al servidor', () async {
    final ordenes = FakeOrdenRepository();
    Object? error;
    try {
      await InvalidarOrden(ordenes).ejecutar('o1', ' no ');
    } catch (e) {
      error = e;
    }
    expect(error, isA<FalloApp>());
    expect(ordenes.invalidaciones, isEmpty);
  });
}
