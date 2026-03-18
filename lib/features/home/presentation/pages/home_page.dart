import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Herramienta mágica para abrir los archivos del celular
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/document_entity.dart';
import '../bloc/home_bloc.dart';
import 'level_map_page.dart';
import '../../presentation/pages/profile_page.dart';

// Este es el cascarón de la pantalla principal
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Aquí inyectamos el cerebro (HomeBloc) a la pantalla
    // El "..add(LoadDocuments())" le dice al bloc "oye, apenas nazcas ponte a buscar mis archivos"
    return BlocProvider(
      create: (_) => di.sl<HomeBloc>()..add(LoadDocuments()),
      child: const _HomeView(),
    );
  }
}

// Esta es la pantalla real, es Stateful porque tiene animaciones y estados que cambian
class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  
  // Función para abrir la galería de archivos del celular y escoger un PDF
  Future<void> _pickAndUploadFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // Filtramos para que solo vea PDFs
    );

    // Si el usuario sí escogió algo y no canceló
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;

      // context.mounted verifica que la pantalla no se haya cerrado mientras el usuario escogía el archivo
      if (context.mounted) {
        // Le avisamos al Bloc que suba el archivo
        context.read<HomeBloc>().add(UploadDocumentRequested(file, fileName));
        
        // Mensajito abajo en la pantalla para que el usuario sepa que algo está pasando
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Subiendo '$fileName'..."),
            backgroundColor: AppTheme.darkBlue,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else {
      // Prevención de errores raros, sobre todo si en el futuro queremos que la app corra en Web
      if (result != null && result.files.single.path == null) {
         print("Error: El path del archivo es nulo (¿Estás en Web?)");
      }
    }
  }

  // Función que dibuja la cajita de advertencia cuando quieres borrar un mundo
  void _showDeleteDialog(BuildContext context, DocumentEntity doc) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Destruir Mundo'),
          ],
        ),
        content: Text('¿Estás seguro de que quieres eliminar "${doc.title}"? Perderás todo el progreso, XP y niveles de este mundo. Esta acción no se puede deshacer.'),
        actions: [
          // Botón para arrepentirse
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          // Botón rojo peligroso
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext); // Quitamos la cajita de advertencia
              // Disparamos el evento para que el Bloc borre esto de internet
              context.read<HomeBloc>().add(DeleteDocumentRequested(doc.id));
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // Dibujado principal de la pantalla
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      
      // La barra de arriba (AppBar) necesita ser un PreferredSize para que Flutter no se queje
      // La envolvemos en un BlocBuilder para que la barra se actualice si ganamos puntos
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            // Valores por defecto por si el internet está lento
            String xpDisplay = "0";
            String streakDisplay = "0";

            // Si el Bloc ya logró cargar el perfil, actualizamos los numeritos
            if (state is HomeLoaded && state.profile != null) {
              xpDisplay = state.profile.totalXp.toString();
              streakDisplay = state.profile.currentStreak.toString();
            }

            return AppBar(
              automaticallyImplyLeading: false, // Quita la flecha de "Atrás" porque esta es la pantalla principal
              title: const Text("Mis Mundos", style: TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: false,
              backgroundColor: Colors.white,
              elevation: 0,
              foregroundColor: Colors.black,
              actions: [
                // Dibujamos el fueguito de los días seguidos y el diamante de los puntos
                _buildStatBadge("🔥", streakDisplay, Colors.orange),
                _buildStatBadge("💎", xpDisplay, Colors.blueAccent),
                
                // Botón circular para ir a ver nuestro perfil
                Padding(
                  padding: const EdgeInsets.only(right: 12.0, left: 8.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePage()),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey[200],
                      child: const Icon(Icons.person, size: 20, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      
      // El cuerpo principal de la pantalla.
      // Usamos BlocConsumer para escuchar errores Y dibujar cosas al mismo tiempo
      body: BlocConsumer<HomeBloc, HomeState>(
        listener: (context, state) {
          // Si el Bloc escupe un error, mostramos una barrita roja abajo
          if (state is HomeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          // Si el Bloc está ocupado, mostramos una bolita girando
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.teal));
          } else if (state is HomeLoaded) {
            // Si cargó todo pero no hay archivos, mostramos el diseño vacío
            if (state.documents.isEmpty) {
              return RefreshIndicator(
                // Permitimos que el usuario jale la pantalla hacia abajo para recargar
                onRefresh: () async {
                  context.read<HomeBloc>().add(LoadDocuments());
                },
                child: SingleChildScrollView(
                  // physics obliga a que siempre se pueda jalar, incluso si la lista es pequeña
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: _buildEmptyState(),
                  ),
                ),
              );
            }
            
            // Si sí hay archivos, los dibujamos en forma de lista
            return RefreshIndicator(
              color: AppTheme.teal,
              backgroundColor: Colors.white,
              onRefresh: () async {
                context.read<HomeBloc>().add(LoadDocuments());
                // Hacemos que la bolita de carga espere medio segundo para que se vea bonita
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: state.documents.length,
                // itemBuilder crea una tarjeta visual por cada PDF que haya
                itemBuilder: (context, index) {
                  final doc = state.documents[index];
                  return _buildWorldCard(context, doc);
                },
              ),
            );
          }
          // Fallback por si acaso: si no pasa nada, no dibujamos nada
          return const SizedBox.shrink();
        },
      ),
      
      // El botón flotante gigante de la esquina para subir archivos
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickAndUploadFile(context),
        label: const Text("Nuevo Mundo PDF"),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.teal,
      ),
    );
  }

  // Función que dibuja la tarjeta rectangular que representa a un PDF
  Widget _buildWorldCard(BuildContext context, DocumentEntity doc) {
    // Revisamos si la IA sigue leyendo el PDF o si ya terminó
    final isProcessing = doc.status == 'processing';
    final progress = isProcessing ? 0.05 : 0.0; 

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      // Clip recorta el contenido para que no se salga de las esquinas redondas
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Si dejas apretado el dedo, te pregunta si quieres borrar el mundo
        // (A menos que se esté procesando, en ese caso bloqueamos el borrado para no romper cosas)
        onLongPress: isProcessing ? null : () => _showDeleteDialog(context, doc), 
        
        // Si tocas la tarjeta normal...
        onTap: isProcessing 
          // Si está procesando, solo te avisa que te esperes
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("La IA está creando tu mundo, espera un momento...")),
              );
            }
          // Si ya está listo, te manda a la pantalla del mapa
          : () async { 
              // await es clave aquí: la app se queda "pausada" esperando a que cierres el mapa
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LevelMapPage(
                    documentId: doc.id,
                    worldTitle: doc.title,
                    worldColor: AppTheme.darkBlue,
                  ),
                ),
              );
              
              // Cuando regresas del mapa a esta pantalla principal, le decimos al BLoC
              // que recargue los datos para que tu XP y progreso se actualicen
              if (context.mounted) {
                context.read<HomeBloc>().add(LoadDocuments());
              }
            },
        // Todo este Container es para que la tarjeta se vea bonita con fondo azul o gris
        child: Container(
          constraints: const BoxConstraints(minHeight: 120),
          decoration: BoxDecoration(
            color: isProcessing ? Colors.grey[400] : AppTheme.darkBlue,
            // Ponemos una imagencita de patrón tenue de fondo
            image: DecorationImage(
              image: const AssetImage('assets/images/pattern.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.1), BlendMode.dstATop),
              onError: (_, __) {},
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // El ícono redondo de la izquierda
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: Icon(
                    // Si carga ponemos un reloj de arena, si no un mundo
                    isProcessing ? Icons.hourglass_empty : Icons.public,
                    color: Colors.white, size: 32
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // El título del PDF
                      Text(
                        doc.title,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        // maxLines corta el título si está muy largo y le pone tres puntitos (...)
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      
                      // Si está procesando, dibujamos la bolita chiquita girando
                      if (isProcessing)
                        const Row(
                          children: [
                            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                            SizedBox(width: 8),
                            Text("Creando lecciones...", style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic)),
                          ],
                        )
                      // Si ya está listo, dibujamos una barrita de progreso
                      else
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.black12,
                                valueColor: const AlwaysStoppedAnimation(Colors.white),
                                minHeight: 6, borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text("0%", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                    ],
                  ),
                ),
                // La flechita de la derecha
                const Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Función atajo para no repetir código al dibujar los puntajes de fuego y diamantes
  Widget _buildStatBadge(String emoji, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)), 
          const SizedBox(width: 6),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  // El dibujo que aparece cuando el usuario es nuevo y no tiene ningún PDF subido
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rocket_launch, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("¡Empieza tu aventura!", style: TextStyle(fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Sube un PDF para generar un mundo de estudio"),
        ],
      ),
    );
  }
}