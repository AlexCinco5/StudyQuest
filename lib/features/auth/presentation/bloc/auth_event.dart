// Esta instruccion enlaza este archivo como parte integral de 'auth_bloc.dart'.
// Permite que el BLoC reconozca estas clases como si estuvieran escritas en el mismo archivo.
part of 'auth_bloc.dart';

// Definicion de la clase base abstracta para todos los eventos de autenticacion.
// En el patron BLoC, los "Eventos" son las acciones que ocurren en la interfaz de usuario 
// (ej. el usuario toca un boton) y que el BLoC debe procesar.
// Hereda de Equatable para permitir una comparacion eficiente de eventos.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  // Configura Equatable para que, por defecto, los eventos sin parametros se consideren iguales.
  @override
  List<Object> get props => [];
}

// Evento especifico que representa un intento de inicio de sesion.
// Se dispara cuando el usuario ingresa sus credenciales y presiona "Ingresar".
class LoginRequested extends AuthEvent {
  // Credenciales capturadas desde los campos de texto de la interfaz.
  final String email;
  final String password;

  // Constructor que requiere que la interfaz proporcione tanto el email como el password
  // al momento de crear y disparar este evento.
  const LoginRequested({
    required this.email,
    required this.password,
  });

  // Sobrescribe el metodo de Equatable para indicar que dos eventos LoginRequested 
  // son iguales solo si su email y password son exactamente los mismos.
  @override
  List<Object> get props => [email, password];
}

// Evento especifico que representa un intento de creacion de una nueva cuenta.
// Se dispara cuando el usuario completa el formulario de registro y lo envia.
class RegisterRequested extends AuthEvent {
  // Datos requeridos para registrar a un nuevo usuario en Supabase.
  final String email;
  final String password;
  final String username; // Dato adicional (metadata) que solicitamos en el registro.

  // Constructor que obliga a enviar los tres parametros.
  const RegisterRequested({
    required this.email,
    required this.password,
    required this.username,
  });

  // Instruye a Equatable a comparar los eventos de registro evaluando sus tres parametros.
  @override
  List<Object> get props => [email, password, username];
}