import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../models/user_model.dart';

// Interfaz del DataSource
abstract class AuthRemoteDataSource {
  Future<UserModel> loginWithEmail(String email, String password);
  Future<UserModel> registerWithEmail(String email, String password, String username);
  Future<void> logout();
  Future<void> addXp(int amount); // <--- NUEVO
}

// Implementación Real
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<UserModel> loginWithEmail(String email, String password) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const ServerFailure('El usuario es nulo después del login');
      }

      return UserModel.fromSupabaseUser(response.user!);
    } on AuthException catch (e) {
      // AuthException es un error específico de Supabase (ej: contraseña incorrecta)
      throw ServerFailure(e.message);
    } catch (e) {
      throw const ServerFailure('Error desconocido al iniciar sesión');
    }
  }

  @override
  Future<UserModel> registerWithEmail(String email, String password, String username) async {
    try {
      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'username': username}, // Esto se guarda en user_metadata
      );

      if (response.user == null) {
        throw const ServerFailure('Error al registrar usuario');
      }

      return UserModel.fromSupabaseUser(response.user!);
    } on AuthException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw const ServerFailure('Error desconocido al registrarse');
    }
  }
  
  @override
  Future<void> logout() async {
    await supabaseClient.auth.signOut();
  }
  
  @override
  Future<void> addXp(int amount) async {
    await supabaseClient.rpc('add_xp', params: {'amount': amount});
  }
}