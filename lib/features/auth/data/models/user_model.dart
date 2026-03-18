import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';

// Definicion del modelo de datos para el Usuario.
// Extiende de UserEntity, que es la representacion pura del negocio (Clean Architecture).
class UserModel extends UserEntity {
  // Constructor del modelo. 
  // Usa 'super' para pasar directamente los parametros a la clase padre (UserEntity).
  const UserModel({
    required super.id,
    required super.email,
    required super.username,
    super.avatarUrl,
  });

  // Factory constructor para parsear el objeto 'User' nativo que devuelve Supabase
  // y convertirlo en nuestro propio 'UserModel'.
  // Las 'factories' son patrones de diseño utiles para crear instancias desde fuentes externas.
  factory UserModel.fromSupabaseUser(User user) {
    // Supabase almacena campos personalizados (como username o avatar) dentro del diccionario 'userMetadata'.
    // Usamos el operador '??' como fallback para proveer valores por defecto ("Estudiante" o string vacio)
    // en caso de que Supabase retorne nulos en esos campos.
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      username: user.userMetadata?['username'] ?? 'Estudiante',
      avatarUrl: user.userMetadata?['avatar_url'],
    );
  }

  // Factory constructor secundario.
  // Utilizado para inflar un UserModel a partir de un diccionario de Dart (JSON).
  // Es practico para serializacion/deserializacion si se necesita guardar la sesion
  // en almacenamiento local (shared_preferences, hive) o para inyectar mocks en pruebas unitarias.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
    );
  }
}