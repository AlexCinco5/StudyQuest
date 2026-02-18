enum LevelType { flashcards, quiz, mixed, exam }

class LevelEntity {
  final String id;
  final String title;
  final LevelType type;
  final bool isLocked;
  final bool isCompleted;
  final int difficulty; // 1 a 5 estrellas

  const LevelEntity({
    required this.id,
    required this.title,
    required this.type,
    this.isLocked = false,
    this.isCompleted = false,
    this.difficulty = 1,
  });
}