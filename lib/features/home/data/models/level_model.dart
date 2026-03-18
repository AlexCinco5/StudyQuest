import '../../domain/entities/level_entity.dart';

// Definicion del modelo de datos para un Nivel del mapa de aprendizaje.
// Extiende de LevelEntity, la representacion de negocio base.
class LevelModel extends LevelEntity {
  
  // Constructor del modelo.
  // Inyecta directamente las propiedades a la superclase (LevelEntity).
  LevelModel({
    required super.id,
    required super.title,
    required super.type,
    required super.isLocked,
  });

  // Factory constructor para crear un Nivel a partir de los datos crudos que genero la IA
  // y que guardamos en la tabla 'topics' de Supabase.
  factory LevelModel.fromTopicJson(Map<String, dynamic> json, int index) {
    // La logica de negocio dicta que los temas extraidos del PDF se transforman en "Niveles" jugables.
    // Para dar variedad al juego sin requerir logica de backend compleja, se alterna el tipo de nivel:
    // Los indices pares (0, 2, 4...) seran de tipo Flashcards.
    // Los indices impares (1, 3, 5...) seran de tipo Quiz.
    final isFlashcard = index % 2 == 0; 
    
    return LevelModel(
      // Mapeo del ID unico generado por Supabase.
      id: json['id'] as String,
      
      // Mapeo del titulo del tema sugerido por la IA.
      title: json['title'] as String,
      
      // Asignacion dinamica del tipo de nivel basado en el calculo par/impar de arriba.
      type: isFlashcard ? LevelType.flashcards : LevelType.quiz,
      
      // Logica de progresion inicial:
      // Solo el primer nivel (indice 0) inicia desbloqueado (isLocked: false).
      // Todos los niveles subsecuentes (indice > 0) inician bloqueados (isLocked: true)
      // forzando al usuario a jugar en orden secuencial.
      isLocked: index > 0, 
    );
  }
}