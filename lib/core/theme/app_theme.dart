import 'package:flutter/material.dart';

class AppTheme {
  // 1. Definimos los colores estáticos de tu paleta
  static const Color darkBlue = Color(0xFF22577A);
  static const Color teal = Color(0xFF38A3A5);
  static const Color mint = Color(0xFF57CC99);
  static const Color lightGreen = Color(0xFF80ED99);
  static const Color paleGreen = Color(0xFFC7F9CC);

  // 2. Definimos el Tema Global (Material 3)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Esquema de colores generado a partir de tu paleta
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkBlue,
        primary: darkBlue,
        secondary: teal,
        tertiary: mint,
        surface: Colors.white, // Fondo general blanco para limpieza visual
        background: Colors.white,
      ),

      // Estilo global del Scaffold (Fondo de pantalla)
      scaffoldBackgroundColor: Colors.white,

      // Estilo global de las AppBars (Barras superiores)
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBlue,
        foregroundColor: Colors.white, // Color del texto/iconos
        centerTitle: true,
        elevation: 0,
      ),

      // Estilo de los Inputs (Cajas de texto)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: paleGreen.withOpacity(0.3), // Usamos tu verde pálido suave
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: teal, width: 2),
        ),
        prefixIconColor: darkBlue,
        labelStyle: const TextStyle(color: darkBlue),
      ),

      // Estilo de los Botones Principales
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      // Estilo de botones flotantes (FAB)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: mint,
        foregroundColor: Colors.white,
      ),
    );
  }
}