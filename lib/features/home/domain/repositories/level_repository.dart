import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/level_entity.dart';
import '../entities/flashcard_entity.dart';
import '../entities/quiz_entity.dart'; // <--- NUEVO IMPORT

class LevelRepository {
  final SupabaseClient supabase;

  LevelRepository(this.supabase);

  /// Obtiene la lista de niveles disponibles para un documento específico.
  Future<List<LevelEntity>> getLevelsForDocument(String docId) async {
    try {
      // 1. Verificar si hay Flashcards
      final flashcardsData = await supabase
          .from('flashcards')
          .select('id')
          .eq('document_id', docId)
          .limit(1);
      
      // 2. Verificar si hay Quizzes
      final quizzesData = await supabase
          .from('quizzes')
          .select('id')
          .eq('document_id', docId)
          .limit(1);

      List<LevelEntity> levels = [];

      // --- NIVEL 1: CONCEPTOS CLAVE (Flashcards) ---
      if (flashcardsData.isNotEmpty) {
        levels.add(const LevelEntity(
          id: 'lvl_1_flash',
          title: 'Conceptos Clave',
          type: LevelType.flashcards,
          isLocked: false, 
          difficulty: 1,
        ));
      }

      // --- NIVEL 2: PRUEBA DE CONOCIMIENTO (Quiz) ---
      if (quizzesData.isNotEmpty) {
        levels.add(const LevelEntity(
          id: 'lvl_2_quiz',
          title: 'Prueba de Conocimiento',
          type: LevelType.quiz,
          isLocked: false, // Puedes cambiar esto a true si quieres obligar a pasar el nivel 1 primero
          difficulty: 2,
        ));
      }

      return levels;

    } catch (e) {
      throw Exception('Error al cargar niveles: $e');
    }
  }

  /// Obtiene todas las flashcards de un documento.
  Future<List<FlashcardEntity>> getFlashcards(String docId) async {
    try {
      final response = await supabase
          .from('flashcards')
          .select()
          .eq('document_id', docId);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => FlashcardEntity.fromMap(json)).toList();

    } catch (e) {
      throw Exception('Error al obtener las flashcards: $e');
    }
  }

  /// Obtiene todas las preguntas del Quiz para un documento.
  /// (NUEVO MÉTODO)
  Future<List<QuizEntity>> getQuizzes(String docId) async {
    try {
      final response = await supabase
          .from('quizzes')
          .select()
          .eq('document_id', docId);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => QuizEntity.fromMap(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener los quizzes: $e');
    }
  }
}