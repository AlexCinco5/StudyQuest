// Importamos las herramientas visuales basicas de Flutter. Esto incluye elementos 
// esenciales como colores, botones, textos y la forma general en que se dibuja la aplicacion.
import 'package:flutter/material.dart';

// Esta clase actua como nuestro manual de identidad visual o guia de estilos.
// Su proposito es concentrar todos los colores y diseños en un solo lugar.
// Si en el futuro necesitas cambiar un color, solo lo modificas aqui y toda la aplicacion
// cambiara automaticamente, ahorrando la necesidad de buscar pantalla por pantalla.
class AppTheme {
  // 1. Definimos los colores estáticos de tu paleta
  
  // Guardamos codigos de color exactos en variables fijas (static const).
  // El "0xFF" al principio es la forma tecnica de decirle al sistema 
  // que el color es 100% solido (sin transparencia), seguido de su codigo hexadecimal.
  static const Color darkBlue = Color(0xFF22577A);
  static const Color teal = Color(0xFF38A3A5);
  static const Color mint = Color(0xFF57CC99);
  static const Color lightGreen = Color(0xFF80ED99);
  static const Color paleGreen = Color(0xFFC7F9CC);

  // 2. Definimos el Tema Global (Material 3)
  
  // Esta funcion empaqueta todas nuestras reglas de diseño.
  // ThemeData funciona como un gran diccionario que le dice a toda la aplicacion
  // de que color deben ser los fondos, las letras, las barras y los botones por defecto.
  static ThemeData get lightTheme {
    return ThemeData(
      // Le instruimos a la app que utilice las reglas de diseño mas modernas de Google (Material 3).
      useMaterial3: true,
      
      // Esquema de colores generado a partir de tu paleta
      // ColorScheme organiza nuestros colores principales para combinarlos de manera armoniosa en diferentes elementos.
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkBlue, // Color principal que sirve de base para que el sistema calcule tonos extra.
        primary: darkBlue,   // Se usara para los componentes mas importantes y llamativos.
        secondary: teal,     // Se usara para componentes secundarios o de menor prioridad.
        tertiary: mint,      // Se usara para detalles menores o acentos de diseño.
        surface: Colors.white, // Fondo general blanco para limpieza visual
        background: Colors.white, // Fondo base tradicional de la aplicacion
      ),

      // Estilo global del Scaffold (Fondo de pantalla)
      // El "Scaffold" es el esqueleto o lienzo en blanco de cada pantalla. Aqui indicamos que siempre sea blanco.
      scaffoldBackgroundColor: Colors.white,

      // Estilo global de las AppBars (Barras superiores)
      // Configuramos el diseño por defecto de las barras de titulo que aparecen en la parte superior de la aplicacion.
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBlue, // Color del fondo de la barra superior.
        foregroundColor: Colors.white, // Color del texto/iconos que van dentro de esa barra superior.
        centerTitle: true, // Fuerza a que los titulos de todas las pantallas esten alineados al centro.
        elevation: 0, // Quita la sombra inferior para que la barra se vea plana, dando un aspecto mas limpio.
      ),

      // Estilo de los Inputs (Cajas de texto)
      // Aqui definimos como se veran los campos donde el usuario puede escribir (formularios, contraseñas, busquedas).
      inputDecorationTheme: InputDecorationTheme(
        filled: true, // Indica que la caja de texto estara rellena de un color (no sera solo un contorno).
        fillColor: paleGreen.withOpacity(0.3), // Usamos tu verde pálido suave con un poco de transparencia.
        
        // Define el contorno por defecto de la caja de texto. 
        // Aqui le indicamos que redondee las esquinas y que no dibuje una linea de contorno perimetral.
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        
        // Define el contorno que tomara la caja justo cuando el usuario la toque para empezar a escribir.
        // Le añadimos un borde del color teal para dar feedback visual de que la caja esta activa.
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: teal, width: 2),
        ),
        prefixIconColor: darkBlue, // Controla el color del icono pequeño que suele ir a la izquierda del texto.
        labelStyle: const TextStyle(color: darkBlue), // Controla el color de la palabra que indica que escribir.
      ),

      // Estilo de los Botones Principales
      // Configuramos la apariencia global de los botones solidos o rellenos de toda la app.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkBlue, // El boton tomara este color de relleno.
          foregroundColor: Colors.white, // Las letras del boton seran blancas para contrastar.
          padding: const EdgeInsets.symmetric(vertical: 16), // Da margen interno para que el boton no se vea muy delgado.
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Redondea las esquinas del boton para hacerlo mas amigable.
          ),
          textStyle: const TextStyle(
            fontSize: 16, // Tamaño de la letra dentro del boton.
            fontWeight: FontWeight.bold, // Hace la letra mas gruesa.
          ),
        ),
      ),
      
      // Estilo de botones flotantes (FAB)
      // Configuramos los botones redondos o alargados que suelen flotar en la esquina inferior derecha de la pantalla.
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: mint, // Color de relleno del boton flotante.
        foregroundColor: Colors.white, // Color del icono dentro del boton flotante.
      ),
    );
  }
}