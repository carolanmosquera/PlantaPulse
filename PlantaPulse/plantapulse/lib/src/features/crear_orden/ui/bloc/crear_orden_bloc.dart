// lib/src/features/crear_orden/ui/bloc/crear_orden_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/entities/categoria.dart';
import '../../../../core/domain/entities/equipo.dart';
import '../../../../core/domain/entities/evidencia.dart';
import '../../../../core/domain/entities/foto_elegida.dart';
import '../../../../core/domain/entities/foto_pendiente.dart';
import '../../../../core/domain/entities/orden.dart';
import '../../../../core/domain/entities/usuario.dart';
import '../../../../core/domain/usecases/catalogos.dart';
import '../../../../core/domain/usecases/evidencias.dart';
import '../../../../core/domain/usecases/ia.dart';
import '../../../../core/errors/fallos.dart';
import '../../domain/usecases/crear_orden_casos.dart';
import 'crear_orden_event.dart';
import 'crear_orden_state.dart';

export 'crear_orden_event.dart';
export 'crear_orden_state.dart';

/// Vive solo mientras dura el asistente (P1 → P2): lo crea P1 y se
/// destruye al cerrarlo. Reemplaza al antiguo BorradorOrden.
///
/// Las altas de categoría y equipo NO pasan por aquí: las hace su
/// formulario, que necesita el resultado en el momento para mostrar un
/// nombre o serial repetido dentro de la hoja. Al terminar, el formulario
/// avisa con CategoriaAgregada / EquipoAgregado.
class CrearOrdenBloc extends Bloc<CrearOrdenEvent, CrearOrdenState> {
  final ListarCategoriasDePlanta _listarCategorias;
  final ListarEquiposDePlanta _listarEquipos;
  final ListarTecnicosDePlanta _listarTecnicos;
  final PublicarOrden _publicarOrden;
  final NuevoIdDeOrden _nuevoIdDeOrden;
  final SubirEvidencia _subirEvidencia;
  final EstructurarNota _estructurarNota;
  final Future<String> Function(Orden)? _publicarConversion;
  int _siguienteFoto = 0;

  CrearOrdenBloc({
    required this._listarCategorias,
    required this._listarEquipos,
    required this._listarTecnicos,
    required this._publicarOrden,
    required this._nuevoIdDeOrden,
    required this._subirEvidencia,
    required this._estructurarNota,
    String descripcionInicial = '',
    Future<String> Function(Orden)? publicarConversion,
  }) : _publicarConversion = publicarConversion,
       super(CrearOrdenState.inicial(
         descripcion: descripcionInicial,
         requiereTecnico: publicarConversion != null,
       )) {
    on<CrearOrdenIniciada>(_alIniciar);
    on<DescripcionCambiada>(
        (e, emit) => emit(state.copyWith(descripcion: e.texto)));
    // Elegir una categoría a mano: si no es la que propuso la IA, deja de
    // estar marcada, y la sugerencia pendiente ya no aplica
    on<CategoriaCambiada>((e, emit) => emit(state.copyWith(
          categoria: e.categoria,
          marcasIa: e.categoria == state.categoria
              ? null
              : _sinMarca(CampoIa.categoria),
          limpiarCategoriaSugerida: e.categoria != state.categoria,
        )));
    on<EquipoSeleccionado>(
        (e, emit) => emit(state.copyWith(equipo: e.equipo)));
    on<PrioridadCambiada>((e, emit) => emit(state.copyWith(
          prioridad: e.prioridad,
          marcasIa: e.prioridad == state.prioridad
              ? null
              : _sinMarca(CampoIa.prioridad),
        )));
    on<NotaEstructurada>(_alEstructurar);
    // El controlador de P2 repite el texto que puso la IA al cargarlo: solo
    // un cambio real quita la marca
    on<TituloCambiado>((e, emit) => emit(state.copyWith(
          titulo: e.texto,
          marcasIa: e.texto == state.titulo ? null : _sinMarca(CampoIa.titulo),
        )));
    on<DescripcionTecnicaCambiada>((e, emit) => emit(state.copyWith(
          descripcionTecnica: e.texto,
          marcasIa: e.texto == state.descripcionTecnica
              ? null
              : _sinMarca(CampoIa.descripcion),
        )));
    on<SugerenciaCategoriaDescartada>(
        (e, emit) => emit(state.copyWith(limpiarCategoriaSugerida: true)));
    on<FechaLimiteCambiada>(
        (e, emit) => emit(state.copyWith(fechaLimite: e.fecha)));
    on<TecnicoSeleccionado>(
        (e, emit) => emit(state.copyWith(tecnico: e.tecnico)));
    on<TecnicoQuitado>(
        (e, emit) => emit(state.copyWith(limpiarTecnico: true)));
    on<CategoriaAgregada>(_alAgregarCategoria);
    on<EquipoAgregado>(_alAgregarEquipo);
    on<EquipoActualizado>(_alActualizarEquipo);
    on<EquipoDadoDeBaja>(_alDarDeBajaEquipo);
    on<FotoHallazgoAgregada>((e, emit) {
      if (!state.puedeAgregarFoto) return;       // tope de 30, como en la base
      emit(state.copyWith(fotos: [
        ...state.fotos,
        FotoPendiente(
          id: _siguienteFoto++,
          foto: FotoElegida(bytes: e.bytes, extension: e.extension),
        ),
      ]));
    });
    // Quitar una foto ya subida (tras un fallo) la deja huérfana en el
    // bucket: no hay política para borrar evidencias.
    on<FotoHallazgoQuitada>((e, emit) {
      if (state.publicando) return;
      emit(state.copyWith(
          fotos: state.fotos.where((f) => f.id != e.id).toList()));
    });
    on<ObservacionesCambiadas>(
        (e, emit) => emit(state.copyWith(observaciones: e.texto)));
    on<OrdenPublicada>(_alPublicar);
  }

  Future<void> _alIniciar(
    CrearOrdenIniciada e,
    Emitter<CrearOrdenState> emit,
  ) async {
    emit(state.copyWith(
      status: EstadoCrearOrden.cargando,
      plantaId: e.plantaId,
      limpiarError: true,
    ));
    try {
      // En paralelo: los tres catálogos no dependen uno del otro
      final (categorias, equipos, tecnicos) = await (
        _listarCategorias.ejecutar(e.plantaId),
        _listarEquipos.ejecutar(e.plantaId),
        _listarTecnicos.ejecutar(e.plantaId),
      ).wait;
      emit(state.copyWith(
        status: EstadoCrearOrden.listo,
        categorias: categorias,
        equipos: equipos,
        tecnicos: tecnicos,
        // El asistente arranca con un chip marcado, como antes
        categoria: state.categoria.isEmpty && categorias.isNotEmpty
            ? categorias.first.nombre
            : null,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: EstadoCrearOrden.error,
        mensajeError: 'No se pudieron cargar las categorías, equipos y técnicos.',
      ));
    }
  }

  Set<CampoIa> _sinMarca(CampoIa campo) => {...state.marcasIa}..remove(campo);

  /// KAN-92. La IA propone; el supervisor decide en P2. Pase lo que pase,
  /// P1 navega a P2 cuando `estructurando` vuelve a false: la IA no puede
  /// dejar a nadie sin poder crear una orden.
  Future<void> _alEstructurar(
    NotaEstructurada e,
    Emitter<CrearOrdenState> emit,
  ) async {
    if (state.estructurando || !state.paso1Valido) return;
    final nota = state.descripcion.trim();
    emit(state.copyWith(estructurando: true, limpiarErrorIa: true));

    try {
      final b = await _estructurarNota.ejecutar(nota);

      // Solo se preselecciona una categoría que YA existe. Si no existe, la
      // IA no la crea: queda como sugerencia y el supervisor decide.
      final sugerida = b.categoriaSugerida.trim();
      final existente = state.categorias
          .where((c) => _mismoNombre(c.nombre, sugerida))
          .firstOrNull;

      emit(state.copyWith(
        estructurando: false,
        titulo: b.titulo,
        descripcionTecnica: b.descripcion,
        prioridad: b.prioridadSugerida,
        categoria: existente?.nombre,
        categoriaSugeridaIa:
            existente == null && sugerida.isNotEmpty ? sugerida : null,
        limpiarCategoriaSugerida: existente != null || sugerida.isEmpty,
        marcasIa: {
          CampoIa.titulo,
          CampoIa.descripcion,
          CampoIa.prioridad,
          if (existente != null) CampoIa.categoria,
        },
        generadaPorIa: true,
        notaOriginal: nota,
      ));
    } catch (err) {
      // Sin reintento automático: gastaría cuota sin que nadie lo note.
      // Se vacía lo que la IA había propuesto antes y nadie tocó; lo que
      // escribió la persona se queda.
      final m = state.marcasIa;
      emit(state.copyWith(
        estructurando: false,
        errorIa: 'El asistente no pudo estructurar la nota: '
            '${FalloApp.mensajeDe(err)} Completa los campos a mano.',
        titulo: m.contains(CampoIa.titulo) ? '' : null,
        descripcionTecnica: m.contains(CampoIa.descripcion) ? '' : null,
        prioridad: m.contains(CampoIa.prioridad) ? Prioridad.media : null,
        marcasIa: const {},
        limpiarCategoriaSugerida: true,
        generadaPorIa: false,
        limpiarNotaOriginal: true,
      ));
    }
  }

  static bool _mismoNombre(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  void _alAgregarCategoria(CategoriaAgregada e, Emitter<CrearOrdenState> emit) {
    final lista = [
      for (final c in state.categorias)
        if (c.id != e.categoria.id) c,
      e.categoria,
    ]..sort(_porNombre<Categoria>((c) => c.nombre));
    // Si es la que sugirió la IA, la sugerencia queda resuelta: la creó el
    // supervisor, no el asistente
    final eraSugerida = state.categoriaSugeridaIa != null &&
        _mismoNombre(state.categoriaSugeridaIa!, e.categoria.nombre);
    emit(state.copyWith(
      categorias: lista,
      categoria: e.categoria.nombre,
      marcasIa: eraSugerida
          ? {...state.marcasIa, CampoIa.categoria}
          : _sinMarca(CampoIa.categoria),
      limpiarCategoriaSugerida: true,
    ));
  }

  void _alAgregarEquipo(EquipoAgregado e, Emitter<CrearOrdenState> emit) {
    final lista = [
      for (final x in state.equipos)
        if (x.id != e.equipo.id) x,
      e.equipo,
    ]..sort(_porNombre<Equipo>((x) => x.nombre));
    emit(state.copyWith(equipos: lista, equipo: e.equipo));
  }

  void _alActualizarEquipo(EquipoActualizado e, Emitter<CrearOrdenState> emit) {
    final lista = [
      for (final x in state.equipos) x.id == e.equipo.id ? e.equipo : x,
    ]..sort(_porNombre<Equipo>((x) => x.nombre));
    emit(state.copyWith(
      equipos: lista,
      equipo: state.equipo?.id == e.equipo.id ? e.equipo : null,
    ));
  }

  void _alDarDeBajaEquipo(EquipoDadoDeBaja e, Emitter<CrearOrdenState> emit) {
    emit(state.copyWith(
      equipos: state.equipos.where((x) => x.id != e.equipoId).toList(),
      limpiarEquipo: state.equipo?.id == e.equipoId,
    ));
  }

  /// Mismo orden que trae la base (por nombre, sin distinguir mayúsculas):
  /// así lo recién creado queda donde estará al reabrir el asistente.
  static int Function(T, T) _porNombre<T>(String Function(T) nombre) =>
      (a, b) => nombre(a).toLowerCase().compareTo(nombre(b).toLowerCase());

  Future<void> _alPublicar(
    OrdenPublicada e,
    Emitter<CrearOrdenState> emit,
  ) async {
    final equipo = state.equipo;
    final tecnico = state.tecnico;      // null = la orden nace sin asignar
    if (state.publicando || !state.paso2Valido || equipo == null) return;

    // El id se reserva una vez y se reutiliza en cada reintento: las fotos
    // ya subidas están en la carpeta de ESE id
    final ordenId = state.ordenIdReservado ?? _nuevoIdDeOrden.ejecutar();
    final fotos = [...state.fotos];
    emit(state.copyWith(
      status: EstadoCrearOrden.publicando,
      ordenIdReservado: ordenId,
      subiendo: 0,
      totalSubir: fotos.where((f) => !f.subida).length,
      limpiarError: true,
    ));

    // ── Fase 1: subir las fotos del hallazgo ──
    // Si una falla, la orden NO se crea: no queda una orden a medias.
    var hechas = 0;
    for (var i = 0; i < fotos.length; i++) {
      final foto = fotos[i];
      if (foto.subida) continue;
      emit(state.copyWith(subiendo: hechas + 1));
      try {
        final ruta = await _subirEvidencia.ejecutar(
          plantaId: state.plantaId,
          registroId: ordenId,
          bytes: foto.foto.bytes,
          extension: foto.foto.extension,
        );
        fotos[i] = foto.subidaA(ruta, DateTime.now());
        hechas++;
        emit(state.copyWith(fotos: List.of(fotos)));
      } catch (err) {
        emit(state.copyWith(
          status: EstadoCrearOrden.error,
          fotos: List.of(fotos),
          mensajeError: 'La orden no se publicó: no se pudo subir la foto '
              '${i + 1}. ${FalloApp.mensajeDe(err)}',
        ));
        return;
      }
    }
    final evidencias = [
      for (final f in fotos)
        Evidencia(ruta: f.ruta!, subidaEn: f.subidaEn!, autorUid: e.creadoPor.uid),
    ];

    // ── Fase 2: crear la orden, ya con sus fotos ──
    final ahora = DateTime.now();
    final sufijo =
        (ahora.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    final codigo = 'WO-${ahora.year}-$sufijo';
    final f = state.fechaLimite;

    final orden = Orden(
      id: ordenId,                         // reservado: sus fotos ya están en su carpeta
      codigo: codigo,
      plantaId: state.plantaId,
      titulo: state.tituloFinal,
      // La descripción técnica (de la IA o a mano) y las observaciones;
      // sin IA queda como antes: solo las observaciones
      descripcion: [
        state.descripcionTecnica.trim(),
        state.observaciones.trim(),
      ].where((t) => t.isNotEmpty).join('\n\n'),
      categoria: state.categoria,
      // La ubicación sale del equipo, no de su código
      zonaId: equipo.zonaId,
      zonaNombre: equipo.zonaNombre,
      equipoId: equipo.id,
      equipoNombre: equipo.nombre,
      creadoPor: e.creadoPor,
      // El responsable es el técnico elegido, no quien la crea.
      // Sin técnico, los dos van null: se asigna después desde el detalle.
      asignadoA: tecnico == null ? null : UsuarioRef.desdeUsuario(tecnico),
      asignadoAUid: tecnico?.uid,
      // Toda orden nace pendiente: la prioridad crítica NO es un estado
      estado: EstadoOrden.pendiente,
      prioridad: state.prioridad,
      createdAt: ahora,                    // el repositorio pone la del servidor
      fechaLimite: DateTime(f.year, f.month, f.day, 23, 59),
      ultimaActividad: ahora,
      evidencias: evidencias,
      // Portada = la última foto subida (ruta, no URL). Los reportes la
      // irán reemplazando con la suya desde el servidor.
      portadaUrl: evidencias.isEmpty ? null : evidencias.last.ruta,
      totalReportes: 0,
      totalAlertas: 0,
      // Para comparar después qué escribió la persona y qué entendió el modelo
      generadaPorIA: state.generadaPorIa,
      notaOriginal: state.generadaPorIa ? state.notaOriginal : null,
    );

    try {
      final publicar = _publicarConversion ?? _publicarOrden.ejecutar;
      final id = await publicar(orden);
      emit(state.copyWith(
        status: EstadoCrearOrden.publicada,
        ordenIdCreada: id,
        codigoCreado: codigo,
      ));
    } catch (err) {
      // Las fotos ya subidas conservan su ruta (y el id reservado): el
      // reintento solo vuelve a intentar crear la orden. Si se abandona,
      // quedan huérfanas en el bucket (costo aceptado, como en reportes).
      emit(state.copyWith(
        status: EstadoCrearOrden.error,
        mensajeError: 'No se pudo publicar la orden. ${FalloApp.mensajeDe(err)}',
      ));
    }
  }
}
