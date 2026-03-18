import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/home_repository.dart';
// Importamos el inyector de dependencias para poder usar repositorios de otros modulos.
import '../../../../injection_container.dart' as di;
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/domain/entities/profile_entity.dart';

// Vinculamos fisicamente este archivo con sus eventos y estados.
part 'home_event.dart';
part 'home_state.dart';

// BLoC encargado de manejar toda la logica de la pantalla principal (Home).
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository homeRepository;

  HomeBloc({required this.homeRepository}) : super(HomeInitial()) {
    
    // 1. Logica de inicializacion: Cargar los documentos y el perfil del usuario.
    on<LoadDocuments>((event, emit) async {
      // Bloquea la UI mostrando un spinner.
      emit(HomeLoading());
      
      // Intentamos recuperar la lista de PDFs del usuario.
      final result = await homeRepository.getMyDocuments();
      
      // El Either nos obliga a manejar exito y fracaso:
      await result.fold(
        (failure) async {
          // Si fallo traer los PDFs, mostramos el error.
          emit(HomeError(failure.message));
        },
        (documents) async {
          // Si trajo los PDFs con exito, hacemos una SEGUNDA consulta, 
          // esta vez al modulo de autenticacion para traernos la racha y los puntos.
          final profileResult = await di.sl<AuthRepository>().getCurrentProfile();
          
          ProfileEntity? userProfile;
          
          profileResult.fold(
            (fail) => null, // Si falla el perfil, no crasheamos, solo se queda nulo.
            (profile) => userProfile = profile, 
          );
          
          // Emitimos el estado final enviando AMBAS cosas: lista de PDFs y perfil.
          emit(HomeLoaded(documents, profile: userProfile));
        }
      );
    });

    // 2. Logica para subir un nuevo archivo a la nube.
    on<UploadDocumentRequested>((event, emit) async {
      // Mostramos un spinner mientras el archivo sube.
      emit(HomeLoading()); 
      
      // Delegamos la operacion pesada al repositorio.
      final result = await homeRepository.uploadDocument(event.file, event.fileName);
      
      result.fold(
        (failure) => emit(HomeError(failure.message)),
        (newDoc) {
          // Si se subio correctamente, le decimos al BLoC que se dispare a si mismo
          // el evento de cargar todo de nuevo para que el archivo aparezca en la lista.
          add(LoadDocuments()); 
        },
      );
    });

    // 3. Logica para borrar un archivo que el usuario ya no quiere.
    on<DeleteDocumentRequested>((event, emit) async {
      emit(HomeLoading()); // Mostramos carga para bloquear interacciones mientras se borra.
      
      final result = await homeRepository.deleteDocument(event.documentId);
      
      result.fold(
        (failure) => emit(HomeError(failure.message)),
        (_) {
          // Si el borrado en Supabase fue exitoso, refrescamos la pantalla.
          add(LoadDocuments()); 
        },
      );
    });
  }
}