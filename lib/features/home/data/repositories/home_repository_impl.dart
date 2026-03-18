// Importacion de la libreria estandar de Dart para el manejo de archivos fisicos.
import 'dart:io';

// Importacion de dartz para el manejo funcional de excepciones usando Either.
import 'package:dartz/dartz.dart';

// Importacion de los modelos de fallas personalizados de la aplicacion.
import '../../../../core/errors/failures.dart';

// Importaciones de las capas de dominio y acceso a datos remoto.
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

// Importacion del cliente de Supabase para operaciones directas en la base de datos.
import 'package:supabase_flutter/supabase_flutter.dart';

// Implementacion concreta del repositorio para el modulo Home.
// Cumple el contrato definido en HomeRepository actuando como adaptador entre la capa
// de presentacion (BLoC) y los origenes de datos.
class HomeRepositoryImpl implements HomeRepository {
  
  // Dependencia del data source remoto inyectada a traves del constructor.
  final HomeRemoteDataSource remoteDataSource;

  HomeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, DocumentEntity>> uploadDocument(File file, String fileName) async {
    try {
      // Delega la logica de subida del archivo al data source remoto.
      final document = await remoteDataSource.uploadDocument(file, fileName);
      
      // Retorna el resultado exitoso empaquetado en el lado derecho de Either.
      return Right(document);
    } on Failure catch (e) {
      // Captura excepciones de negocio conocidas y las propaga en el lado izquierdo.
      return Left(e);
    } catch (e) {
      // Fallback para atrapar cualquier excepcion no controlada y transformarla en un ServerFailure.
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DocumentEntity>>> getMyDocuments() async {
    try {
      // Solicita el listado de documentos asociados al usuario actual.
      final documents = await remoteDataSource.getMyDocuments();
      
      // Retorna la lista en caso de exito.
      return Right(documents);
    } on Failure catch (e) {
      // Propaga el error funcional hacia las capas superiores.
      return Left(e);
    }
  }

  @override
  Future<Either<Failure, void>> deleteDocument(String documentId) async {
    try {
      // Usamos Supabase.instance.client en lugar de solo supabase
      // Ejecuta la eliminacion del registro directamente contra la tabla 'documents'.
      await Supabase.instance.client
          .from('documents')
          .delete()
          .eq('id', documentId);
          
      // Al ser una operacion void, retorna null empaquetado como exito.
      return const Right(null);
    } catch (e) {
      // Captura y formatea cualquier error derivado de la operacion de borrado.
      return Left(ServerFailure('Error al eliminar el documento: $e'));
    }
  }
}