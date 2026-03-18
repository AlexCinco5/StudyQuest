// Esta instruccion indica que este archivo es un fragmento de 'auth_bloc.dart'.
// Permite que las clases definidas aqui sean vistas y utilizadas directamente por el BLoC
// como si formaran parte de un solo archivo continuo.
part of 'auth_bloc.dart'; // <--- Esta línea conecta con el archivo principal

// Definicion de la clase base abstracta para todos los estados de autenticacion.
// En el patron BLoC, los "Estados" representan como debe verse la pantalla en un momento dado.
// Al heredar de Equatable, evitamos reconstrucciones de pantalla innecesarias si el nuevo estado
// es identico al estado anterior.
abstract class AuthState extends Equatable {
  const AuthState();
  
  // Por defecto, los estados que no contengan informacion extra se consideraran iguales entre si.
  @override
  List<Object> get props => [];
}

// Estado inicial por defecto de la aplicacion.
// Se emite apenas arranca el BLoC, antes de que el usuario intente hacer login o registro.
// En este estado, la pantalla suele mostrar los campos de texto vacios listos para escribirse.
class AuthInitial extends AuthState {}

// Estado de procesamiento en curso.
// Se emite despues de que el usuario envia sus datos y el servidor los esta validando.
// Cuando la interfaz recibe este estado, generalmente deshabilita los botones y muestra un spinner circular.
class AuthLoading extends AuthState {}

// Estado de autenticacion exitosa.
// Se emite cuando las credenciales son correctas o el registro termino sin errores.
class AuthSuccess extends AuthState {
  // Contiene la entidad del usuario recien logueado, lo que permite a la interfaz
  // mostrar su nombre o redirigirlo a la pantalla principal pasandole sus datos.
  final UserEntity user;
  
  const AuthSuccess(this.user);
  
  // Le dice a Equatable que dos estados de exito son iguales unicamente
  // si pertenecen al mismo usuario.
  @override
  List<Object> get props => [user];
}

// Estado de error en la autenticacion.
// Se emite cuando el correo es invalido, la contraseña es erronea, o se cae el internet.
class AuthFailure extends AuthState {
  // Contiene el mensaje de texto explicativo del error proveniente de Supabase.
  final String message;
  
  const AuthFailure(this.message);

  // Le dice a Equatable que dos errores son identicos solo si tienen el mismo mensaje exacto,
  // permitiendo que la interfaz muestre el texto de error en un SnackBar o Dialogo.
  @override
  List<Object> get props => [message];
}