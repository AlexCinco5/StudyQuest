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
      // 1. Consultamos la nueva tabla de temas generada por la IA
      final response = await supabase
          .from('topics')
          .select()
          .eq('document_id', docId)
          .order('order_index', ascending: true);

      final List<dynamic> topicsData = response as List<dynamic>;
      List<LevelEntity> levels = [];

      // 2. Si la IA generó temas, creamos un nivel por cada tema
      if (topicsData.isNotEmpty) {
        for (int i = 0; i < topicsData.length; i++) {
          final topic = topicsData[i];
          
          // Alternamos los juegos: el tema 1 será Flashcards, el tema 2 Quiz, el 3 Flashcards...
          final isFlashcard = i % 2 == 0;

          levels.add(LevelEntity(
            id: topic['id'].toString(), // Usamos el ID real del tema
            title: topic['title'].toString(), // ¡El título real que sacó la IA!
            type: isFlashcard ? LevelType.flashcards : LevelType.quiz,
            isLocked: false, // Los dejamos desbloqueados para que puedas probarlos
            difficulty: i + 1,
          ));
        }
      } 
      // 3. PLAN B: Si es un PDF viejo (de antes de mejorar la IA), usamos tu lógica original
      else {
        final flashcardsData = await supabase.from('flashcards').select('id').eq('document_id', docId).limit(1);
        final quizzesData = await supabase.from('quizzes').select('id').eq('document_id', docId).limit(1);

        if (flashcardsData.isNotEmpty) {
          levels.add(const LevelEntity(
            id: 'lvl_1_flash',
            title: 'Conceptos Clave',
            type: LevelType.flashcards,
            isLocked: false,
            difficulty: 1,
          ));
        }
        if (quizzesData.isNotEmpty) {
          levels.add(const LevelEntity(
            id: 'lvl_2_quiz',
            title: 'Prueba de Conocimiento',
            type: LevelType.quiz,
            isLocked: false,
            difficulty: 2,
          ));
        }
      }

      return levels;

    } catch (e) {
      throw Exception('Error al cargar niveles: $e');
    }
  }

  /// Obtiene las flashcards de un documento y tema en específico.
  Future<List<FlashcardEntity>> getFlashcards(String docId, String topicId) async {
    try {
      // PLAN A: Es un PDF viejo o el topicId es genérico
      if (topicId.startsWith('lvl_')) {
        final response = await supabase
            .from('flashcards')
            .select()
            .eq('document_id', docId);
        
        final List<dynamic> data = response as List<dynamic>;
        return data.map((json) => FlashcardEntity.fromMap(json)).toList();
      } 
      // PLAN B: Es un PDF nuevo con temas reales
      else {
        final response = await supabase
            .from('flashcards')
            .select()
            .eq('topic_id', topicId); // Buscamos por el tema específico

        final List<dynamic> data = response as List<dynamic>;
        
        // Si no encontró nada por tema (tal vez la IA no generó flashcards para este tema en particular), 
        // traemos todas las del documento como fallback para que no se quede vacío.
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