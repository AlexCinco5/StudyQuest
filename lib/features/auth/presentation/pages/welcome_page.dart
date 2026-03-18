// Importacion base del framework de Flutter para construir la interfaz de usuario.
import 'package:flutter/material.dart';

// Importaciones de recursos internos del proyecto.
import '../../../../core/theme/app_theme.dart'; // Contiene la paleta de colores (darkBlue, teal, etc).
import 'login_page.dart'; // Pantalla destino para usuarios existentes.
import 'register_page.dart'; // Pantalla destino para usuarios nuevos.

// Definicion de la pantalla de bienvenida.
// Es un StatelessWidget porque esta pantalla es puramente visual y estatica; 
// no necesita recordar ni cambiar ningun dato interno mientras se muestra.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold provee la estructura base (el lienzo blanco) para la pantalla.
    return Scaffold(
      backgroundColor: Colors.white,
      
      // SafeArea garantiza que el contenido no quede oculto bajo el "notch" (muesca de la camara)
      // o la barra de navegacion gestual del sistema operativo del telefono.
      body: SafeArea(
        // Padding añade un margen interno global para que los elementos no toquen los bordes de la pantalla.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          
          // La columna principal organiza el contenido verticalmente.
          child: Column(
            // Empuja el primer bloque de contenido (Logo/Textos) hacia arriba 
            // y el segundo bloque (Botones) hacia abajo, creando un espacio vacio en el medio.
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              
              // --- SECCION SUPERIOR: LOGO Y TEXTOS INFORMATIVOS ---
              Column(
                children: [
                  const SizedBox(height: 40), // Margen superior para despegar el logo del techo.
                  
                  // Representacion visual de la marca de la app.
                  const Icon(
                    Icons.school_rounded,
                    size: 120,
                    color: AppTheme.darkBlue, // Utiliza el color principal corporativo.
                  ),
                  const SizedBox(height: 24),
                  
                  // Titulo de bienvenida.
                  const Text(
                    'Bienvenido a StudyQuest',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBlue,
                      letterSpacing: 1.2, // Separa ligeramente las letras para mayor elegancia.
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Subtitulo descriptivo de la propuesta de valor de la aplicacion.
                  Text(
                    'Estudia de manera inteligente. Convierte tus PDFs en flashcards y quizzes con IA.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600], // Gris suave para no competir visualmente con el titulo.
                      height: 1.5, // Aumenta el interlineado para facilitar la lectura.
                    ),
                  ),
                ],
              ),

              // --- SECCION INFERIOR: BOTONES DE NAVEGACION ---
              Column(
                // Fuerza a que los botones hijos se estiren horizontalmente para ocupar todo el ancho permitido.
                crossAxisAlignment: CrossAxisAlignment.stretch, 
                children: [
                  
                  // Boton principal de alto contraste para usuarios recurrentes.
                  FilledButton(
                    onPressed: () {
                      // Inserta la pantalla de Login en el stack de navegacion.
                      // Al usar push() en lugar de pushReplacement(), se permite al usuario
                      // usar el boton nativo de "Atras" para regresar a esta pantalla de bienvenida.
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    // El diseño visual (color de fondo, bordes, fuente) se hereda automaticamente 
                    // de la configuracion global en app_theme.dart.
                    child: const Text('YA TENGO UNA CUENTA'),
                  ),
                  
                  const SizedBox(height: 16), // Separacion entre botones.

                  // Boton secundario (transparente con contorno) para la creacion de cuentas nuevas.
                  // Visualmente es menos pesado que el boton principal para establecer una jerarquia.
                  OutlinedButton(
                    onPressed: () {
                      // Inserta la pantalla de Registro en el stack de navegacion.
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const RegisterPage()),
                      );
                    },
                    // Se define un estilo personalizado en linea (inline) especifico para este boton.
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.darkBlue, // Color del texto al no estar presionado.
                      side: const BorderSide(color: AppTheme.darkBlue, width: 2), // Grosor y color del contorno.
                      padding: const EdgeInsets.symmetric(vertical: 16), // Altura interna del boton.
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Redondeo de esquinas congruente con el tema.
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('QUIERO REGISTRARME'),
                  ),
                  
                  const SizedBox(height: 20), // Margen inferior de seguridad respecto al borde del SafeArea.
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}