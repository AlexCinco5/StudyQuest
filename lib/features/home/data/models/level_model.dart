import '../../domain/entities/level_entity.dart';

class LevelModel extends LevelEntity {
  LevelModel({
    required super.id,
    required super.title,
    required super.type,
    required super.isLocked,
  });

  factory LevelModel.fromTopicJson(Map<String, dynamic> json, int index) {
    // La IA generó temas (topics). Convertimos cada tema en un "Nivel"
    // Por ahora, para simplificar, el Nivel 1 será Flashcards, el Nivel 2 Quiz, etc.
    // o puedes hacer que todos sean un mix. Aquí lo haremos alternado:
    final isFlashcard = index % 2 == 0; 
    
    return LevelModel(
      id: json['id'] as String,
      title: json['title'] as String,
      type: isFlashcard ? LevelType.flashcards : LevelType.quiz,
      // Por ahora, desbloqueamos el primero, bloqueamos el resto
      isLocked: index > 0, 
    );
  }
}