import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserEntity>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.loginWithEmail(email, password);
      // Éxito: Retornamos el lado DERECHO (Right) con el usuario
      return Right(user);
    } on Failure catch (e) {
      // Falla conocida: Retornamos el lado IZQUIERDO (Left) con el error
      return Left(e);
    } catch (e) {
      return const Left(ServerFailure('Error inesperado en el repositorio'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> registerWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final user = await remoteDataSource.registerWithEmail(email, password, username);
      return Right(user);
    } on Failure catch (e) {
      return Left(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (e) {
      // En logout a veces no importa tanto si falla, pero podríamos manejarlo
    }
  }

  // Al final de la clase, implementa el método
  @override
  Future<void> addXp(int amount) async {
    try {
      await remoteDataSource.addXp(amount);
    } catch (e) {
      print("Error sumando XP: $e");
      // No lanzamos error para no interrumpir la UI de "Felicidades"
    }
  }
}