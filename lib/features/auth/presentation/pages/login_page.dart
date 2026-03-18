// Importaciones base de Flutter para interfaces de usuario y el gestor de estado BLoC.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Importaciones internas de la arquitectura limpia de la aplicacion.
import '../bloc/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart'; // Define la paleta de colores y estilos globales.
import '../../../home/presentation/pages/home_page.dart'; // Pantalla destino tras un login exitoso.

// Definicion de la pantalla de Login como un StatefulWidget.
// Se requiere manejar estado local (Stateful) porque los campos de texto mutan 
// constantemente conforme el usuario teclea sus credenciales.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Inicializacion de controladores para extraer el texto de los inputs.
  // Actuan como puentes entre la UI y la logica para leer lo que el usuario escribio.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Clave global para identificar y manipular el formulario completo.
  // Permite ejecutar validaciones conjuntas en todos los inputs antes de enviar la peticion.
  final _formKey = GlobalKey<FormState>();

  // Metodo del ciclo de vida que se ejecuta al destruir la pantalla.
  @override
  void dispose() {
    // Es imperativo liberar los controladores de texto para prevenir fugas de memoria (memory leaks).
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Funcion disparada al presionar el boton principal de inicio de sesion.
  void _onLoginPressed() {
    // 1. Ejecuta los validadores individuales definidos en los TextFormFields.
    // Solo si todos retornan 'null' (es decir, sin errores), se procede.
    if (_formKey.currentState!.validate()) {
      // 2. Extrae el texto, limpia espacios accidentales al inicio/final con trim(),
      // y despacha el evento 'LoginRequested' hacia el BLoC para iniciar el proceso de autenticacion.
      context.read<AuthBloc>().add(
            LoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            ),
          );
    }
  }

  // Construccion del arbol de widgets de la pantalla.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // BlocConsumer es un widget hibrido especializado.
      // Ejecuta logica secundaria sin redibujar (listener) Y redibuja la UI segun el estado (builder).
      body: BlocConsumer<AuthBloc, AuthState>(
        
        // Bloque listener: Reacciona a cambios de estado ejecutando acciones "one-off" 
        // como navegacion, dialogos o notificaciones tipo toast/snackbar.
        listener: (context, state) {
          if (state is AuthFailure) {
            // Manejo del estado de error: Muestra un banner rojo en la parte inferior.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating, // Hace que el banner flote sobre la UI.
              ),
            );
          } else if (state is AuthSuccess) {
            // Manejo del estado de exito: Navega hacia la pantalla Home.
            // Se utiliza pushReplacement para destruir la pantalla de Login del stack de navegacion,
            // evitando que el usuario regrese accidentalmente al login presionando el boton "Atras".
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        },
        
        // Bloque builder: Reconstruye puramente la interfaz visual basandose en el estado actual.
        builder: (context, state) {
          // Intercepta el estado de carga para mostrar retroalimentacion visual (spinner).
          if (state is AuthLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.teal, // Utiliza el color de acento definido en el tema global.
              ),
            );
          }

          // Construccion de la vista por defecto (AuthInitial o tras un fallo recuperable).
          return Center(
            // SingleChildScrollView previene errores de "RenderFlex overflow" si se despliega
            // el teclado virtual en pantallas pequeñas, permitiendo hacer scroll vertical.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0), // Margen interno para dar respiro visual.
              
              // Envoltorio Form necesario para que la _formKey funcione y agrupe los inputs.
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Centra los elementos verticalmente.
                  crossAxisAlignment: CrossAxisAlignment.stretch, // Estira los botones para ocupar el ancho disponible.
                  children: [
                    
                    // --- SECCION CABECERA (LOGO Y TITULOS) ---
                    const Icon(
                      Icons.school_rounded, 
                      size: 100, 
                      color: AppTheme.darkBlue 
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'StudyQuest',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkBlue,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tu compañero de estudio inteligente',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 48), // Espaciador grande antes del formulario.

                    // --- INPUT EMAIL ---
                    TextFormField(
                      controller: _emailController,
                      // Optimiza el teclado virtual para mostrar la '@' mas accesible.
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      // Funcion validadora. Retorna un string de error o null si es valido.
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu correo';
                        }
                        if (!value.contains('@')) {
                          return 'Ingresa un correo válido';
                        }
                        return null; // Validacion exitosa.
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- INPUT PASSWORD ---
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true, // Oculta el texto tecleado reemplazandolo por puntos (***).
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu contraseña';
                        }
                        // Validacion basica de seguridad (minimo 6 caracteres suele ser requerido por Supabase).
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // --- BOTON DE ACCION PRINCIPAL ---
                    // Usa el FilledButtonTheme definido globalmente en app_theme.dart.
                    FilledButton(
                      onPressed: _onLoginPressed, // Invoca la funcion local definida arriba.
                      child: const Text('INICIAR SESIÓN'),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // --- ENLACE SECUNDARIO (NAVEGACION A REGISTRO) ---
                    TextButton(
                      onPressed: () {
                        // Implementacion temporal interactiva mediante un SnackBar.
                        ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text("Función de Registro próximamente...")),
                        );
                      },
                      child: const Text(
                        '¿No tienes cuenta? Regístrate aquí',
                        style: TextStyle(color: AppTheme.teal),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}