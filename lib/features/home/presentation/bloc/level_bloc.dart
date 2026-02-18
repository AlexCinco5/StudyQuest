import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/level_entity.dart';
import '../../domain/repositories/level_repository.dart';

// Eventos
abstract class LevelEvent {}
class LoadLevels extends LevelEvent {
  final String documentId;
  LoadLevels(this.documentId);
}

// Estados
abstract class LevelState {}
class LevelInitial extends LevelState {}
class LevelLoading extends LevelState {}
class LevelLoaded extends LevelState {
  final List<LevelEntity> levels;
  LevelLoaded(this.levels);
}
class LevelError extends LevelState {
  final String message;
  LevelError(this.message);
}

// BLoC Principal
class LevelBloc extends Bloc<LevelEvent, LevelState> {
  final LevelRepository repository;

  LevelBloc(this.repository) : super(LevelInitial()) {
    on<LoadLevels>((event, emit) async {
      emit(LevelLoading());
      try {
        final levels = await repository.getLevelsForDocument(event.documentId);
        emit(LevelLoaded(levels));
      } catch (e) {
        emit(LevelError("Error cargando niveles: $e"));
      }
    });
  }
}