import 'package:flutter/material.dart';
// Herramienta principal para hablar con nuestra base de datos en la nube
import 'package:supabase_flutter/supabase_flutter.dart';
// Importamos la pantalla de inicio para poder mandar al usuario allá cuando cierre sesión
import '../../../../features/auth/presentation/pages/welcome_page.dart';

// Pantalla donde el usuario puede ver su racha, sus puntos y cerrar sesión.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Guardamos una conexión directa a Supabase para pedir los datos rápidos
  final _supabase = Supabase.instance.client;
  
  // Aquí guardaremos la información del usuario cuando la descarguemos
  // Es Map porque Supabase nos regresa los datos como un diccionario JSON
  Map<String, dynamic>? _profileData;
  
  // Bolita de carga activada por defecto al entrar
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Apenas carga la pantalla, mandamos a pedir los datos a internet
    _loadUserProfile();
  }

  // Función asíncrona que va a Supabase a buscar el perfil del usuario
  Future<void> _loadUserProfile() async {
    try {
      // 1. Primero checamos quién está usando la app ahorita
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("Usuario no logueado");

      // 2. Buscamos en la tabla 'profiles' el renglón que coincida con nuestro ID
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single(); // Le decimos que solo nos traiga UNO, no una lista

      // 3. Guardamos los datos y quitamos la bolita de carga
      setState(() {
        _profileData = data;
        _isLoading = false;
      });
    } catch (e) {
      // Si falla (ej. sin internet), quitamos la carga para no dejar la pantalla trabada
      print("❌ Error cargando perfil: $e");
      setState(() => _isLoading = false);
    }
  }

  // Función para cerrar la sesión del usuario
  Future<void> _signOut() async {
    // 1. Mostrar un cuadrito de confirmación para que no cierre sesión por accidente
    // Retorna un true (si confirma) o false (si cancela)
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('Cerrar sesión'),
            ],
          ),
          content: const Text('¿Estás seguro de que deseas salir de tu cuenta?'),
          actions: [
            // Botón de arrepentimiento
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false), // Devuelve false
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            // Botón rojo definitivo
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(dialogContext, true), // Devuelve true
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );

    // 2. Si el usuario presionó "Cancelar" o picó afuera del cuadro, detenemos la función aquí mismo
    if (confirmar != true) return;

    // 3. Si sí confirmó, le decimos a Supabase que borre la sesión activa del celular
    await _supabase.auth.signOut();

    // 4. Redirigimos a la pantalla principal (WelcomePage)
    // Usamos pushAndRemoveUntil para destruir todo el historial de pantallas por seguridad.
    // Así evitamos que el usuario presione el botón de "Atrás" de Android y vuelva a entrar a su perfil cerrado.
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
        (Route<dynamic> route) => false, // Elimina absolutamente todas las pantallas anteriores
      );
    }
  }

  // Diseño visual de la pantalla
  @override
  Widget build(BuildContext context) {
    // Si sigue descargando datos, mostramos el cargador en toda la pantalla
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF009688))),
      );
    }

    // Si terminó de cargar pero no encontró nada (error raro), mostramos un mensaje
    if (_profileData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Perfil')),
        body: const Center(child: Text("No se pudo cargar el perfil")),
      );
    }

    // Extraemos los datos del JSON de forma segura. 
    // Usamos 'as num?' y '??" para evitar que la app explote si la base de datos nos manda un nulo o un formato raro.
    final int xp = (_profileData!['total_xp'] as num?)?.toInt() ?? 0;
    final int streak = (_profileData!['current_streak'] as num?)?.toInt() ?? 0;
    final String username = _profileData!['username'] ?? 'Estudiante';

    return Scaffold(
      backgroundColor: Colors.grey[50], // Fondo blanquito
      
      // La barra de arriba con el botón de salir
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0, // Sin sombra
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: _signOut, // Conectamos el botón con nuestra función de arriba
            tooltip: 'Cerrar Sesión',
          )
        ],
      ),
      
      // Cuerpo de la pantalla con scroll por si las pantallas son chiquitas
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // --- 1. ENCABEZADO Y FOTO DE PERFIL ---
              // Por ahora usamos un ícono genérico en lugar de una foto real
              const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF009688), // Color turquesa
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 16),
              // Nombre del usuario sacado de la base de datos
              Text(
                username,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              // Rango (Texto estático por ahora)
              Text(
                'Nivel de Estudio: Principiante', 
                style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),

              // --- 2. PANEL DE ESTADÍSTICAS ---
              // Fila con los dos cuadros grandes de puntaje
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard(
                    icon: Icons.local_fire_department_rounded,
                    color: Colors.orange,
                    value: '$streak',
                    label: 'Racha',
                  ),
                  _buildStatCard(
                    icon: Icons.diamond_rounded,
                    color: Colors.blueAccent,
                    value: '$xp',
                    label: 'Puntos XP',
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // --- 3. SECCIÓN DE LOGROS (Visual por ahora) ---
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Logros y Medallas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                ),
              ),
              const SizedBox(height: 16),
              
              // Tarjetitas de ejemplo simulando logros desbloqueados
              _buildAchievementTile(
                icon: Icons.star_rounded,
                title: 'Primera Lección',
                subtitle: 'Completado',
                color: Colors.amber,
              ),
              const SizedBox(height: 12),
              _buildAchievementTile(
                icon: Icons.security_rounded,
                title: 'Estudiante Dedicado',
                subtitle: 'Racha de 5 días',
                color: Colors.indigo,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- FUNCIONES DE DIBUJO RÁPIDO ---
  // Hacemos estas funciones chiquitas para no repetir el mismo código enorme dos veces

  // Dibuja los cuadritos grandes de XP y Racha
  Widget _buildStatCard({required IconData icon, required Color color, required String value, required String label}) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // Sombrita suave
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // Dibuja las tarjetas alargadas de los logros
  Widget _buildAchievementTile({required IconData icon, required String title, required String subtitle, required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), // Fondo semitransparente del mismo color que el ícono
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      ),
    );
  }
}