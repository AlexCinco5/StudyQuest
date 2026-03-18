// Importamos 'dartz', una libreria de programacion funcional que nos permite usar 'Either'.
// 'Either' actua como una caja fuerte que obliga al programador a manejar dos posibles resultados:
// un error (Left) o un exito (Right), previniendo que la aplicacion crashee sorpresivamente.
import 'package:dartz/dartz.dart';

// Importamos nuestros manejadores de errores, entidades y fuentes de datos.
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../../domain/entities/profile_entity.dart';

// Esta clase implementa el AuthRepository (el contrato puro de dominio).
// Actua como el intermediario (o fachada) entre los datos crudos que vienen de internet
// y el BLoC que maneja la interfaz de usuario.
class AuthRepositoryImpl implements AuthRepository {
  // Inyectamos la fuente de datos remota (quien realmente habla con Supabase).
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  // La firma de la funcion promete devolver una caja 'Either'. 
  // Dentro puede haber un Failure (si falla) o un UserEntity (si tiene exito).
  Future<Either<Failure, UserEntity>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Le delegamos el trabajo pesado a la fuente de datos remota.
      final user = await remoteDataSource.loginWithEmail(email, password);
      // Exito: Retornamos el lado DERECHO (Right) de la caja con los datos del usuario.
      return Right(user);
    } on Failure catch (e) {
      // Falla controlada: Si atrapamos un Failure especifico, lo metemos en el lado IZQUIERDO (Left).
      return Left(e);
    } catch (e) {
      // Falla generica: Si algo explota (ej. falta de RAM, error nativo), empaquetamos un error generico en el Left.
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
      // Intenta registrar llamando a la fuente remota.
      final user = await remoteDataSource.registerWithEmail(email, password, username);
      // Empaqueta el exito en el lado derecho.
      return Right(user);
    } on Failure catch (e) {
      // Empaqueta el fallo en el lado izquierdo.
      return Left(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Pide cerrar sesion en el servidor remoto.
      await remoteDataSource.logout();
    } catch (e) {
      // En operaciones de logout, las fallas suelen ser ignoradas (ej. el token ya habia expirado)
      // para asegurar que la app limpie el estado local de todas formas.
    }
  }

  @override
  Future<void> addXp(int amount) async {
    try {
      // Delega la operacion de sumar experiencia y calcular racha a la capa de datos remota.
      await remoteDataSource.addXp(amount);
    } catch (e) {
      // Loguea el error interno, pero absorbe la excepcion silenciosamente.
      // Razon: Si falla la suma de XP por mala conexion, no queremos interrumpir la pantalla 
      // de "Nivel Completado" del usuario con un popup de error tecnico.
      print("Error sumando XP: $e");
    }
  }

  @override
  Future<Either<Failure, ProfileEntity>> getCurrentProfile() async {
    try {
      // Llamamos al remoteDataSource para extraer el diccionario crudo (JSON/Map) del perfil.
      final data = await remoteDataSource.getCurrentProfile();
      
      // Convertimos el JSON crudo a nuestra entidad limpia y segura de Dart (ProfileEntity),
      // y la empaquetamos en el lado derecho del exito.
      return Right(ProfileEntity.fromMap(data));
    } catch (e) {
      // Si algo falla, atrapamos el error, lo convertimos a texto y lo enviamos en el lado izquierdo.
      return Left(ServerFailure(e.toString()));
    }
  }
}