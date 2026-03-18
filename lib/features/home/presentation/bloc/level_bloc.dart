import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/level_entity.dart';
import '../../domain/repositories/level_repository.dart';

// --- EVENTOS ---
// Clase base para definir todas las interacciones del usuario en la pantalla de niveles.
abstract class LevelEvent {}

// Evento disparado para solicitar a la base de datos la lista de niveles disponibles
// para un documento especifico.
class LoadLevels extends LevelEvent {
  final String documentId;
  LoadLevels(this.documentId);
}

// --- ESTADOS ---
// Clase base que representa los diferentes estados visuales de la pantalla de niveles.
abstract class LevelState {}

// Estado inicial, antes de que se solicite la carga de datos.
class LevelInitial extends LevelState {}

// Estado emitido durante la consulta a la base de datos para mostrar un indicador de progreso.
class LevelLoading extends LevelState {}

// Estado de exito que contiene la lista ya procesada de los niveles, lista para dibujarse.
class LevelLoaded extends LevelState {
  final List<LevelEntity> levels;
  LevelLoaded(this.levels);
}

// Estado emitido si algo sale mal (como perdida de conexion) para mostrar un mensaje al usuario.
class LevelError extends LevelState {
  final String message;
  LevelError(this.message);
}

// --- BLoC Principal ---
// Cerebro logico que reacciona a los LevelEvents y escupe LevelStates.
class LevelBloc extends Bloc<LevelEvent, LevelState> {
  // Conexion directa con la capa de datos.
  final LevelRepository repository;

  // Al crear el BLoC, iniciamos en estado "LevelInitial".
  LevelBloc(this.repository) : super(LevelInitial()) {
    
    // Configuracion de la reaccion al evento "LoadLevels".
    on<LoadLevels>((event, emit) async {
      // 1. Avisa a la pantalla que empezo a buscar.
      emit(LevelLoading());
      try {
        // 2. Le pide al repositorio los niveles amarrados al ID del documento.
        final levels = await repository.getLevelsForDocument(event.documentId);
        // 3. Si todo salio bien, emite el estado cargado con los datos.
        emit(LevelLoaded(levels));
      } catch (e) {
        // 4. Si algo falla, emite el estado de error.
        emit(LevelError("Error cargando niveles: $e"));
      }
    });
  }
}