import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/fallos.dart';
import '../../domain/entities/preferencias_usuario.dart';
import '../../domain/usecases/preferencias_casos.dart';

enum EstadoAjustes { inicial, cargando, listo, guardando, errorCarga }

class AjustesState extends Equatable {
  final EstadoAjustes estado;
  final PreferenciasUsuario? preferencias;
  final String? error;
  const AjustesState({
    this.estado = EstadoAjustes.inicial,
    this.preferencias,
    this.error,
  });

  bool get guardando => estado == EstadoAjustes.guardando;

  @override
  List<Object?> get props => [estado, preferencias, error];
}

sealed class AjustesEvent {
  const AjustesEvent();
}

class AjustesCargados extends AjustesEvent {
  const AjustesCargados();
}

class PreferenciaCambiada extends AjustesEvent {
  final Preferencia campo;
  final bool valor;
  const PreferenciaCambiada(this.campo, this.valor);
}

/// Vive dentro de la ruta de Ajustes y está ligado al uid de esa sesión.
class AjustesBloc extends Bloc<AjustesEvent, AjustesState> {
  final String uid;
  final ObtenerPreferencias obtener;
  final CambiarPreferencia cambiar;

  AjustesBloc({required this.uid, required this.obtener, required this.cambiar})
    : super(const AjustesState()) {
    on<AjustesCargados>(_cargar);
    on<PreferenciaCambiada>(_guardar);
  }

  Future<void> _cargar(AjustesCargados e, Emitter<AjustesState> emit) async {
    if (state.guardando || state.estado == EstadoAjustes.cargando) return;
    emit(const AjustesState(estado: EstadoAjustes.cargando));
    try {
      final preferencias = await obtener.ejecutar(uid);
      if (emit.isDone) return;
      emit(
        AjustesState(estado: EstadoAjustes.listo, preferencias: preferencias),
      );
    } catch (e) {
      if (emit.isDone) return;
      emit(
        AjustesState(
          estado: EstadoAjustes.errorCarga,
          error: FalloApp.mensajeDe(e),
        ),
      );
    }
  }

  Future<void> _guardar(
    PreferenciaCambiada e,
    Emitter<AjustesState> emit,
  ) async {
    if (state.estado != EstadoAjustes.listo || state.preferencias == null) {
      return;
    }
    final anterior = state.preferencias!;
    if (anterior.valor(e.campo) == e.valor) return;
    emit(
      AjustesState(
        estado: EstadoAjustes.guardando,
        preferencias: anterior.cambiar(e.campo, e.valor),
      ),
    );
    try {
      final confirmadas = await cambiar.ejecutar(uid, e.campo, e.valor);
      if (emit.isDone) return;
      emit(
        AjustesState(estado: EstadoAjustes.listo, preferencias: confirmadas),
      );
    } catch (e) {
      if (emit.isDone) return;
      emit(
        AjustesState(
          estado: EstadoAjustes.listo,
          preferencias: anterior,
          error: FalloApp.mensajeDe(e),
        ),
      );
    }
  }
}
