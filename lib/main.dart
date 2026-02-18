import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/secrets.dart';
import 'injection_container.dart' as di; // Importamos con alias
import 'features/auth/presentation/bloc/auth_bloc.dart';
// Crearemos esta página pronto
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/welcome_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar Supabase
  await Supabase.initialize(
    url: Secrets.supabaseUrl,
    anonKey: Secrets.supabaseAnonKey,
  );

  // 2. Inicializar Inyección de Dependencias
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
      ],
      child: MaterialApp(
        title: 'StudyQuest',
        debugShowCheckedModeBanner: false, // Quitamos la etiqueta "Debug"
        
        // AQUÍ APLICAMOS TU PALETA:
        theme: AppTheme.lightTheme, 
        
        home: const WelcomePage(),
      ),
    );
  }
}

