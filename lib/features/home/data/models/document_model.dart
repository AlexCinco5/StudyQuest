import '../../domain/entities/document_entity.dart';

// Definicion del modelo de datos para un Documento.
// Extiende de DocumentEntity, que es la representacion abstracta del negocio.
// El modelo anade la capacidad de interactuar con fuentes de datos externas (JSON/Bases de datos).
class DocumentModel extends DocumentEntity {
  
  // Constructor del modelo.
  // Utiliza 'super' para inyectar directamente los valores en las propiedades de la clase padre.
  const DocumentModel({
    required super.id,
    required super.title,
    required super.fileUrl,
    super.summary,
    required super.status,
    required super.uploadDate,
  });

  // Factory constructor para deserializar datos.
  // Transforma un diccionario (Map) proveniente de Supabase en una instancia manejable de DocumentModel.
  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      // Mapeo directo de claves crudas del JSON a parametros de Dart.
      id: json['id'],
      title: json['title'],
      fileUrl: json['file_url'],
      
      // Manejo de discrepancia de nombres: la propiedad interna es 'summary',
      // pero en la base de datos la columna fue nombrada 'summary_text'.
      summary: json['summary_text'], 
      
      // Operador coalescente nulo (??). Si el documento no tiene un estado definido en BD,
      // se asume por defecto que esta en fase de 'processing'.
      status: json['status'] ?? 'processing',
      
      // Parseo del timestamp. Convierte la cadena de texto 'created_at' del formato ISO 8601
      // a un objeto DateTime nativo de Dart.
      uploadDate: DateTime.parse(json['created_at']),
    );
  }

  // Metodo de serializacion.
  // Convierte la instancia actual de DocumentModel de vuelta a un diccionario (Map).
  // Se utiliza para preparar los datos antes de realizar operaciones de Insercion o Actualizacion en Supabase.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'file_url': fileUrl,
      'status': status,
      // Exclusion intencional: no se envian campos gestionados automaticamente por la base de datos
      // como el 'id' (generado como UUID por Supabase) ni 'created_at' (asignado por default por la BD).
    };
  }
}