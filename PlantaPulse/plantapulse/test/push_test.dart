// test/push_test.dart
// KAN-96: el token de notificaciones se guarda, se actualiza y se borra
// del perfil al cerrar sesión. Sin Firebase: el push es un doble en memoria.
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantapulse/src/core/core.dart';
import 'package:plantapulse/src/features/auth/auth.dart';
import 'package:plantapulse/src/features/notificaciones/notificaciones.dart';

import 'fakes.dart';

class FakePush implements PushRepositorio {
  String? token = 'token-1';
  bool desactivado = false;
  final renovaciones = StreamController<String>.broadcast();
  final tocadas = StreamController<String>.broadcast();

  @override
  Future<String?> activar() async => token;

  @override
  Stream<String> get tokenRenovado => renovaciones.stream;

  @override
  Future<void> desactivar() async => desactivado = true;

  @override
  Future<String?> ordenQueAbrioLaApp() async => null;

  @override
  Stream<String> get ordenesTocadas => tocadas.stream;
}

/// Solo registra lo que se escribe en el campo del token.
class UsuariosTokens implements UsuarioRepositorio {
  final Map<String, String?> tokens = {};
  final List<String> pasos = [];

  @override
  Future<void> guardarTokenPush(String uid, String token) async {
    tokens[uid] = token;
    pasos.add('guardar $token');
  }

  @override
  Future<void> borrarTokenPush(String uid) async {
    tokens[uid] = null;
    pasos.add('borrar');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('al iniciar guarda el token en el perfil del usuario', () async {
    final usuarios = UsuariosTokens();
    await SincronizarTokenPush(FakePush(), usuarios).iniciar('u1');
    expect(usuarios.tokens['u1'], 'token-1');
  });

  test('sin permiso de notificaciones no escribe nada', () async {
    final usuarios = UsuariosTokens();
    await SincronizarTokenPush(FakePush()..token = null, usuarios)
        .iniciar('u1');
    expect(usuarios.pasos, isEmpty);
  });

  test('cuando el token cambia, el perfil se actualiza', () async {
    final push = FakePush();
    final usuarios = UsuariosTokens();
    await SincronizarTokenPush(push, usuarios).iniciar('u1');

    push.renovaciones.add('token-2');
    await pumpEventQueue();

    expect(usuarios.tokens['u1'], 'token-2');
  });

  test('detener borra el token del perfil y del dispositivo', () async {
    final push = FakePush();
    final usuarios = UsuariosTokens();
    final sincronizar = SincronizarTokenPush(push, usuarios);
    await sincronizar.iniciar('u1');

    await sincronizar.detener();
    push.renovaciones.add('token-tarde');
    await pumpEventQueue();

    expect(usuarios.tokens['u1'], isNull);
    expect(push.desactivado, isTrue);
    expect(usuarios.pasos.last, 'borrar'); // ya no escucha renovaciones
  });

  test('cerrar sesión borra el token ANTES de salir (después RLS no deja)',
      () async {
    final auth = FakeAuthService();
    final pasos = <String>[];
    final cerrar = CerrarSesion(_AuthQueAnota(auth, pasos),
        antesDeSalir: () async => pasos.add('borrar token'));

    await cerrar.ejecutar();

    expect(pasos, ['borrar token', 'salir']);
  });

  test('si borrar el token falla, la sesión se cierra igual', () async {
    final pasos = <String>[];
    final cerrar = CerrarSesion(_AuthQueAnota(FakeAuthService(), pasos),
        antesDeSalir: () async => throw Exception('sin red'));

    await cerrar.ejecutar();

    expect(pasos, ['salir']);
  });
}

class _AuthQueAnota implements AutenticacionRepositorio {
  final FakeAuthService _real;
  final List<String> _pasos;
  _AuthQueAnota(this._real, this._pasos);

  @override
  Future<void> salir() async {
    _pasos.add('salir');
    await _real.salir();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
