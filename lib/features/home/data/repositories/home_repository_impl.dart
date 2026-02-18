import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;

  HomeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, DocumentEntity>> uploadDocument(File file, String fileName) async {
    try {
      final document = await remoteDataSource.uploadDocument(file, fileName);
      return Right(document);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DocumentEntity>>> getMyDocuments() async {
    try {
      final documents = await remoteDataSource.getMyDocuments();
      return Right(documents);
    } on Failure catch (e) {
      return Left(e);
    }
  }
}