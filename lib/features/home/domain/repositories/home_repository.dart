// Importacion basica para manejar archivos guardados en el telefono.
import 'dart:io';

// Importacion de dartz, una herramienta que nos obliga a programar pensando 
// en que las cosas pueden salir bien o pueden fallar, evitando cierres inesperados de la app.
import 'package:dartz/dartz.dart'; 

// Importacion de nuestro molde para los errores de la app.
import '../../../../core/errors/failures.dart';

// Importacion del molde de datos que representa un archivo PDF en nuestro sistema.
import '../entities/document_entity.dart';

// Definicion de la clase abstracta (el contrato) para la pantalla principal.
// Este contrato dicta que cualquier clase que lo firme debe saber hacer estas tres cosas,
// sin importar si guarda los datos en internet o en el telefono.
abstract class HomeRepository {
  
  // Promesa para obtener la lista de documentos (o "mundos de estudio") del usuario.
  // Devuelve una caja (Either) que contiene un error (Failure) o la lista de documentos.
  Future<Either<Failure, List<DocumentEntity>>> getMyDocuments();
  
  // Promesa para subir un nuevo archivo PDF.
  // Pide el archivo fisico y su nombre, y devuelve una caja con error o el documento recien creado.
  Future<Either<Failure, DocumentEntity>> uploadDocument(File file, String fileName);

  // Promesa para borrar un documento que ya no queremos.
  // Pide el ID del documento. Devuelve un error o simplemente nada (void) si el borrado fue exitoso.
  Future<Either<Failure, void>> deleteDocument(String documentId);
}