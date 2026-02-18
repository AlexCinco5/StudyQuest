import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/level_entity.dart';
import '../entities/flashcard_entity.dart';

class LevelRepository {
  final SupabaseClient supabase;

  LevelRepository(this.supabase);

  /// Obtiene la lista de niveles disponibles para un documento específico.
  /// Verifica en la base de datos si existen flashcards o quizzes generados.
  Future<List<LevelEntity>> getLevelsForDocument(String docId) async {
    try {
      // 1. Verificar si hay Flashcards (Consultamos solo 1 para saber si existen)
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
      // Si existen flashcards en la DB, agregamos este nivel al mapa
      if (flashcardsData.isNotEmpty) {
        levels.add(const LevelEntity(
          id: 'lvl_1_flash',
          title: 'Conceptos Clave',
          type: LevelType.flashcards,
          isLocked: false, // El primer nivel siempre está desbloqueado
          difficulty: 1,
        ));
      }

      // --- NIVEL 2: PRUEBA DE CONOCIMIENTO (Quiz) ---
      // Si existen quizzes en la DB, agregamos este nivel
      if (quizzesData.isNotEmpty) {
        levels.add(const LevelEntity(
          id: 'lvl_2_quiz',
          title: 'Prueba de Conocimiento',
          type: LevelType.quiz,
          isLocked: false, // Por ahora desbloqueado para pruebas (luego lo bloquearemos hasta pasar el nivel 1)
          difficulty: 2,
        ));
      }

      // En el futuro aquí podrías agregar lógica para 'Exámenes Finales', 'Retos', etc.

      return levels;

    } catch (e) {
      // Si hay error (ej: sin conexión), lanzamos la excepción para que el Bloc la maneje
      throw Exception('Error al cargar niveles: $e');
    }
  }

  /// Obtiene todas las flashcards de un documento para empezar a jugar.
  Future<List<FlashcardEntity>> getFlashcards(String docId) async {
    try {
      final response = await supabase
          .from('flashcards')
          .select() // Trae todas las columnas (id, front_text, back_text, etc.)
          .eq('document_id', docId);

      // Convertimos la lista de mapas JSON (List<Map<String, dynamic>>) a objetos FlashcardEntity
      final List<dynamic> data = response as List<dynamic>;
      
      return data.map((json) => FlashcardEntity.fromMap(json)).toList();

    } catch (e) {
      throw Exception('Error al obtener las flashcards: $e');
    }
  }
}