// test/fakes.dart
// Versiones en memoria de AuthService y UsuarioRepository, para probar
// el AuthBloc y las pantallas sin tocar Firebase.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plantapulse/src/models/usuario.dart';
import 'package:plantapulse/src/repositories/usuario_repository.dart';
import 'package:plantapulse/src/services/auth_service.dart';

class FakeAuthService implements AuthService {
  /// email → (password, uid). Simula lo que guarda Firebase Auth.
  final Map<String, (String, String)> cuentas = {};
  String? _uid;
  int _siguiente = 1;

  @override
  String? get uidActual => _uid;

  @override
  bool get haySesion => _uid != null;

  @override
  Stream<User?> get cambiosDeSesion => const Stream.empty();

  @override
  Future<String> registrar({required String email, required String password}) async {
    final correo = email.trim();
    if (cuentas.containsKey(correo)) {
      throw FirebaseAuthException(code: 'email-already-in-use');
    }
    final uid = 'uid${_siguiente++}';
    cuentas[correo] = (password, uid);
    _uid = uid;
    return uid;
  }

  @override
  Future<String> entrar({required String email, required String password}) async {
    final cuenta = cuentas[email.trim()];
    if (cuenta == null || cuenta.$1 != password) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    _uid = cuenta.$2;
    return cuenta.$2;
  }

  @override
  Future<void> salir() async => _uid = null;

  @override
  Future<void> enviarCorreoDeRecuperacion(String email) async {}
}

class FakeUsuarioRepository implements UsuarioRepository {
  final Map<String, Usuario> perfiles = {};

  /// Lo que se habría escrito en Firestore, para revisar que no haya contraseña.
  final List<Map<String, dynamic>> escrituras = [];

  @override
  Future<void> crear(Usuario usuario) async {
    escrituras.add(usuario.aFirestore());
    perfiles[usuario.uid] = usuario;
  }

  @override
  Future<Usuario?> obtener(String uid) async => perfiles[uid];

  @override
  Future<void> aprobar(
    String uid, {
    required RolUsuario rol,
    required String plantaId,
    required UsuarioRef aprobadoPor,
  }) async {
    perfiles[uid] = perfiles[uid]!.copyWith(
      estado: EstadoCuenta.activo,
      rol: rol,
      plantaId: plantaId,
      aprobadoPor: aprobadoPor,
    );
  }

  @override
  Future<void> rechazar(String uid, UsuarioRef aprobadoPor) async {
    perfiles[uid] = perfiles[uid]!.copyWith(
      estado: EstadoCuenta.rechazado,
      aprobadoPor: aprobadoPor,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const adminRef = UsuarioRef(uid: 'admin1', nombre: 'Admin');
