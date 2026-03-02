part of 'home_bloc.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<DocumentEntity> documents;
  final dynamic profile; // Usamos dynamic temporalmente para evitar dependencias cruzadas complejas, o importa ProfileEntity si lo prefieres

  const HomeLoaded(this.documents, {this.profile});

  @override
  List<Object?> get props => [documents, profile];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object> get props => [message];
}