part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object> get props => [];
}

class LoadDocuments extends HomeEvent {}

class UploadDocumentRequested extends HomeEvent {
  final File file;
  final String fileName;

  const UploadDocumentRequested(this.file, this.fileName);

  @override
  List<Object> get props => [file, fileName];
}

class DeleteDocumentRequested extends HomeEvent {
  final String documentId;

  const DeleteDocumentRequested(this.documentId);

  @override
  List<Object> get props => [documentId];
}