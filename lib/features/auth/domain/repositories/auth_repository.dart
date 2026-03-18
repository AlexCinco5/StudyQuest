// Importamos 'dartz', una librería que nos permite usar el tipo 'Either'.
// 'Either' es una forma de programar que nos obliga a manejar explícitamente los errores,
// asegurando que una función devuelva un "Error" (lado izquierdo) o un "Éxito" (lado derecho).
import 'package:dartz/dartz.dart'; 

// Importamos nuestros moldes de errores (Failure) que definimos en otro archivo.
import '../../../../core/errors/failures.dart';

// Importamos la entidad de Usuario (UserEntity), que representa la información básica de la cuenta.
import '../entities/user_entity.dart';

// Importamos la entidad de Perfil (ProfileEntity), que contiene los datos del juego (XP, racha).
import '../entities/profile_entity.dart';

// Definimos el 'AuthRepository' como una clase abstracta.
// En arquitectura limpia, esto actúa como un "Contrato".
// Dice QUÉ operaciones se pueden hacer relacionadas a la cuenta del usuario, 
// pero NO dice CÓMO se van a hacer (no se mete con bases de datos ni internet aquí).
abstract class AuthRepository {
  
  // Promete buscar el perfil actual del usuario (sus puntos y racha).
  // Es 'Future' porque la respuesta no es inmediata (toma tiempo buscarla).
  // Devuelve 'Either<Failure, ProfileEntity>', lo que significa que el resultado
  // será forzosamente uno de dos: o falla devolviendo un error (Failure), 
  // o tiene éxito devolviendo el perfil (ProfileEntity).
  Future<Either<Failure, ProfileEntity>> getCurrentProfile();

  // Promete sumar experiencia a la cuenta del usuario.
  // Es 'Future<void>' porque hace su trabajo asincrónicamente pero no necesita devolver 
  // ninguna información de vuelta al terminar.
  Future<void> addXp(int amount);
  
  // Promete intentar iniciar sesión.
  // Pide obligatoriamente (required) un correo y una contraseña.
  // Si tiene éxito, devolverá los datos de la cuenta en un 'UserEntity' en el lado derecho del 'Either'.
  // Si falla, devolverá un 'Failure' en el lado izquierdo.
  Future<Either<Failure, UserEntity>> loginWithEmail({
    required String email,
    required String password,
  });

  // Promete intentar registrar una cuenta nueva.
  // Pide correo, contraseña y un nombre de usuario de forma obligatoria.
  // Al igual que el login, devuelve un error o el nuevo usuario creado usando 'Either'.
  Future<Either<Failure, UserEntity>> registerWithEmail({
    required String email,
    required String password,
    required String username,
  });

  // Promete cerrar la sesión actual en el dispositivo.
  // No devuelve ningún dato de confirmación (void).
  Future<void> logout();
}