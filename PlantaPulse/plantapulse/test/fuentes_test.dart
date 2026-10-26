// test/fuentes_test.dart
// La capa de fuentes de datos: AlmacenamientoRepositorioImpl compone dos
// fuentes (el dispositivo y Storage) sin saber qué hay debajo de ninguna.
// Antes no se podía probar: la cámara y Storage estaban metidos en un
// widget y en el repositorio.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plantapulse/main.dart';
import 'package:plantapulse/src/core/core.dart';
import 'package:plantapulse/src/core/data/data.dart';

import 'fakes.dart';

/// La cámara y la galería, sin teléfono.
class DispositivoFalso implements FotoFuenteDispositivo {
  final FotoElegida? foto;
  final List<String> llamadas = [];

  DispositivoFalso(this.foto);

  @override
  Future<FotoElegida?> tomarConCamara() async {
    llamadas.add('camara');
    return foto;
  }

  @override
  Future<FotoElegida?> elegirDeGaleria() async {
    llamadas.add('galeria');
    return foto;
  }
}

/// Storage, sin red: guarda lo que recibe.
class AlmacenFalso implements AlmacenamientoFuenteSupabase {
  final List<({String plantaId, String ordenId, Uint8List bytes, String extension})>
      recibidas = [];
  final List<String> urlsPedidas = [];

  @override
  Future<String> subir({
    required String plantaId,
    required String ordenId,
    required Uint8List bytes,
    required String extension,
  }) async {
    recibidas.add((
      plantaId: plantaId,
      ordenId: ordenId,
      bytes: bytes,
      extension: extension,
    ));
    return '$plantaId/$ordenId/foto-${recibidas.length}.$extension';
  }

  @override
  String urlPublica(String ruta) {
    urlsPedidas.add(ruta);
    return 'https://almacen.falso/$ruta';
  }
}

void main() {
  final bytes = Uint8List.fromList([7, 7, 7]);

  test('pide la foto a la fuente del dispositivo y la entrega a la de Storage',
      () async {
    final dispositivo =
        DispositivoFalso(FotoElegida(bytes: bytes, extension: 'jpg'));
    final almacen = AlmacenFalso();
    final repo = AlmacenamientoRepositorioImpl(
        dispositivo: dispositivo, almacen: almacen);

    final foto = await repo.obtenerFoto(OrigenFoto.camara);
    expect(dispositivo.llamadas, ['camara']);
    expect(foto, isNotNull);

    final ruta = await repo.subir(
      plantaId: 'p1',
      ordenId: 'o1',
      bytes: foto!.bytes,
      extension: foto.extension,
    );
    // Storage recibe exactamente lo que dio el dispositivo
    final recibida = almacen.recibidas.single;
    expect(recibida.bytes, same(bytes));
    expect(recibida.extension, 'jpg');
    expect((recibida.plantaId, recibida.ordenId), ('p1', 'o1'));
    expect(ruta, 'p1/o1/foto-1.jpg');
  });

  test('cada origen va a su método de la fuente; cancelar devuelve null',
      () async {
    final dispositivo = DispositivoFalso(null);       // el usuario canceló
    final repo = AlmacenamientoRepositorioImpl(
        dispositivo: dispositivo, almacen: AlmacenFalso());

    expect(await repo.obtenerFoto(OrigenFoto.galeria), isNull);
    expect(await repo.obtenerFoto(OrigenFoto.camara), isNull);
    expect(dispositivo.llamadas, ['galeria', 'camara']);
  });

  test('la URL sale de la fuente de Storage; una URL vieja se respeta', () {
    final almacen = AlmacenFalso();
    final repo = AlmacenamientoRepositorioImpl(
        dispositivo: DispositivoFalso(null), almacen: almacen);

    expect(repo.urlDe('p1/o1/a.jpg'), 'https://almacen.falso/p1/o1/a.jpg');
    expect(repo.urlDe('https://otro.sitio/b.jpg'), 'https://otro.sitio/b.jpg');
    expect(almacen.urlsPedidas, ['p1/o1/a.jpg']);   // la vieja ni la toca
  });

  // ═══════════ En pantalla ═══════════

  testWidgets('"Agregar foto" pide la foto por el caso de uso, sin image_picker',
      (tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.toString().contains('overflowed')) return;
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final auth = FakeAuthService();
    final usuarios = FakeUsuarioRepository();
    final ordenes = FakeOrdenRepository();
    final almacen = FakeAlmacenamientoRepository()
      ..fotoDelDispositivo = FotoElegida(bytes: _pixelPng, extension: 'png');
    auth.cuentas['tec1@planta.com'] = ('clave1234', 'tec1');
    usuarios.perfiles['tec1'] = Usuario(
      uid: 'tec1', nombre: 'Luis Pérez', email: 'tec1@planta.com',
      rol: RolUsuario.tecnico, plantaId: 'p1',
      estado: EstadoCuenta.activo, createdAt: DateTime(2026),
    );
    final ahora = DateTime.now();
    ordenes.ordenes.add(Orden(
      id: 'o1', codigo: 'WO-2026-0001', plantaId: 'p1',
      titulo: 'Cambio de rodamientos',
      creadoPor: const UsuarioRef(uid: 'sup1', nombre: 'Laura Vega'),
      asignadoA: const UsuarioRef(uid: 'tec1', nombre: 'Luis Pérez'),
      asignadoAUid: 'tec1', createdAt: ahora,
      fechaLimite: ahora.add(const Duration(days: 1)), ultimaActividad: ahora,
    ));

    await tester.pumpWidget(PlantaPulseApp(
      authBloc: authBlocDe(auth, usuarios),
      usuarioRepository: usuarios,
      plantaRepository: FakePlantaRepository(),
      ordenRepository: ordenes,
      equipoRepository: FakeEquipoRepository(),
      categoriaRepositorio: FakeCategoriaRepository(),
      zonaRepositorio: FakeZonaRepository(),
      reporteRepositorio: FakeReporteRepository(),
      almacenamientoRepositorio: almacen,
    ));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'tec1@planta.com');
    await tester.enterText(find.byType(TextField).at(1), 'clave1234');
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();

    Future<void> tocar(String texto) async {
      await tester.ensureVisible(find.text(texto));
      await tester.pumpAndSettle();
      await tester.tap(find.text(texto));
      await tester.pumpAndSettle();
    }

    await tocar('Cambio de rodamientos');
    await tocar('LLENAR REPORTE DE AVANCE');
    expect(find.text('0/$maxFotosPorReporte · OPCIONAL'), findsOneWidget);

    // La hoja solo elige el origen; la foto la da el repositorio
    await tocar('Agregar foto');
    await tocar('Tomar foto');
    expect(almacen.pedidas, [OrigenFoto.camara]);
    expect(find.text('1/$maxFotosPorReporte · OPCIONAL'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
  });
}

/// Un PNG de 1×1 válido, para que Image.memory lo pueda pintar.
final _pixelPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0,
  0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D, 0x1D, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);
