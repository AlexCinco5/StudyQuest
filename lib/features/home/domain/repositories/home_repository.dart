import 'dart:io';
import 'package:dartz/dartz.dart'; // Para manejar errores (Either)
import '../../../../core/errors/failures.dart';
import '../entities/document_entity.dart';

abstract class HomeRepository {
  // Obtener la lista de mundos guardados
  Future<Either<Failure, List<DocumentEntity>>> getMyDocuments();
  
  // Subir un nuevo PDF
  Future<Either<Failure, DocumentEntity>> uploadDocument(File file, String fileName);
}