// Esta directiva conecta estrechamente este archivo con 'auth_bloc.dart'.
// Permite que ambos archivos compartan clases y variables privadas como si fueran uno solo.
part of 'auth_bloc.dart';

// Clase base abstracta para todos los eventos del modulo de autenticacion.
// Al heredar de Equatable, facilitamos la comparacion de eventos por valor y no por referencia,
// lo que previene que el BLoC reaccione a eventos duplicados innecesarios.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

// Evento disparado desde la UI cuando el usuario pulsa el boton de "Iniciar Sesion".
class LoginRequested extends AuthEvent {
  // Credenciales necesarias para ejecutar el intento de login.
  final String email;
  final String password;

  // Constructor que asegura la recepcion obligatoria de las credenciales.
  const LoginRequested({required this.email, required this.password});

  // Sobrescritura de props para incluir las credenciales en la comparacion de igualdad del evento.
  @override
  List<Object> get props => [email, password];
}

// Más adelante agregaremos RegisterRequested, LogoutRequested, etc.