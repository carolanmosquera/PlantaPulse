// test/resolver_alertas_datos_test.dart
// "Alerta solucionada" en la capa de datos: la fuente llama a la función
// resolver_alerta con lo que espera el servidor, y la bandeja deja de
// mostrar los avisos que el servidor archivó. Sin red: cliente HTTP falso.
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plantapulse/src/core/core.dart';
import 'package:plantapulse/src/features/notificaciones/data/datasources/avisos_fuente_supabase.dart';
import 'package:plantapulse/src/features/notificaciones/data/repositories/avisos_repositorio_impl.dart';
import 'package:plantapulse/src/features/novedades/data/datasources/alerta_critica_fuente_supabase.dart';
import 'package:plantapulse/src/features/novedades/data/repositories/alerta_critica_repositorio_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Un cliente de Supabase que no sale a la red.
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
        // postgrest lee response.request
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

/// La bandeja tal como llegaría por tiempo real, sin red.
class _FuenteAvisosFija extends AvisosFuenteSupabase {
  final List<Map<String, dynamic>> filas;

  _FuenteAvisosFija(this.filas);

  @override
  Stream<List<Map<String, dynamic>>> delUsuario(String usuarioId) =>
      Stream.value(filas);
}

Map<String, dynamic> fila(String id, {bool archivada = false}) => {
      'id': id,
      'usuario_id': 'sup1',
      'tipo': 'critica',
      'titulo': 'Alerta crítica: fuego',
      'descripcion': 'Incendio en bodega 3',
      'alerta_id': 'a1',
      'leida': archivada,
      'archivada': archivada,
      'created_at': '2026-11-24T10:00:00Z',
    };

void main() {
  test('la fuente llama a resolver_alerta con la alerta y la nota', () async {
    final peticiones = <http.Request>[];
    final repo = AlertaCriticaRepositorioImpl(AlertaCriticaFuenteSupabase(
        cliente: clienteFalso(peticiones, (_) => jsonResp(null))));

    await repo.resolver('a1', nota: '  Se apagó con extintor ');

    final p = peticiones.single;
    expect(p.url.path, '/rest/v1/rpc/resolver_alerta');
    expect(jsonDecode(p.body),
        {'p_alerta_id': 'a1', 'p_nota': 'Se apagó con extintor'});
  });

  test('el motivo que da el servidor llega tal cual a la pantalla', () async {
    final repo = AlertaCriticaRepositorioImpl(AlertaCriticaFuenteSupabase(
        cliente: clienteFalso([], (_) => jsonResp({
              'code': 'P0001',
              'message': 'La nota de cierre admite hasta 300 caracteres.',
            }, 400))));

    Object? error;
    try {
      await repo.resolver('a1', nota: 'x');
    } catch (e) {
      error = e;
    }
    expect(error, isA<FalloApp>());
    expect((error as FalloApp).mensaje,
        'La nota de cierre admite hasta 300 caracteres.');
  });

  test('sin permiso (42501) es un fallo de permisos con mensaje propio',
      () async {
    final repo = AlertaCriticaRepositorioImpl(AlertaCriticaFuenteSupabase(
        cliente: clienteFalso([], (_) => jsonResp(
            {'code': '42501', 'message': 'permission denied'}, 403))));

    Object? error;
    try {
      await repo.resolver('a1');
    } catch (e) {
      error = e;
    }
    expect(error, isA<FalloPermisos>());
    expect((error as FalloApp).mensaje, contains('supervisor o un administrador'));
  });

  test('la bandeja no muestra los avisos archivados', () async {
    final repo = AvisosRepositorioImpl(_FuenteAvisosFija([
      fila('n1'),
      fila('n2', archivada: true), // su alerta ya se solucionó
    ]));

    final avisos = await repo.delUsuario('sup1').first;
    expect(avisos.map((a) => a.id), ['n1']);
  });
}
