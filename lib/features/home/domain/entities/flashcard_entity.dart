class FlashcardEntity {
  final String id;
  final String front; // Pregunta
  final String back;  // Respuesta

  FlashcardEntity({
    required this.id,
    required this.front,
    required this.back,
  });

  // Constructor para convertir desde Supabase
  factory FlashcardEntity.fromMap(Map<String, dynamic> map) {
    return FlashcardEntity(
      id: map['id'] as String,
      front: map['front_text'] ?? 'Sin texto',
      back: map['back_text'] ?? 'Sin respuesta',
    );
  }
}