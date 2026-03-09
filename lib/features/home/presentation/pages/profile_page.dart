import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../features/auth/presentation/pages/welcome_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("Usuario no logueado");

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      setState(() {
        _profileData = data;
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Error cargando perfil: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    // 1. Mostrar el Pop-up de confirmación
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
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false), // Devuelve false
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
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

    // 2. Si el usuario presionó "Cancelar", detenemos la función
    if (confirmar != true) return;

    // 3. Si confirmó, cerramos sesión en Supabase
    await _supabase.auth.signOut();

    // 4. Redirigimos a la WelcomePage destruyendo el historial (así no queda la flecha de atrás)
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF009688))),
      );
    }

    if (_profileData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Perfil')),
        body: const Center(child: Text("No se pudo cargar el perfil")),
      );
    }

    final int xp = (_profileData!['total_xp'] as num?)?.toInt() ?? 0;
    final int streak = (_profileData!['current_streak'] as num?)?.toInt() ?? 0;
    final String username = _profileData!['username'] ?? 'Estudiante';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: _signOut,
            tooltip: 'Cerrar Sesión',
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // --- 1. ENCABEZADO Y AVATAR ---
              const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF009688),
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                username,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Nivel de Estudio: Principiante', 
                style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),

              // --- 2. PANEL DE ESTADÍSTICAS ---
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

              // --- 3. SECCIÓN DE LOGROS ---
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Logros y Medallas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                ),
              ),
              const SizedBox(height: 16),
              
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

  Widget _buildStatCard({required IconData icon, required Color color, required String value, required String label}) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            color: color.withOpacity(0.1),
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