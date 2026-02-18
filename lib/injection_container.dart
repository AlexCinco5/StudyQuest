import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORTS DE AUTH ---
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// --- IMPORTS DE HOME (Documentos) ---
import 'features/home/data/datasources/home_remote_data_source.dart';
import 'features/home/data/repositories/home_repository_impl.dart';
import 'features/home/domain/repositories/home_repository.dart';
import 'features/home/presentation/bloc/home_bloc.dart';

// --- IMPORTS DE LEVELS (Nuevos) ---
// Asegúrate de haber creado estos archivos previamente
import 'features/home/domain/repositories/level_repository.dart'; 
import 'features/home/presentation/bloc/level_bloc.dart';

final sl = GetIt.instance; // Service Locator

Future<void> init() async {
  // ! --- Features - Auth ---
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(supabaseClient: sl()),
  );

  // ! --- Features - Home (Lista de Mundos/Documentos) ---
  sl.registerFactory(() => HomeBloc(homeRepository: sl()));
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(supabaseClient: sl()),
  );

  // ! --- Features - Levels (Mapa de Niveles) ---
  // Registramos el Bloc que controla el mapa
  sl.registerFactory(() => LevelBloc(sl()));
  
  // Registramos el Repositorio que busca Flashcards/Quizzes
  // Nota: LevelRepository depende directamente de SupabaseClient
  sl.registerLazySingleton(() => LevelRepository(sl()));

  // ! --- External (Cliente Supabase) ---
  sl.registerLazySingleton(() => Supabase.instance.client);
}