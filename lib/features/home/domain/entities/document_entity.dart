import 'package:equatable/equatable.dart';

// Entidad de negocio que representa un documento (PDF) procesado en el sistema.
// Hereda de Equatable para permitir una comparacion por valor eficiente en la capa de presentacion,
// minimizando los redibujados del widget tree.
class DocumentEntity extends Equatable {
  // Identificador unico del documento generado por la base de datos.
  final String id;
  
  // Nombre del archivo original o titulo inferido por el sistema.
  final String title;
  
  // URL de acceso al archivo fisico alojado en el storage remoto.
  final String fileUrl;
  
  // Resumen del contenido generado asincronamente por la IA.
  // Se define como nullable (String?) porque durante la fase de procesamiento inicial
  // este dato aun no estara disponible.
  final String? summary; 
  
  // Indicador del estado actual en el ciclo de vida del documento.
  // Valores esperados definen el flujo de la UI: 'processing', 'ready', 'error'.
  final String status;   
  
  // Marca temporal exacta de cuando el documento fue registrado.
  final DateTime uploadDate;

  // Constructor inmutable. Garantiza que una vez instanciada la entidad, 
  // sus valores de solo lectura no sean alterados inadvertidamente.
  const DocumentEntity({
    required this.id,
    required this.title,
    required this.fileUrl,
    this.summary,
    required this.status,
    required this.uploadDate,
  });

  // Sobrescritura de la evaluacion de igualdad.
  // Se excluyen explicitamente 'summary' y 'uploadDate' de las propiedades de comparacion.
  // Esto instruye a los BLoCs a emitir nuevos estados de UI unicamente si cambian 
  // identificadores, rutas o estados criticos, ignorando metadatos.
  @override
  List<Object?> get props => [id, title, fileUrl, status];
}