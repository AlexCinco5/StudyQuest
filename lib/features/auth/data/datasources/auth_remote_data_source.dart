import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/notification_service.dart'; // <--- IMPORTAMOS EL SERVICIO DE NOTIFICACIONES
import '../models/user_model.dart';

// Interfaz del DataSource
abstract class AuthRemoteDataSource {
  Future<UserModel> loginWithEmail(String email, String password);
  Future<UserModel> registerWithEmail(String email, String password, String username);
  Future<void> logout();
  Future<void> addXp(int amount); 
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
            'last_activity_date': null, // Inicializamos en null para que calcule bien la primera racha
          })
          .select()
          .single(); 
          
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
        data: {'username': username}, 
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
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) throw Exception("Usuario no logueado");

      // 1. LECTURA PRIMERO: Traemos el perfil actual ANTES de hacer cualquier cambio
      final profile = await supabaseClient
          .from('profiles')
          .select('current_streak, last_activity_date')
          .eq('id', user.id)
          .single();

      // 2. SUMAMOS XP en la base de datos
      await supabaseClient.rpc('add_xp', params: {'amount': amount});

      // 3. MATEMÁTICA PURA DE FECHAS (Usando UTC para evitar bugs de zona horaria)
      final now = DateTime.now();
      final todayUtc = DateTime.utc(now.year, now.month, now.day);
      
      DateTime? lastActivityUtc;
      if (profile['last_activity_date'] != null) {
        final parsed = DateTime.parse(profile['last_activity_date']);
        lastActivityUtc = DateTime.utc(parsed.year, parsed.month, parsed.day);
      }

      int currentStreak = (profile['current_streak'] as num?)?.toInt() ?? 0;
      bool needsUpdate = false;

      print("🕵️‍♂️ --- DIAGNÓSTICO DE RACHA ---");
      print("📅 Fecha en BD: $lastActivityUtc");
      print("📅 Fecha Hoy: $todayUtc");
      print("🔥 Racha actual antes de calcular: $currentStreak");

      // 4. LÓGICA DE RACHA
      if (lastActivityUtc == null) {
        currentStreak = 1;
        needsUpdate = true;
        print("➡️ Resultado: Primera vez estudiando. Racha = 1");
      } else {
        final difference = todayUtc.difference(lastActivityUtc).inDays;
        print("⏳ Diferencia de días: $difference");

        if (difference == 1) {
          currentStreak += 1;
          needsUpdate = true;
          print("➡️ Resultado: Estudió ayer. ¡Racha Sube a $currentStreak!");
        } else if (difference > 1) {
          currentStreak = 1;
          needsUpdate = true;
          print("➡️ Resultado: Pasaron más de 2 días. Racha rota, reinicia a 1");
        } else {
          print("➡️ Resultado: Ya había estudiado hoy. La racha se queda en $currentStreak");
        }
      }

      // 5. ACTUALIZAMOS SI HUBO CAMBIOS
      if (needsUpdate) {
        final dateString = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        
        await supabaseClient.from('profiles').update({
          'current_streak': currentStreak,
          'last_activity_date': dateString
        }).eq('id', user.id);
        
        print("✅ Base de datos actualizada con racha: $currentStreak y fecha: $dateString");
      }

      // 6. PROGRAMAR EL MEGÁFONO (NOTIFICACIÓN PARA EL DÍA SIGUIENTE)
      await NotificationService.scheduleStreakReminder();

    } catch (e) {
      print("❌ Error en addXp y racha: $e");
    }
  }
}