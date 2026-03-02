import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../models/user_model.dart';

// Interfaz del DataSource
abstract class AuthRemoteDataSource {
  Future<UserModel> loginWithEmail(String email, String password);
  Future<UserModel> registerWithEmail(String email, String password, String username);
  Future<void> logout();
  Future<void> addXp(int amount); // <--- NUEVO
  Future<Map<String, dynamic>> getCurrentProfile();
}

// Implementación Real
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl({required this.supabaseClient});
  @override
  Future<Map<String, dynamic>> getCurrentProfile() async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) throw Exception("No hay sesión activa");

    try {
      // 1. Intentamos buscar el perfil normalmente
      final response = await supabaseClient
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single(); 
          
      return response;
    } catch (e) {
      // 2. Si falla (error porque no existe), LO CREAMOS EN ESE INSTANTE
      print("Perfil no encontrado, creando uno nuevo para el usuario...");
      
      final newProfile = await supabaseClient
          .from('profiles')
          .insert({
            'id': user.id,
            'total_xp': 0,
            'current_streak': 0,
          })
          .select()
          .single(); // Pedimos que nos devuelva el perfil recién creado
          
      return newProfile;
    }
  }
  
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