import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.username,
    super.avatarUrl,
  });

  // Factory: Crea un UserModel a partir del objeto User de Supabase
  factory UserModel.fromSupabaseUser(User user) {
    // Supabase guarda datos extra (como username) en user_metadata
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      username: user.userMetadata?['username'] ?? 'Estudiante',
      avatarUrl: user.userMetadata?['avatar_url'],
    );
  }

  // Factory: Crea un UserModel a partir de un JSON (útil para pruebas o caché local)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
    );
  }
}