class QuizEntity {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  QuizEntity({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuizEntity.fromMap(Map<String, dynamic> map) {
    return QuizEntity(
      id: map['id'] as String,
      question: map['question_text'] ?? 'Sin pregunta',
      // Supabase devuelve las opciones como una lista dinámica, hay que asegurarnos de que sean Strings
      options: List<String>.from(map['options'] ?? []),
      correctIndex: map['correct_answer_index'] as int,
      explanation: map['explanation'] ?? '',
    );
  }
}