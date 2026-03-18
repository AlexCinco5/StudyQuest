// Importaciones requeridas para construir la interfaz y manejar el estado.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Importaciones relativas de la arquitectura BLoC y configuraciones de diseño.
import '../bloc/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/pages/home_page.dart';
import 'login_page.dart'; // Importado para permitir la navegacion cruzada entre login y registro.

// Pantalla de registro implementada como StatefulWidget.
// Se requiere manejar el estado interno para rastrear el texto ingresado en multiples campos.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controladores dedicados para cada campo del formulario.
  // Permiten extraer el texto escrito por el usuario en tiempo real.
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Controlador adicional exclusivo para la pantalla de registro,
  // util para validar que el usuario no cometio un error tipografico al crear su contraseña.
  final _confirmPasswordController = TextEditingController(); 
  
  // Clave global para gestionar y validar el bloque completo del formulario.
  final _formKey = GlobalKey<FormState>();

  // Metodo de limpieza que se llama cuando el widget es destruido.
  @override
  void dispose() {
    // Es imperativo liberar los recursos de todos los controladores para evitar memory leaks.
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Funcion manejadora del evento onTap del boton de registro.
  void _onRegisterPressed() {
    // Se invoca el validador global del formulario.
    if (_formKey.currentState!.validate()) {
      // Si la validacion es exitosa, se despacha el evento RegisterRequested al BLoC.
      // Se utiliza trim() para limpiar posibles espacios en blanco introducidos por el teclado.
      context.read<AuthBloc>().add(
            RegisterRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
              username: _usernameController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Se implementa una AppBar minimalista principalmente para proveer el boton de retroceso nativo.
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Hace que la barra se fusione con el fondo.
        elevation: 0, // Elimina la sombra para un diseño plano.
        iconTheme: const IconThemeData(color: AppTheme.darkBlue), // Colorea la flecha de retroceso.
      ),
      // Permite que el cuerpo (body) de la pantalla ocupe el espacio detras de la AppBar transparente.
      extendBodyBehindAppBar: true, 
      
      // BlocConsumer integra un Listener (para side-effects) y un Builder (para renderizado).
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          // Manejo de errores: despliega un SnackBar rojo indicando el motivo de la falla.
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
            );
          } else if (state is AuthSuccess) {
            // Manejo de exito: Redirige al usuario al panel principal (Home)
            // destruyendo el stack de navegacion previo para prevenir flujos invalidos con el boton 'Atras'.
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        },
        builder: (context, state) {
          // Representacion del estado de procesamiento mediante un indicador visual.
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.teal));
          }

          // Representacion del estado por defecto: el formulario de registro interactivo.
          return Center(
            // Permite hacer scroll si el teclado virtual oculta parte del formulario.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              
              // El widget Form agrupa los inputs para realizar la validacion colectiva.
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- TITULO Y SUBTITULO ---
                    const Text(
                      'Crear Cuenta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Únete y empieza tu racha de estudio',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),

                    // --- CAMPO: NOMBRE DE USUARIO ---
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de Usuario',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      // Validador en linea usando operador ternario.
                      // Retorna null si es valido, o un mensaje de error si esta vacio.
                      validator: (value) =>
                          value != null && value.isNotEmpty ? null : 'Elige un nombre de usuario',
                    ),
                    const SizedBox(height: 16),

                    // --- CAMPO: EMAIL ---
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress, // Muestra el teclado con '@'.
                      decoration: const InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      // Validador basico comprobando la existencia del arroba.
                      validator: (value) =>
                          value != null && value.contains('@') ? null : 'Ingresa un correo válido',
                    ),
                    const SizedBox(height: 16),

                    // --- CAMPO: CONTRASEÑA ---
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true, // Enmascara los caracteres tecleados.
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      // Validador de longitud minima requerida (generalmente 6 caracteres por defecto en Supabase).
                      validator: (value) =>
                          value != null && value.length >= 6 ? null : 'Mínimo 6 caracteres',
                    ),
                    const SizedBox(height: 16),

                    // --- CAMPO: CONFIRMAR CONTRASEÑA ---
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar Contraseña',
                        prefixIcon: Icon(Icons.lock_reset),
                      ),
                      // Validador cruzado: verifica que el valor ingresado sea identico al del primer input de contraseña.
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null; // Validacion exitosa.
                      },
                    ),
                    const SizedBox(height: 32),

                    // --- BOTON DE REGISTRO ---
                    // Usa el estilo de boton relleno (FilledButton) definido en app_theme.dart.
                    FilledButton(
                      onPressed: _onRegisterPressed,
                      child: const Text('REGISTRARME'),
                    ),

                    const SizedBox(height: 16),

                    // --- SECCION INFERIOR: ENLACE A LOGIN ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('¿Ya tienes cuenta?'),
                        TextButton(
                          onPressed: () {
                            // Se utiliza pushReplacement para evitar crear una cadena infinita
                            // de pantallas Login -> Registro -> Login -> Registro en el stack de navegacion.
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                            );
                          },
                          child: const Text('Inicia Sesión', style: TextStyle(color: AppTheme.teal)),
                        ),
                      ],
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