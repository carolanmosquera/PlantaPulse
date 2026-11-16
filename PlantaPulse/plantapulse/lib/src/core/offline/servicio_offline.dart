
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../data/models/orden_modelo.dart';
import '../data/models/reporte_modelo.dart';
import '../domain/entities/orden.dart';
import '../domain/entities/reporte.dart';
import '../domain/repositories/reporte_repositorio.dart';
import '../errors/fallos.dart';

class ServicioOffline extends ChangeNotifier {
  final ReporteRepositorio _reportes;
  final SharedPreferencesAsync _local = SharedPreferencesAsync();
  Timer? _temporizador;

  bool conectado = true;
  bool sincronizando = false;
  int pendientes = 0;

  bool _iniciado = false;
  bool _cerrado = false;

  ServicioOffline(this._reportes);

  String? get _uid => Supabase.instance.client.auth.currentUser?.id;

  String _claveOrdenes(String uid, String plantaId) =>
      'kan98_ordenes_${uid}_$plantaId';

  String _claveReportes(String uid) =>
      'kan98_reportes_$uid';

  Future<void> iniciar() async {
    if (_iniciado) return;
    _iniciado = true;

    // Reintenta mientras la aplicación esté abierta.
    _temporizador = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(revisar()),
    );

    await revisar();
  }

  Future<void> revisar() async {
    if (_cerrado) return;

    // La sincronización valida la conexión real al comunicarse con el servidor.
    conectado = true;
    notifyListeners();
    await actualizarPendientes();

    if (conectado) {
      await sincronizar();
    }
  }

  // ---------------------------
  // ÓRDENES GUARDADAS
  // ---------------------------

  Future<void> guardarOrdenes({
    required String uid,
    required String plantaId,
    required List<Orden> ordenes,
  }) async {
    if (uid != _uid) return;

    final datos = [
      for (final orden in ordenes)
        {
          ...OrdenModelo.desdeEntidad(orden).toJson(),
          'created_at': orden.createdAt.toUtc().toIso8601String(),
          'ultima_actividad':
              orden.ultimaActividad.toUtc().toIso8601String(),
          'eliminada_en':
              orden.eliminadaEn?.toUtc().toIso8601String(),
        },
    ];

    await _local.setString(
      _claveOrdenes(uid, plantaId),
      jsonEncode(datos),
    );
  }

  Future<List<Orden>> leerOrdenes({
    required String uid,
    required String plantaId,
  }) async {
    if (uid != _uid) return [];

    try {
      final contenido = await _local.getString(
        _claveOrdenes(uid, plantaId),
      );

      if (contenido == null) return [];

      final lista = jsonDecode(contenido) as List;

      return lista
          .map((dato) => OrdenModelo.fromJson(
                Map<String, dynamic>.from(dato as Map),
              ))
          .where((orden) =>
              !orden.eliminada &&
              orden.plantaId == plantaId &&
              orden.asignadoAUid == uid)
          .toList()
        ..sort(
          (a, b) => a.fechaLimite.compareTo(b.fechaLimite),
        );
    } catch (_) {
      return [];
    }
  }

  // ---------------------------
  // REPORTES PENDIENTES
  // ---------------------------

  Future<List<Map<String, dynamic>>> _leerCola(String uid) async {
    final contenido = await _local.getString(
      _claveReportes(uid),
    );

    if (contenido == null || contenido.isEmpty) return [];

    final lista = jsonDecode(contenido) as List;

    return lista
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> actualizarPendientes() async {
    final uid = _uid;

    if (uid == null) {
      pendientes = 0;
    } else {
      try {
        pendientes = (await _leerCola(uid)).length;
      } catch (_) {
        pendientes = 0;
      }
    }

    if (!_cerrado) notifyListeners();
  }

  Future<void> guardarReportePendiente(Reporte reporte) async {
    final uid = _uid;

    if (uid == null || uid != reporte.autor.uid) {
      throw const FalloPermisos(
        'Debes iniciar sesión con la cuenta del reporte.',
      );
    }

    if (reporte.evidencias.isNotEmpty) {
      throw const FalloApp(
        'El almacenamiento offline de fotografías '
        'todavía no está disponible.',
      );
    }

    final cola = await _leerCola(uid);
    final idLocal = const Uuid().v4();

    cola.add({
      ...ReporteModelo.desdeEntidad(reporte).toJson(),
      'id': idLocal,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    await _local.setString(
      _claveReportes(uid),
      jsonEncode(cola),
    );

    await actualizarPendientes();
  }

  // ---------------------------
  // SINCRONIZACIÓN AUTOMÁTICA
  // ---------------------------

  Future<void> sincronizar() async {
    final uid = _uid;

    if (!conectado || sincronizando || uid == null) return;

    sincronizando = true;
    if (!_cerrado) notifyListeners();

    try {
      final cola = await _leerCola(uid);

      for (final item in cola) {
        // Evitar sincronizar registros de otra cuenta.
        if (_uid != uid || !conectado) break;

        final reporte = ReporteModelo.fromJson(item);
        bool entregado = false;

        try {
          await _reportes.crear(reporte);
          entregado = true;
        } on FalloApp catch (error) {
          // El UUID permite reconocer un reintento que
          // ya fue insertado anteriormente.
          if (error.mensaje == 'Ese registro ya existe.') {
            entregado = true;
          } else {
            // Conservar el reporte para el siguiente intento.
            break;
          }
        } catch (_) {
          break;
        }

        if (entregado) {
          final actual = await _leerCola(uid);

          actual.removeWhere(
            (dato) => dato['id'] == item['id'],
          );

          await _local.setString(
            _claveReportes(uid),
            jsonEncode(actual),
          );
        }
      }
    } catch (_) {
      // No borrar los registros si ocurre un fallo inesperado.
    } finally {
      sincronizando = false;
      await actualizarPendientes();
    }
  }

  @override
  void dispose() {
    _cerrado = true;
    _temporizador?.cancel();
    super.dispose();
  }
}
