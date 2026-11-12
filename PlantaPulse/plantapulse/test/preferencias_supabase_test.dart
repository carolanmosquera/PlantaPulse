import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:plantapulse/src/core/core.dart';
import 'package:plantapulse/src/core/data/datasources/planta_fuente_supabase.dart';
import 'package:plantapulse/src/core/data/repositories/planta_repositorio_impl.dart';
import 'package:plantapulse/src/features/perfil/perfil.dart';
import 'package:plantapulse/src/features/perfil/data/datasources/preferencias_fuente_supabase.dart';
import 'package:plantapulse/src/features/perfil/data/repositories/preferencias_repositorio_impl.dart';

void main() {
  const espacio = 'plantapulse_preferencias';
  late sb.SupabaseClient cliente;
  late PreferenciasRepositorio repo;
  late Map<String, dynamic> usuario;
  late List<http.Request> peticiones;
  int estadoHttp = 200;
  bool confirmar = true;

  setUp(() {
    estadoHttp = 200;
    confirmar = true;
    peticiones = [];
    usuario = {
      'id': 'cuenta-a',
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'ana@example.com',
      'created_at': '2026-01-01T00:00:00Z',
      'app_metadata': {'provider': 'email'},
      'user_metadata': {
        'nombre': 'Ana',
        'otra_opcion': 7,
        espacio: {'opcion_futura': 'conservar'},
      },
    };
    cliente = sb.SupabaseClient(
      'https://prueba.supabase.co',
      'clave-publica-prueba',
      authOptions: const sb.AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((req) async {
        peticiones.add(req);
        Object respuesta = usuario;
        var codigo = 200;
        if (req.url.path.endsWith('/token')) {
          respuesta = {
            'access_token': 'token-de-prueba',
            'token_type': 'bearer',
            'expires_in': 3600,
            'refresh_token': 'refresh-de-prueba',
            'user': usuario,
          };
        } else if (req.url.path.endsWith('/user')) {
          expect(req.headers['Authorization'], 'Bearer token-de-prueba');
          codigo = estadoHttp;
          if (codigo != 200) {
            respuesta = {'msg': 'Solicitud rechazada'};
          } else if (req.method == 'PUT' && confirmar) {
            final body = jsonDecode(req.body) as Map<String, dynamic>;
            usuario = {
              ...usuario,
              'user_metadata': {
                ...usuario['user_metadata'] as Map<String, dynamic>,
                ...body['data'] as Map<String, dynamic>,
              },
            };
            respuesta = usuario;
          }
        } else if (req.url.path.endsWith('/plantas')) {
          respuesta = {
            'id': 'inactiva',
            'nombre': 'Planta histórica',
            'activo': false,
          };
        } else {
          fail('Petición inesperada: ${req.method} ${req.url}');
        }
        return http.Response(
          jsonEncode(respuesta),
          codigo,
          headers: {'content-type': 'application/json'},
          request: req,
        );
      }),
    );
    repo = PreferenciasRepositorioImpl(
      PreferenciasFuenteSupabase(auth: cliente.auth),
    );
    addTearDown(cliente.dispose);
  });

  Future<void> entrar() async {
    await cliente.auth.signInWithPassword(
      email: 'ana@example.com',
      password: 'solo-prueba',
    );
    peticiones.clear();
  }

  test(
    'lectura autenticada, valores iniciales y nueva lectura del servidor',
    () async {
      await entrar();
      expect(await repo.obtener('cuenta-a'), const PreferenciasUsuario());
      (usuario['user_metadata'] as Map)[espacio] = {
        'modo_offline': true,
        'modo_oscuro': 'true',
      };
      final actual = await repo.obtener('cuenta-a');
      expect(actual.modoOffline, isTrue);
      expect(actual.modoOscuro, isFalse);
      expect(peticiones.map((r) => r.method), ['GET', 'GET']);
    },
  );

  test(
    'cinco escrituras confirmadas, conserva metadatos y no cambia permisos ni credenciales',
    () async {
      await entrar();
      const claves = [
        'notificaciones_push',
        'alertas_mantenimiento',
        'solo_criticas',
        'modo_oscuro',
        'modo_offline',
      ];
      for (var i = 0; i < Preferencia.values.length; i++) {
        final campo = Preferencia.values[i];
        final valor = !const PreferenciasUsuario().valor(campo);
        final guardadas = await repo.cambiar('cuenta-a', campo, valor);
        expect(guardadas.valor(campo), valor);
        final req = peticiones.last;
        expect(req.method, 'PUT');
        final body = jsonDecode(req.body) as Map;
        expect(body.keys, ['data']);
        final data = body['data'] as Map;
        expect(data.keys, [espacio]);
        expect(data[espacio][claves[i]], valor);
        expect(data[espacio]['opcion_futura'], 'conservar');
      }
      final nueva = PreferenciasRepositorioImpl(
        PreferenciasFuenteSupabase(auth: cliente.auth),
      );
      expect(
        await nueva.obtener('cuenta-a'),
        const PreferenciasUsuario(
          notificacionesPush: false,
          alertasMantenimiento: false,
          soloCriticas: true,
          modoOscuro: true,
          modoOffline: true,
        ),
      );
      expect(usuario['user_metadata']['nombre'], 'Ana');
      expect(usuario['user_metadata']['otra_opcion'], 7);
      expect(usuario['role'], 'authenticated');
      expect(usuario['email'], 'ana@example.com');
      expect(usuario['app_metadata'], {'provider': 'email'});
    },
  );

  test('sin sesión o con otra cuenta no consulta ni escribe', () async {
    await expectLater(
      repo.obtener('cuenta-a'),
      throwsA(isA<FalloAutenticacion>()),
    );
    expect(peticiones, isEmpty);
    await entrar();
    await expectLater(
      repo.cambiar('cuenta-b', Preferencia.modoOscuro, true),
      throwsA(isA<FalloAutenticacion>()),
    );
    expect(peticiones, isEmpty);
  });

  test(
    'rechazo del servidor no se convierte en preferencias iniciales',
    () async {
      await entrar();
      estadoHttp = 403;
      await expectLater(
        repo.obtener('cuenta-a'),
        throwsA(isA<FalloAutenticacion>()),
      );
      await expectLater(
        repo.cambiar('cuenta-a', Preferencia.modoOscuro, true),
        throwsA(isA<FalloAutenticacion>()),
      );
      expect(peticiones.every((r) => r.method == 'GET'), isTrue);
    },
  );

  test('respuesta sin el valor solicitado no confirma el guardado', () async {
    await entrar();
    confirmar = false;
    await expectLater(
      repo.cambiar('cuenta-a', Preferencia.modoOscuro, true),
      throwsA(isA<FalloApp>()),
    );
  });

  test('la planta asignada se obtiene por id aunque esté inactiva', () async {
    final plantas = PlantaRepositorioImpl(
      PlantaFuenteSupabase(cliente: cliente),
    );
    final planta = await plantas.obtener('inactiva');
    expect(planta!.nombre, 'Planta histórica');
    expect(planta.activo, isFalse);
    expect(peticiones.single.url.queryParameters['id'], 'eq.inactiva');
    expect(
      peticiones.single.url.queryParameters.containsKey('activo'),
      isFalse,
    );
  });
}
