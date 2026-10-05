// test/fakes.dart
// Versiones en memoria de los contratos del dominio, para probar
// los Blocs y las pantallas sin tocar Firebase.
import 'dart:async';
import 'package:plantapulse/src/core/core.dart';
import 'package:plantapulse/src/core/data/models/orden_firestore.dart';
import 'package:plantapulse/src/core/data/models/usuario_firestore.dart';
import 'package:plantapulse/src/features/auth/auth.dart';
import 'package:plantapulse/src/features/crear_orden/crear_orden.dart';
import 'package:plantapulse/src/features/ordenes/ordenes.dart';

/// Arma el AuthBloc con sus casos de uso, igual que main.dart.
AuthBloc authBlocDe(AutenticacionRepositorio auth, UsuarioRepositorio usuarios) =>
    AuthBloc(
      comprobarSesion: ComprobarSesion(auth, usuarios),
      iniciarSesion: IniciarSesion(auth, usuarios),
      registrarSolicitud: RegistrarSolicitud(auth, usuarios),
      recargarPerfil: RecargarPerfil(auth, usuarios),
      cerrarSesion: CerrarSesion(auth),
    );

/// Arma el OrdenesBloc con sus casos de uso, igual que main.dart.
OrdenesBloc ordenesBlocDe(OrdenRepositorio ordenes) => OrdenesBloc(
      observarOrdenesDePlanta: ObservarOrdenesDePlanta(ordenes),
      observarMisTareas: ObservarMisTareas(ordenes),
    );

/// Implementa el contrato AutenticacionRepositorio. Conserva el nombre
/// histórico para no tocar las pruebas.
class FakeAuthService implements AutenticacionRepositorio {
  /// email → (password, uid). Simula lo que guarda el servicio de Auth.
  final Map<String, (String, String)> cuentas = {};
  String? _uid;
  int _siguiente = 1;

  @override
  String? get uidActual => _uid;

  @override
  bool get haySesion => _uid != null;

  @override
  CuentaAuth? get cuentaActual {
    final uid = _uid;
    if (uid == null) return null;
    final email =
        cuentas.entries.where((e) => e.value.$2 == uid).firstOrNull?.key;
    return CuentaAuth(uid: uid, email: email);
  }

  @override
  Stream<String?> get cambiosDeSesion => const Stream.empty();

  @override
  Future<String> registrar({required String email, required String password}) async {
    final correo = email.trim();
    if (cuentas.containsKey(correo)) {
      throw const FalloAutenticacion('Ya existe una cuenta con ese correo.');
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
      throw const FalloAutenticacion('Correo o contraseña incorrectos.');
    }
    _uid = cuenta.$2;
    return cuenta.$2;
  }

  @override
  Future<void> salir() async => _uid = null;

  @override
  Future<void> enviarCorreoDeRecuperacion(String email) async {}
}

class FakeUsuarioRepository implements UsuarioRepositorio {
  final Map<String, Usuario> perfiles = {};

  /// Lo que se habría escrito en Firestore, para revisar que no haya contraseña.
  final List<Map<String, dynamic>> escrituras = [];

  /// Avisa a los streams abiertos que algo cambió, como snapshots().
  final _cambios = StreamController<void>.broadcast();

  List<Usuario> get _pendientes => perfiles.values
      .where((u) => u.estado == EstadoCuenta.pendiente)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Stream<List<Usuario>> solicitudesPendientes() async* {
    yield _pendientes;
    yield* _cambios.stream.map((_) => _pendientes);
  }

  @override
  Future<void> crear(Usuario usuario) async {
    escrituras.add(usuario.aFirestore());
    perfiles[usuario.uid] = usuario;
    _cambios.add(null);
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
    _cambios.add(null);
  }

  @override
  Future<void> rechazar(String uid, UsuarioRef aprobadoPor) async {
    perfiles[uid] = perfiles[uid]!.copyWith(
      estado: EstadoCuenta.rechazado,
      aprobadoPor: aprobadoPor,
    );
    _cambios.add(null);
  }

  @override
  Future<List<Usuario>> tecnicosDePlanta(String plantaId) async =>
      perfiles.values
          .where((u) =>
              u.plantaId == plantaId &&
              u.rol == RolUsuario.tecnico &&
              u.estado == EstadoCuenta.activo &&
              u.activo)
          .toList()
        ..sort((a, b) => a.nombre.compareTo(b.nombre));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePlantaRepository implements PlantaRepositorio {
  final List<Planta> plantas = const [
    Planta(id: 'p1', nombre: 'Planta Norte'),
    Planta(id: 'p2', nombre: 'Planta Sur'),
  ];

  @override
  Future<List<Planta>> activas() async => plantas;
}

const adminRef = UsuarioRef(uid: 'admin1', nombre: 'Admin');


class FakeEquipoRepository implements EquipoRepositorio {
  final List<Equipo> equipos = [];

  @override
  Future<List<Equipo>> deLaPlanta(String plantaId) async => equipos
      .where((e) => e.plantaId == plantaId && e.activo)
      .toList()
    ..sort((a, b) => a.nombre.compareTo(b.nombre));

  @override
  Future<Equipo?> obtener(String equipoId) async =>
      equipos.where((e) => e.id == equipoId).firstOrNull;
}

/// Una consulta abierta: su filtro, su orden y el stream que la escucha.
class _Consulta {
  final bool Function(Orden) filtro;
  final int Function(Orden, Orden) orden;
  final StreamController<List<Orden>> ctrl;

  _Consulta(this.filtro, this.orden, this.ctrl);

  List<Orden> sobre(List<Orden> todas) =>
      todas.where(filtro).toList()..sort(orden);
}

/// Simula snapshots(): cada consulta abierta recibe la lista de nuevo
/// cuando se crea o cambia una orden, sin que nadie la relance.
class FakeOrdenRepository implements OrdenRepositorio {
  final List<Orden> ordenes = [];

  /// Lo que se habría escrito en Firestore con add().
  final List<Map<String, dynamic>> escrituras = [];

  /// Cuántas consultas se abrieron: los filtros en memoria no deben sumar.
  int consultas = 0;

  final List<_Consulta> _abiertas = [];
  int _siguiente = 1;

  int get suscripcionesActivas => _abiertas.length;

  Stream<List<Orden>> _consultar(
    bool Function(Orden) filtro,
    int Function(Orden, Orden) orden,
  ) {
    consultas++;
    final ctrl = StreamController<List<Orden>>();
    final consulta = _Consulta(filtro, orden, ctrl);
    ctrl.onListen = () {
      _abiertas.add(consulta);
      ctrl.add(consulta.sobre(ordenes));
    };
    ctrl.onCancel = () => _abiertas.remove(consulta);
    return ctrl.stream;
  }

  void _avisar() {
    for (final c in List.of(_abiertas)) {
      c.ctrl.add(c.sobre(ordenes));
    }
  }

  /// Simula que el stream de Firestore falla (red caída, permisos...).
  void fallar(Object error) {
    for (final c in List.of(_abiertas)) {
      c.ctrl.addError(error);
    }
  }

  @override
  Stream<List<Orden>> deLaPlanta(String plantaId, {EstadoOrden? estado}) =>
      _consultar(
        (o) => o.plantaId == plantaId && (estado == null || o.estado == estado),
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

  @override
  Stream<List<Orden>> asignadasA(String uid, String plantaId) => _consultar(
        (o) => o.plantaId == plantaId && o.asignadoAUid == uid,
        (a, b) => a.fechaLimite.compareTo(b.fechaLimite),
      );

  @override
  Future<String> crear(Orden orden) async {
    final id = 'ord${_siguiente++}';
    escrituras.add(orden.aFirestore());
    ordenes.add(conId(orden, id));
    _avisar();
    return id;
  }

  @override
  Future<void> actualizarEstado(String ordenId, EstadoOrden estado) async {
    final i = ordenes.indexWhere((o) => o.id == ordenId);
    ordenes[i] = ordenes[i].copyWith(estado: estado);
    _avisar();
  }

  /// Orden no tiene copyWith(id): Firestore pone el id al crear.
  static Orden conId(Orden o, String id) => Orden(
        id: id,
        codigo: o.codigo,
        plantaId: o.plantaId,
        titulo: o.titulo,
        descripcion: o.descripcion,
        categoria: o.categoria,
        zonaId: o.zonaId,
        zonaNombre: o.zonaNombre,
        equipoId: o.equipoId,
        equipoNombre: o.equipoNombre,
        creadoPor: o.creadoPor,
        asignadoA: o.asignadoA,
        asignadoAUid: o.asignadoAUid,
        estado: o.estado,
        prioridad: o.prioridad,
        createdAt: o.createdAt,
        fechaLimite: o.fechaLimite,
        ultimaActividad: o.ultimaActividad,
        portadaUrl: o.portadaUrl,
        totalReportes: o.totalReportes,
        totalAlertas: o.totalAlertas,
      );
}
