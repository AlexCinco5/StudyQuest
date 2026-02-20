import 'package:dartz/dartz.dart'; // Importante: Para usar Either
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

// Abstract class = Contrato
abstract class AuthRepository {
  
  // Future porque es asíncrono.
  // Either<Failure, UserEntity> significa:
  // "Esto va a devolver O una Falla (izquierda) O un Usuario (derecha)"
  // Agrega esto dentro de la clase abstracta
  Future<void> addXp(int amount);
  
  Future<Either<Failure, UserEntity>> loginWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> registerWithEmail({
    required String email,
    required String password,
    required String username,
  });

  Future<void> logout();
}