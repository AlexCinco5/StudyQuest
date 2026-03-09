import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/level_entity.dart';
import '../entities/flashcard_entity.dart';
import '../entities/quiz_entity.dart';

class LevelRepository {
  final SupabaseClient supabase;

  LevelRepository(this.supabase);

  /// Obtiene la lista de niveles dinámicos desde la tabla 'topics'
  Future<List<LevelEntity>> getLevelsForDocument(String docId) async {
    try {
      final response = await supabase
          .from('topics')
          .select()
          .eq('document_id', docId)
          .order('order_index', ascending: true);

      final List<dynamic> topicsData = response as List<dynamic>;
      List<LevelEntity> levels = [];

      if (topicsData.isNotEmpty) {
        bool previousCompleted = true; // El Nivel 1 SIEMPRE está desbloqueado

        for (int i = 0; i < topicsData.length; i++) {
          final topic = topicsData[i];
          final isFlashcard = i % 2 == 0;
          final isCompleted = topic['is_completed'] == true;

          levels.add(LevelEntity(
            id: topic['id'].toString(),
            title: topic['title'].toString(),
            type: isFlashcard ? LevelType.flashcards : LevelType.quiz,
            isLocked: !previousCompleted, // Se bloquea si el ANTERIOR no está completo
            difficulty: i + 1,
          ));

          // Para la siguiente vuelta del ciclo, el "anterior" será este nivel
          previousCompleted = isCompleted;
        }
      } else {
        // PLAN B (Documentos viejos)
        final flashcardsData = await supabase.from('flashcards').select('id').eq('document_id', docId).limit(1);
        final quizzesData = await supabase.from('quizzes').select('id').eq('document_id', docId).limit(1);

        if (flashcardsData.isNotEmpty) {
          levels.add(const LevelEntity(id: 'lvl_1_flash', title: 'Conceptos Clave', type: LevelType.flashcards, isLocked: false, difficulty: 1));
        }
        if (quizzesData.isNotEmpty) {
          levels.add(const LevelEntity(id: 'lvl_2_quiz', title: 'Prueba de Conocimiento', type: LevelType.quiz, isLocked: false, difficulty: 2));
        }
      }

      return levels;
    } catch (e) {
      throw Exception('Error al cargar niveles: $e');
    }
  }

  /// Marca un tema como completado en la base de datos
  Future<void> markLevelCompleted(String topicId) async {
    try {
      if (topicId.startsWith('lvl_')) return; // Ignorar PDFs viejos
      
      await supabase
          .from('topics')
          .update({'is_completed': true})
          .eq('id', topicId);
    } catch (e) {
      print('Error al marcar nivel como completado: $e');
    }
  }

  /// Obtiene las flashcards de un documento y tema en específico.
  Future<List<FlashcardEntity>> getFlashcards(String docId, String topicId) async {
    try {
      if (topicId.startsWith('lvl_')) {
        final response = await supabase
            .from('flashcards')
            .select()
            .eq('document_id', docId);
        
        final List<dynamic> data = response as List<dynamic>;
        return data.map((json) => FlashcardEntity.fromMap(json)).toList();
      } else {
        final response = await supabase
            .from('flashcards')
            .select()
            .eq('topic_id', topicId);

        final List<dynamic> data = response as List<dynamic>;
        
        if (data.isEmpty) {
           final fallbackResponse = await supabase
            .from('flashcards')
            .select()
            .eq('document_id', docId);
           final List<dynamic> fallbackData = fallbackResponse as List<dynamic>;
           return fallbackData.map((json) => FlashcardEntity.fromMap(json)).toList();
        }

        return data.map((json) => FlashcardEntity.fromMap(json)).toList();
      }
    } catch (e) {
      throw Exception('Error al obtener las flashcards: $e');
    }
  }

  /// Obtiene las preguntas del Quiz para un documento y tema en específico.
  Future<List<QuizEntity>> getQuizzes(String docId, String topicId) async {
    try {
      if (topicId.startsWith('lvl_')) {
        final response = await supabase
            .from('quizzes')
            .select()
            .eq('document_id', docId);
        final List<dynamic> data = response as List<dynamic>;
        return data.map((json) => QuizEntity.fromMap(json)).toList();
      } else {
        final response = await supabase
            .from('quizzes')
            .select()
            .eq('topic_id', topicId);

        final List<dynamic> data = response as List<dynamic>;
        
        if (data.isEmpty) {
           final fallbackResponse = await supabase
            .from('quizzes')
            .select()
            .eq('document_id', docId);
           final List<dynamic> fallbackData = fallbackResponse as List<dynamic>;
           return fallbackData.map((json) => QuizEntity.fromMap(json)).toList();
        }

        return data.map((json) => QuizEntity.fromMap(json)).toList();
      }
    } catch (e) {
      throw Exception('Error al obtener los quizzes: $e');
    }
  }
}