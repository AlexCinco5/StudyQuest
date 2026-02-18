import 'dart:io'; // <--- IMPORTANTE
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/home_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository homeRepository;

  HomeBloc({required this.homeRepository}) : super(HomeInitial()) {
    
    // 1. Cargar documentos (Al entrar a la pantalla)
    on<LoadDocuments>((event, emit) async {
      emit(HomeLoading());
      final result = await homeRepository.getMyDocuments();
      result.fold(
        (failure) => emit(HomeError(failure.message)),
        (documents) => emit(HomeLoaded(documents)),
      );
    });

    // 2. Subir documento
    on<UploadDocumentRequested>((event, emit) async {
      emit(HomeLoading()); // Mostramos spinner mientras sube
      
      final result = await homeRepository.uploadDocument(event.file, event.fileName);
      
      result.fold(
        (failure) => emit(HomeError(failure.message)),
        (newDoc) {
          // ¡Éxito! Ahora recargamos la lista completa para ver el nuevo archivo
          add(LoadDocuments()); 
        },
      );
    });
  }
}