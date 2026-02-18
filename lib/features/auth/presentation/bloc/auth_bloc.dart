import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

// Estas líneas conectan con los archivos de Eventos y Estados
part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    
    // --- MANEJO DE LOGIN ---
    on<LoginRequested>((event, emit) async {
      // 1. Emitimos estado de carga
      emit(AuthLoading());

      // 2. Llamamos al repositorio
      final result = await authRepository.loginWithEmail(
        email: event.email,
        password: event.password,
      );

      // 3. Manejamos la respuesta (Izquierda=Error, Derecha=Éxito)
      result.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (user) => emit(AuthSuccess(user)),
      );
    });

    // --- MANEJO DE REGISTRO (Nuevo) ---
    on<RegisterRequested>((event, emit) async {
      // 1. Emitimos estado de carga
      emit(AuthLoading());

      // 2. Llamamos al repositorio (nota que aquí enviamos también el username)
      final result = await authRepository.registerWithEmail(
        email: event.email,
        password: event.password,
        username: event.username,
      );

      // 3. Manejamos la respuesta
      result.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (user) => emit(AuthSuccess(user)),
      );
    });
  }
}