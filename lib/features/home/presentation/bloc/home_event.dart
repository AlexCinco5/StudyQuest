// Anotacion obligatoria cuando se usa la directiva "part" en home_bloc.dart.
part of 'home_bloc.dart';

// Clase base para las acciones que el usuario puede tomar en la pantalla Home.
abstract class HomeEvent extends Equatable {
  const HomeEvent();
  
  @override
  List<Object> get props => [];
}

// Evento que se dispara cada vez que entramos a la pantalla o hacemos "pull-to-refresh".
class LoadDocuments extends HomeEvent {}

// Evento disparado cuando el usuario selecciona un PDF de sus archivos locales y quiere subirlo.
class UploadDocumentRequested extends HomeEvent {
  // Necesitamos el archivo crudo y el nombre que le queremos poner en la BD.
  final File file;
  final String fileName;

  const UploadDocumentRequested(this.file, this.fileName);

  @override
  List<Object> get props => [file, fileName];
}

// Evento disparado cuando el usuario presiona el boton de borrar en un documento.
class DeleteDocumentRequested extends HomeEvent {
  // Solo requerimos el ID unico para saber a quien apuntar en Supabase.
  final String documentId;

  const DeleteDocumentRequested(this.documentId);

  @override
  List<Object> get props => [documentId];
}