import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../../../../injection_container.dart' as di;
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/domain/entities/profile_entity.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository homeRepository;

  HomeBloc({required this.homeRepository}) : super(HomeInitial()) {
    
    // 1. Cargar documentos Y perfil (Al entrar a la pantalla o recargar)
    on<LoadDocuments>((event, emit) async {
      emit(HomeLoading());
      
      // Pedimos los documentos
      final result = await homeRepository.getMyDocuments();
      
      await result.fold(
        (failure) async {
          emit(HomeError(failure.message));
        },
        (documents) async {
          // Si los documentos cargaron, pedimos el perfil
          final profileResult = await di.sl<AuthRepository>().getCurrentProfile();
          
          ProfileEntity? userProfile;
          
          profileResult.fold(
            (fail) => null, 
            (profile) => userProfile = profile, 
          );
          
          // Emitimos ambos datos
          emit(HomeLoaded(documents, profile: userProfile));
        }
      );
    });

    // 2. Subir documento
    on<UploadDocumentRequested>((event, emit) async {
      emit(HomeLoading()); 
      
      final result = await homeRepository.uploadDocument(event.file, event.fileName);
      
      result.fold(
        (failure) => emit(HomeError(failure.message)),
        (newDoc) {
          add(LoadDocuments()); 
        },
      );
    });
  }
}