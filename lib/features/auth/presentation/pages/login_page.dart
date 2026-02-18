import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Importaciones de tu arquitectura
import '../bloc/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart'; // Para usar colores específicos si hace falta
import '../../../home/presentation/pages/home_page.dart'; // Importante para la navegación

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controladores para capturar el texto del usuario
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Clave para validar el formulario (que no esté vacío, etc.)
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // Siempre limpia los controladores para liberar memoria
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    // 1. Validar que los campos no estén vacíos
    if (_formKey.currentState!.validate()) {
      // 2. Disparar el evento al BLoC
      context.read<AuthBloc>().add(
            LoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // BlocConsumer: Escucha cambios (Listener) Y reconstruye la UI (Builder)
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            // Error: Mostrar Snackbar Roja
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is AuthSuccess) {
            // Éxito: Navegar al Home y borrar el historial de navegación
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        },
        builder: (context, state) {
          // Si está cargando, mostramos un indicador de progreso
          if (state is AuthLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.teal, // Usamos tu color turquesa
              ),
            );
          }

          // Si no está cargando, mostramos el formulario
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- LOGO Y TÍTULO ---
                    const Icon(
                      Icons.school_rounded, 
                      size: 100, 
                      color: AppTheme.darkBlue // Tu azul principal
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
                    const SizedBox(height: 48),

                    // --- INPUT EMAIL ---
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu correo';
                        }
                        if (!value.contains('@')) {
                          return 'Ingresa un correo válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- INPUT PASSWORD ---
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true, // Ocultar texto
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu contraseña';
                        }
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // --- BOTÓN LOGIN ---
                    FilledButton(
                      onPressed: _onLoginPressed,
                      child: const Text('INICIAR SESIÓN'),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // --- ENLACE A REGISTRO (Visual por ahora) ---
                    TextButton(
                      onPressed: () {
                        // Aquí conectaríamos la página de Registro más adelante
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