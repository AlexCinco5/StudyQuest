// Entidad central para el dominio de estudio mediante tarjetas de memoria.
// Modela la estructura conceptual independiente de implementaciones de infraestructura.
class FlashcardEntity {
  // Clave primaria de la tarjeta.
  final String id;
  
  // Texto expuesto en la cara principal (el anverso), tipicamente la incognita.
  final String front; 
  
  // Texto oculto en la cara posterior (el reverso), la resolucion o definicion.
  final String back;  

  FlashcardEntity({
    required this.id,
    required this.front,
    required this.back,
  });

  // Constructor tipo factory para instanciacion a partir de diccionarios de datos.
  // Actua como una capa de mapeo directo entre la respuesta de la API (JSON) y la entidad.
  factory FlashcardEntity.fromMap(Map<String, dynamic> map) {
    return FlashcardEntity(
      // Forzado de tipo para asegurar integridad referencial.
      id: map['id'] as String,
      
      // Aplicacion de valores fallback para mitigar inconsistencias o datos corruptos
      // en la capa de persistencia de Supabase sin romper la experiencia del usuario.
      front: map['front_text'] ?? 'Sin texto',
      back: map['back_text'] ?? 'Sin respuesta',
    );
  }
}