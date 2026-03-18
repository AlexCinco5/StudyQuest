// Importacion de los paquetes principales para la arquitectura BLoC.
// flutter_bloc proporciona las clases para crear el componente logico de presentacion.
import 'package:flutter_bloc/flutter_bloc.dart';
// equatable permite comparar eventos y estados por valor, optimizando los redibujados de pantalla.
import 'package:equatable/equatable.dart';

// Importaciones de las capas inferiores (Dominio).
// El BLoC solo conoce el contrato del repositorio y la entidad pura.
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

// Estas directivas enlazan este archivo principal con los archivos donde se definen
// los Eventos (entradas) y los Estados (salidas). Fisicamente son tres archivos separados,
// pero lógicamente para Dart, funcionan como uno solo.
part 'auth_event.dart';
part 'auth_state.dart';

// Definicion del Business Logic Component (BLoC) para la autenticacion.
// Toma 'AuthEvent' como entrada (lo que pide el usuario) 
// y emite 'AuthState' como salida (lo que debe pintar la pantalla).
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // Inyeccion de dependencias: El BLoC necesita una implementacion del contrato del repositorio
  // para poder ejecutar la logica de negocio real (hablar con Supabase).
  final AuthRepository authRepository;

  // Constructor del BLoC.
  // 'super(AuthInitial())' establece el estado inicial por defecto de la aplicacion
  // (es decir, antes de que el usuario haga cualquier cosa).
  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    
    // Registro del manejador para el evento 'LoginRequested'.
    // Cuando la interfaz de usuario dispare este evento, se ejecutara este bloque de codigo.
    on<LoginRequested>((event, emit) async {
      // 1. Inmediatamente despues de recibir el evento, emitimos el estado 'AuthLoading'.
      // Esto le dice a la pantalla que debe mostrar un circulo girando de "Cargando...".
      emit(AuthLoading());

      // 2. Ejecucion de la peticion asincrona al repositorio.
      // Se extraen las credenciales del evento que envio la interfaz.
      final result = await authRepository.loginWithEmail(
        email: event.email,
        password: event.password,
      );

      // 3. Resolucion del resultado devuelto por el repositorio (Tipo Either).
      // El metodo 'fold' obliga a manejar ambos casos posibles:
      result.fold(
        // Si el resultado cayo del lado Izquierdo (hubo un error o Failure),
        // emitimos el estado 'AuthFailure' extrayendo el mensaje de error para mostrar un popup.
        (failure) => emit(AuthFailure(failure.message)),
        
        // Si el resultado cayo del lado Derecho (exito total),
        // emitimos el estado 'AuthSuccess' adjuntando la informacion del usuario logueado
        // para que la interfaz sepa que debe navegar a la pantalla principal.
        (user) => emit(AuthSuccess(user)),
      );
    });

    // Registro del manejador para el evento 'RegisterRequested'.
    // Sigue exactamente el mismo flujo logico que el login.
    on<RegisterRequested>((event, emit) async {
      // 1. Se emite el estado de carga para bloquear la interfaz temporalmente.
      emit(AuthLoading());

      // 2. Se invoca el metodo de registro en el repositorio, pasando los tres parametros necesarios.
      final result = await authRepository.registerWithEmail(
        email: event.email,
        password: event.password,
        username: event.username,
      );

      // 3. Manejo funcional de la respuesta 'Either'.
      result.fold(
        // Fallo: Se avisa a la pantalla para mostrar el error.
        (failure) => emit(AuthFailure(failure.message)),
        // Exito: Se avisa a la pantalla que el registro concluyo satisfactoriamente.
        (user) => emit(AuthSuccess(user)),
      );
    });
  }
}