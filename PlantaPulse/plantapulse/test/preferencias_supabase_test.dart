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
import 'fakes.dart';

class _UsuariosConAvisos extends FakeUsuarioRepository {
  @override
  Future<void> actualizar(String uid, Map<String, dynamic> cambios) async {
    perfiles[uid] = perfiles[uid]!.copyWith(
      preferenciasAvisos: PreferenciasAvisos.fromJson(
        cambios['preferenciasAvisos'],
      ),
    );
  }
}

void main() {
  const espacio = 'plantapulse_preferencias';
  late sb.SupabaseClient cliente;
  late PreferenciasRepositorio repo;
  late _UsuariosConAvisos usuarios;
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
    usuarios = _UsuariosConAvisos();
    usuarios.perfiles['cuenta-a'] = Usuario(
      uid: 'cuenta-a',
      nombre: 'Ana',
      email: 'ana@example.com',
      rol: RolUsuario.tecnico,
      plantaId: 'p1',
      estado: EstadoCuenta.activo,
      createdAt: DateTime(2026),
    );
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
      usuarios,
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
    'los avisos de usuarios prevalecen sobre metadatos antiguos de Auth',
    () async {
      await entrar();
      (usuario['user_metadata'] as Map)[espacio] = {
        'notificaciones_push': false,
        'alertas_mantenimiento': false,
        'solo_criticas': true,
        'modo_oscuro': true,
      };
      final leidas = await repo.obtener('cuenta-a');
      expect(leidas.notificacionesPush, isTrue);
      expect(leidas.alertasMantenimiento, isTrue);
      expect(leidas.soloCriticas, isFalse);
      expect(leidas.modoOscuro, isTrue);

      final guardadas = await repo.cambiar(
        'cuenta-a',
        Preferencia.notificacionesPush,
        false,
      );
      expect(guardadas.notificacionesPush, isFalse);
      expect(usuarios.perfiles['cuenta-a']!.preferenciasAvisos.push, isFalse);
      expect(peticiones.where((r) => r.method == 'PUT'), isEmpty);
      expect(usuario['user_metadata'][espacio]['notificaciones_push'], isFalse);
    },
  );

  test(
    'cinco escrituras confirmadas en sus fuentes respectivas y sin cambiar credenciales',
    () async {
      await entrar();
      const claves = ['modo_oscuro', 'modo_offline'];
      for (var i = 0; i < Preferencia.values.length; i++) {
        final campo = Preferencia.values[i];
        final valor = !const PreferenciasUsuario().valor(campo);
        final guardadas = await repo.cambiar('cuenta-a', campo, valor);
        expect(guardadas.valor(campo), valor);
        if (i < 3) {
          expect(peticiones.last.method, 'GET');
        } else {
          final put = peticiones.where((r) => r.method == 'PUT').last;
          final body = jsonDecode(put.body) as Map;
          expect(body.keys, ['data']);
          final data = body['data'] as Map;
          expect(data.keys, [espacio]);
          expect(data[espacio][claves[i - 3]], valor);
          expect(data[espacio]['opcion_futura'], 'conservar');
        }
      }
      final nueva = PreferenciasRepositorioImpl(
        PreferenciasFuenteSupabase(auth: cliente.auth),
        usuarios,
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
