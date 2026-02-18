import 'package:flutter/material.dart';

// Importaciones de tu proyecto
import '../../../../core/theme/app_theme.dart';
import 'login_page.dart';
import 'register_page.dart'; // Asegúrate de tener este archivo creado

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos Scaffold para la estructura básica de la pantalla
    return Scaffold(
      // Fondo blanco limpio (definido en el tema)
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Espacia los elementos verticalmente (Arriba y Abajo)
            children: [
              // --- SECCIÓN SUPERIOR: LOGO Y TEXTO ---
              Column(
                children: [
                  const SizedBox(height: 40),
                  // Icono o Logo de la App
                  Icon(
                    Icons.school_rounded,
                    size: 120,
                    color: AppTheme.darkBlue, // Usamos el azul principal de tu paleta
                  ),
                  const SizedBox(height: 24),
                  
                  // Título Principal
                  Text(
                    'Bienvenido a StudyQuest',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBlue,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Subtítulo o Lema
                  Text(
                    'Estudia de manera inteligente. Convierte tus PDFs en flashcards y quizzes con IA.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5, // Altura de línea para mejor lectura
                    ),
                  ),
                ],
              ),

              // --- SECCIÓN INFERIOR: BOTONES DE ACCIÓN ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, // Estira los botones a lo ancho
                children: [
                  // Botón Principal (Relleno): INICIAR SESIÓN
                  FilledButton(
                    onPressed: () {
                      // Navegar a la pantalla de Login
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    // El estilo ya está definido en app_theme.dart, pero podemos personalizar si queremos
                    child: const Text('YA TENGO UNA CUENTA'),
                  ),
                  
                  const SizedBox(height: 16),

                  // Botón Secundario (Borde): REGISTRARSE
                  OutlinedButton(
                    onPressed: () {
                      // Navegar a la pantalla de Registro
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const RegisterPage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.darkBlue, // Color del texto
                      side: const BorderSide(color: AppTheme.darkBlue, width: 2), // Borde azul
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('QUIERO REGISTRARME'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}