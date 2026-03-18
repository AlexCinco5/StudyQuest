// Conexion con el cerebro central.
part of 'home_bloc.dart';

// Clase base que define las posibles fachadas de la pantalla Home.
abstract class HomeState extends Equatable {
  const HomeState();
  
  @override
  List<Object?> get props => [];
}

// Estado neutro, util apenas se enciende la app.
class HomeInitial extends HomeState {}

// Estado activo cuando el BLoC esta ocupado hablando con Supabase (subiendo o descargando).
class HomeLoading extends HomeState {}

// Estado dorado: Todo cargo correctamente.
class HomeLoaded extends HomeState {
  // La lista de PDFs que vamos a pintar en modo de cuadricula (grid).
  final List<DocumentEntity> documents;
  
  // Objeto comodin para almacenar la racha y los XP del jugador.
  // Es "dynamic" por ahora para evitar importar modelos complejos que puedan generar errores circulares.
  final dynamic profile; 

  // El perfil es opcional porque al subir un archivo tal vez solo queramos recargar los docs.
  const HomeLoaded(this.documents, {this.profile});

  // Le decimos a Equatable que redibuje si cambia la lista de docs o si el jugador gano puntos.
  @override
  List<Object?> get props => [documents, profile];
}

// Estado de alerta si algo se rompe.
class HomeError extends HomeState {
  // El texto del error para mostrar en un banner flotante.
  final String message;

  const HomeError(this.message);

  @override
  List<Object> get props => [message];
}