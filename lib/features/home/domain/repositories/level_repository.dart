// Importacion del cliente oficial para conectar la app con nuestra base de datos en Supabase.
import 'package:supabase_flutter/supabase_flutter.dart';

// Importacion de los moldes que estructuran un nivel, una tarjeta de memoria y una pregunta.
import '../entities/level_entity.dart';
import '../entities/flashcard_entity.dart';
import '../entities/quiz_entity.dart';

// Clase encargada de toda la logica relacionada con los niveles (temas) dentro de un documento.
class LevelRepository {
  // Guarda la conexion directa a la base de datos.
  final SupabaseClient supabase;

  // Al crear este repositorio, es obligatorio darle la llave de conexion a Supabase.
  LevelRepository(this.supabase);

  // Promesa para buscar todos los temas que la IA extrajo de un PDF en particular.
  Future<List<LevelEntity>> getLevelsForDocument(String docId) async {
    try {
      // 1. Busca en la tabla 'topics' todos los temas que pertenezcan a este documento,
      // ordenados del primero al ultimo segun su indice.
      final response = await supabase
          .from('topics')
          .select()
          .eq('document_id', docId)
          .order('order_index', ascending: true);

      // Convierte la respuesta en una lista que Dart pueda entender.
      final List<dynamic> topicsData = response as List<dynamic>;
      List<LevelEntity> levels = [];

      // Si la IA si encontro temas en este PDF...
      if (topicsData.isNotEmpty) {
        // Regla del juego: El primer nivel siempre estara abierto para poder empezar.
        bool previousCompleted = true; 

        // Recorre cada tema encontrado, uno por uno.
        for (int i = 0; i < topicsData.length; i++) {
          final topic = topicsData[i];
          
          // Magia simple: los niveles pares (0, 2, 4...) seran Flashcards, los impares seran Quizzes.
          final isFlashcard = i % 2 == 0;
          
          // Revisa si la base de datos dice que este nivel ya fue pasado por el usuario.
          final isCompleted = topic['is_completed'] == true;

          // Construye la entidad del nivel y la agrega a la lista final.
          levels.add(LevelEntity(
            id: topic['id'].toString(),
            title: topic['title'].toString(),
            type: isFlashcard ? LevelType.flashcards : LevelType.quiz,
            
            // Aqui esta la logica de bloqueo: 
            // Si el nivel ANTERIOR no se ha completado, este nivel aparece con candado.
            isLocked: !previousCompleted, 
            difficulty: i + 1,
          ));

          // Actualiza el estado para que, en la siguiente vuelta del ciclo, 
          // el nivel que sigue sepa si este se completo o no.
          previousCompleted = isCompleted;
        }
      } else {
        // PLAN B: Esto es un rescavidas para los PDFs muy viejos que se subieron 
        // antes de que programaramos la funcion de los "temas" (topics).
        // Si no hay temas, busca si al menos hay flashcards sueltas o preguntas sueltas.
        final flashcardsData = await supabase.from('flashcards').select('id').eq('document_id', docId).limit(1);
        final quizzesData = await supabase.from('quizzes').select('id').eq('document_id', docId).limit(1);

        // Si encontro tarjetas, arma un nivel basico de flashcards.
        if (flashcardsData.isNotEmpty) {
          levels.add(const LevelEntity(id: 'lvl_1_flash', title: 'Conceptos Clave', type: LevelType.flashcards, isLocked: false, difficulty: 1));
        }
        // Si encontro preguntas, arma un nivel basico de examen.
        if (quizzesData.isNotEmpty) {
          levels.add(const LevelEntity(id: 'lvl_2_quiz', title: 'Prueba de Conocimiento', type: LevelType.quiz, isLocked: false, difficulty: 2));
        }
      }

      // Devuelve la lista completa de niveles (nuevos o viejos) lista para mostrarse en pantalla.
      return levels;
    } catch (e) {
      // Si el internet falla, arroja un error general.
      throw Exception('Error al cargar niveles: $e');
    }
  }

  // Promesa para registrar en internet que un usuario gano un nivel.
  Future<void> markLevelCompleted(String topicId) async {
    try {
      // Si el nivel tiene este nombre inventado ('lvl_...'), significa que es del "Plan B" (PDF viejo),
      // asi que ignoramos guardar el progreso porque esos niveles no existen en la base de datos real.
      if (topicId.startsWith('lvl_')) return; 
      
      // Le dice a Supabase: "Busca el tema con este ID y cambiale el estado de completado a verdadero".
      await supabase
          .from('topics')
          .update({'is_completed': true})
          .eq('id', topicId);
    } catch (e) {
      // Si falla, solo lo imprime para los programadores, pero no arruina la experiencia del usuario.
      print('Error al marcar nivel como completado: $e');
    }
  }

  // Promesa para descargar las tarjetas de memoria de un tema especifico.
  Future<List<FlashcardEntity>> getFlashcards(String docId, String topicId) async {
    try {
      // Si es un nivel falso de un PDF viejo, traete TODAS las flashcards de ese PDF.
      if (topicId.startsWith('lvl_')) {
        final response = await supabase
            .from('flashcards')
            .select()
            .eq('document_id', docId);
        
        final List<dynamic> data = response as List<dynamic>;
        // Transforma el monton de JSONs en objetos ordenados de Dart.
        return data.map((json) => FlashcardEntity.fromMap(json)).toList();
      } else {
        // Si es un nivel normal, busca solo las tarjetas amarradas a ese tema en particular.
        final response = await supabase
            .from('flashcards')
            .select()
            .eq('topic_id', topicId);

        final List<dynamic> data = response as List<dynamic>;
        
        // Otro rescavidas: Si por alguna razon el tema no tenia tarjetas propias, 
        // trata de buscar cualquier tarjeta huerfana que pertenezca al PDF completo para que el juego no falle.
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

  // Promesa para descargar las preguntas de opcion multiple de un tema especifico.
  // Funciona exactamente igual que la descarga de flashcards, pero consultando la tabla 'quizzes'.
  Future<List<QuizEntity>> getQuizzes(String docId, String topicId) async {
    try {
      // Modo retro-compatibilidad: Trae todo si es un nivel de "Plan B".
      if (topicId.startsWith('lvl_')) {
        final response = await supabase
            .from('quizzes')
            .select()
            .eq('document_id', docId);
        final List<dynamic> data = response as List<dynamic>;
        return data.map((json) => QuizEntity.fromMap(json)).toList();
      } else {
        // Modo normal: Trae solo las preguntas de este tema.
        final response = await supabase
            .from('quizzes')
            .select()
            .eq('topic_id', topicId);

        final List<dynamic> data = response as List<dynamic>;
        
        // Salvavidas: Busca a nivel general si este tema especifico estaba vacio.
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