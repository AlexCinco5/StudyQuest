import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/notification_service.dart'; // <--- IMPORTAMOS EL SERVICIO DE NOTIFICACIONES
import '../models/user_model.dart';

// Interfaz que define los metodos obligatorios para el manejo de autenticacion y datos de usuario.
// Sirve como contrato estricto para la implementacion concreta.
abstract class AuthRemoteDataSource {
  Future<UserModel> loginWithEmail(String email, String password);
  Future<UserModel> registerWithEmail(String email, String password, String username);
  Future<void> logout();
  Future<void> addXp(int amount); 
  Future<Map<String, dynamic>> getCurrentProfile();
}

// Implementacion de la interfaz AuthRemoteDataSource utilizando el cliente oficial de Supabase.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  // Instancia del cliente de Supabase inyectada a traves del constructor.
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<Map<String, dynamic>> getCurrentProfile() async {
    // Verifica si existe una sesion activa en el cliente local antes de realizar la consulta.
    final user = supabaseClient.auth.currentUser;
    if (user == null) throw Exception("No hay sesión activa");

    try {
      // Intenta recuperar los datos del perfil del usuario activo desde la tabla 'profiles'.
      final response = await supabaseClient
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single(); 
          
      return response;
    } catch (e) {
      // En caso de que el perfil no exista (error de consulta vacia), se fuerza la creacion de un registro por defecto.
      // Esto actua como fallback de seguridad si el trigger de registro en Supabase falla o tiene retraso.
      print("Perfil no encontrado, creando uno nuevo para el usuario...");
      
      final newProfile = await supabaseClient
          .from('profiles')
          .insert({
            'id': user.id,
            'total_xp': 0,
            'current_streak': 0,
            'last_activity_date': null, // Inicializado en null para manejar correctamente el primer calculo de racha.
          })
          .select()
          .single(); 
          
      return newProfile;
    }
  }
  
  @override
  Future<UserModel> loginWithEmail(String email, String password) async {
    try {
      // Ejecuta la peticion de autenticacion contra la API de Supabase.
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Validacion de seguridad para evitar null exceptions si la API responde con exito pero sin payload de usuario.
      if (response.user == null) {
        throw const ServerFailure('El usuario es nulo después del login');
      }

      // Mapea la respuesta JSON al modelo de dominio interno.
      return UserModel.fromSupabaseUser(response.user!);
    } on AuthException catch (e) {
      // Captura y propaga errores especificos arrojados por el modulo de Auth.
      throw ServerFailure(e.message);
    } catch (e) {
      // Fallback para capturar excepciones de red o errores de formato.
      throw const ServerFailure('Error desconocido al iniciar sesión');
    }
  }

  @override
  Future<UserModel> registerWithEmail(String email, String password, String username) async {
    try {
      // Peticion de registro. Pasa el username dentro del bloque 'data' como metadata del usuario.
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
    // Purga la sesion local y revoca el token activo en el servidor.
    await supabaseClient.auth.signOut();
  }
  
  @override
  Future<void> addXp(int amount) async {
    try {
      // Validacion de sesion.
      final user = supabaseClient.auth.currentUser;
      if (user == null) throw Exception("Usuario no logueado");

      // Lectura inicial del perfil para obtener el estado actual de la racha y ultima fecha de actividad.
      final profile = await supabaseClient
          .from('profiles')
          .select('current_streak, last_activity_date')
          .eq('id', user.id)
          .single();

      // Ejecucion de un Remote Procedure Call (RPC) para incrementar la experiencia en base de datos.
      await supabaseClient.rpc('add_xp', params: {'amount': amount});

      // Estandarizacion temporal utilizando formato UTC estricto para aislar la logica de las zonas horarias del cliente.
      final now = DateTime.now();
      final todayUtc = DateTime.utc(now.year, now.month, now.day);
      
      DateTime? lastActivityUtc;
      if (profile['last_activity_date'] != null) {
        final parsed = DateTime.parse(profile['last_activity_date']);
        lastActivityUtc = DateTime.utc(parsed.year, parsed.month, parsed.day);
      }

      // Parsing seguro del valor actual de la racha con fallback a 0.
      int currentStreak = (profile['current_streak'] as num?)?.toInt() ?? 0;
      bool needsUpdate = false;

      print("--- DIAGNOSTICO DE RACHA ---");
      print("Fecha en BD: $lastActivityUtc");
      print("Fecha Hoy: $todayUtc");
      print("Racha actual antes de calcular: $currentStreak");

      // Logica transaccional de evaluacion de rachas.
      if (lastActivityUtc == null) {
        // Asignacion para el primer registro de actividad en la vida util de la cuenta.
        currentStreak = 1;
        needsUpdate = true;
        print("Resultado: Primera vez estudiando. Racha = 1");
      } else {
        // Calculo del delta en dias absolutos entre transacciones.
        final difference = todayUtc.difference(lastActivityUtc).inDays;
        print("Diferencia de dias: $difference");

        if (difference == 1) {
          // Actividad consecutiva confirmada. Incremento del contador de racha.
          currentStreak += 1;
          needsUpdate = true;
          print("Resultado: Estudio ayer. Racha Sube a $currentStreak");
        } else if (difference > 1) {
          // Ruptura de racha detectada por exceder el limite de inactividad permitido.
          currentStreak = 1;
          needsUpdate = true;
          print("Resultado: Pasaron mas de 2 dias. Racha rota, reinicia a 1");
        } else {
          // Actividad duplicada en el mismo ciclo (dia). Se omite el incremento pero no se penaliza.
          print("Resultado: Ya habia estudiado hoy. La racha se queda en $currentStreak");
        }
      }

      // Bloque de escritura condicional para evitar requests redundantes a Supabase si el estado no muto.
      if (needsUpdate) {
        // Formateo del string de fecha respetando la estructura ISO 8601 acotada.
        final dateString = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        
        // Modificacion de los registros del perfil con el nuevo delta consolidado.
        await supabaseClient.from('profiles').update({
          'current_streak': currentStreak,
          'last_activity_date': dateString
        }).eq('id', user.id);
        
        print("Base de datos actualizada con racha: $currentStreak y fecha: $dateString");
      }

      // Invocacion asincrona del servicio local para programar la interrupcion del recordatorio futuro.
      await NotificationService.scheduleStreakReminder();

    } catch (e) {
      // Captura de excepcion generica sin interrupcion de flujo para prevenir bloqueos en la interfaz de usuario.
      print("Error en addXp y racha: $e");
    }
  }
}