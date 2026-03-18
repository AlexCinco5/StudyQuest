// Entidad que abstrae un reactivo de evaluacion tipo opcion multiple.
class QuizEntity {
  // Identificador unico del reactivo.
  final String id;
  
  // Enunciado descriptivo del problema a resolver.
  final String question;
  
  // Arreglo indexado de cadenas conteniendo los posibles distractores y la clave.
  final List<String> options;
  
  // Referencia posicional (index zero-based) dentro del arreglo 'options' 
  // que señala la respuesta correcta evaluable por el motor logico.
  final int correctIndex;
  
  // Cadena de texto didactica expuesta post-evaluacion para consolidar el conocimiento.
  final String explanation;

  QuizEntity({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  // Factory method para deserializacion estructurada desde origenes dinámicos.
  factory QuizEntity.fromMap(Map<String, dynamic> map) {
    return QuizEntity(
      // Casting explicito estandar de identificadores.
      id: map['id'] as String,
      question: map['question_text'] ?? 'Sin pregunta',
      
      // Resolucion critica de tipos de colecciones.
      // La API frecuentemente expone arrays JSON como listas no tipadas (List<dynamic>).
      // Se emplea List<String>.from para iterar e inferir cada elemento estrictamente como cadena,
      // inyectando una lista vacia [] pre-procesamiento si el nodo original viene nulo.
      options: List<String>.from(map['options'] ?? []),
      
      // Casting requerido para operaciones algebraicas posteriores de calificacion.
      correctIndex: map['correct_answer_index'] as int,
      
      // Normalizacion de valores nulos hacia cadenas vacias para facilitar 
      // chequeos de visibilidad en el renderizado de la interfaz.
      explanation: map['explanation'] ?? '',
    );
  }
}