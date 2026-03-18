// Importacion del paquete Equatable para facilitar la comparacion de objetos en memoria.
// Esto es crucial para la capa de presentacion (BLoC), ya que permite detectar si los datos del usuario
// realmente cambiaron y si es necesario redibujar la pantalla.
import 'package:equatable/equatable.dart';

// Definicion de la entidad principal de Usuario (UserEntity).
// En Clean Architecture, las entidades son los objetos centrales de la aplicacion.
// No dependen de nada mas, no saben de bases de datos ni de interfaces graficas; solo almacenan los datos clave.
class UserEntity extends Equatable {
  
  // Identificador unico global (UUID) asignado al usuario por el sistema de autenticacion.
  final String id;
  
  // Correo electronico verificado con el que el usuario inicio sesion o se registro.
  final String email;
  
  // Nombre publico de la cuenta (por ejemplo, "Alejandro"), usado para mostrarlo en la UI o en el Leaderboard.
  final String username;
  
  // URL absoluta que apunta al archivo de la imagen de perfil del usuario.
  // El operador de nulidad "?" se usa aqui porque el usuario puede no haber subido ninguna foto.
  final String? avatarUrl; 

  // Constructor constante de la entidad.
  // Los parametros "required" garantizan que jamas existira un usuario en el sistema 
  // que no tenga un ID, un email o un nombre de usuario definidos.
  const UserEntity({
    required this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
  });

  // Inyeccion de las propiedades al comparador interno de Equatable.
  // Le indica a Dart que dos instancias de UserEntity son matematicamente identicas 
  // unica y exclusivamente si su id, email, username y avatarUrl son iguales.
  @override
  List<Object?> get props => [id, email, username, avatarUrl];
}