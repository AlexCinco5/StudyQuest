import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
// Importamos la caja de herramientas (inyección de dependencias) para sacar el BLoC
import '../../../../injection_container.dart' as di;
import '../../domain/entities/level_entity.dart';
import '../bloc/level_bloc.dart';
import 'flashcards_page.dart'; 
import 'quiz_page.dart'; 
import 'study_guide_page.dart'; 

// Esta es la pantalla que parece un mapa de juego (estilo Candy Crush o Duolingo)
// Muestra el camino de aprendizaje que la IA armó para un PDF en específico.
class LevelMapPage extends StatelessWidget {
  // Datos que recibe la pantalla desde la página anterior (Home)
  final String documentId;
  final String worldTitle;
  final Color worldColor;

  const LevelMapPage({
    super.key,
    required this.documentId,
    required this.worldTitle,
    required this.worldColor,
  });

  @override
  Widget build(BuildContext context) {
    // Le enchufamos su cerebro (LevelBloc) y le decimos que empiece a buscar los niveles
    // usando el ID del documento apenas se construya la pantalla.
    return BlocProvider(
      create: (_) => di.sl<LevelBloc>()..add(LoadLevels(documentId)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(worldTitle),
          backgroundColor: worldColor,
          elevation: 0,
        ),
        body: Container(
          // Le ponemos un fondo difuminado bonito que baja de color hasta blanco
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [worldColor.withOpacity(0.1), Colors.white],
            ),
          ),
          // El BlocBuilder es el que redibuja la pantalla según lo que el cerebro diga
          child: BlocBuilder<LevelBloc, LevelState>(
            builder: (context, state) {
              if (state is LevelLoading) {
                // Si sigue pensando, mostramos un círculo de carga
                return const Center(child: CircularProgressIndicator(color: AppTheme.teal));
              } else if (state is LevelError) {
                // Si el internet falló, mostramos el texto del error en rojo
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              } else if (state is LevelLoaded) {
                // Si todo salió bien, mandamos a dibujar la viborita (el mapa)
                return _buildPath(context, state.levels);
              }
              // Por defecto no pintamos nada
              return const SizedBox.shrink();
            },
          ),
        ),
        // --- BOTÓN FLOTANTE ---
        // Este botón manda a la pantalla "aburrida" donde está el texto plano para leer
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudyGuidePage(
                  documentId: documentId,
                  worldTitle: worldTitle,
                ),
              ),
            );
          },
          icon: const Icon(Icons.menu_book_rounded),
          label: const Text("Guía de Estudio"),
          backgroundColor: worldColor, // Combina con el color que le tocó a este mundo
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  // Función que construye la lista de círculos en zigzag
  Widget _buildPath(BuildContext context, List<LevelEntity> levels) {
    // Si la IA procesó el PDF pero extrañamente no encontró temas
    if (levels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "Aún no hay lecciones generadas.\nIntenta recargar la página.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Dibujamos la lista de niveles
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 40),
      // Le sumamos 1 al tamaño de la lista para poder pintar el cofre final al fondo
      itemCount: levels.length + 1, 
      itemBuilder: (context, index) {
        // Si ya pasamos todos los niveles normales, pintamos el premio final
        if (index == levels.length) {
          return _buildPathItem(
            child: Column(
              children: [
                const Icon(Icons.emoji_events, size: 60, color: Colors.amber),
                const SizedBox(height: 8),
                Text("¡Meta Final!", style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.bold)),
              ],
            ),
            // Esto del índice par/impar sirve para que un nivel quede a la izquierda y el otro a la derecha (zigzag)
            isLeft: index % 2 == 0,
          );
        }

        // Si es un nivel normal, llamamos a la función que dibuja el circulito
        final level = levels[index];
        return _buildLevelNode(
          context: context,
          level: level,
          color: worldColor,
          isLeft: index % 2 == 0,
        );
      },
    );
  }

  // Función pesada que dibuja cada círculo del mapa individualmente
  Widget _buildLevelNode({
    required BuildContext context,
    required LevelEntity level,
    required Color color,
    required bool isLeft, // ¿Va a la izquierda o a la derecha de la pantalla?
  }) {
    // Escogemos el dibujito que va adentro del círculo dependiendo de qué tipo de juego es
    IconData icon;
    switch (level.type) {
      case LevelType.flashcards:
        icon = Icons.style; // Unas cartas
        break;
      case LevelType.quiz:
        icon = Icons.quiz; // Un signo de interrogación
        break;
      case LevelType.exam:
        icon = Icons.history_edu;
        break;
      default:
        icon = Icons.star;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        // Movemos todo el bloque a la izquierda o a la derecha
        mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          // Empujamos el círculo un poquito hacia el centro usando espacios vacíos
          isLeft ? const SizedBox(width: 40) : const Spacer(),
          Column(
            children: [
              // El círculo en sí, que es tocable (InkWell)
              InkWell(
                borderRadius: BorderRadius.circular(50), // Para que el efecto de toque sea redondo
                // Lógica de qué pasa al tocar:
                onTap: level.isLocked
                    // Si el nivel tiene candado, no te dejamos jugar y te avisamos abajo
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Completa el nivel anterior para desbloquear este.")),
                        );
                      }
                    // Si está desbloqueado...
                    : () async { 
                        // Te mandamos a la pantalla de flashcards o a la de examen según toque
                        if (level.type == LevelType.flashcards) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              // Le pasamos el ID del documento y el ID de este tema específico
                              builder: (_) => FlashcardsPage(documentId: documentId, topicId: level.id),
                            ),
                          );
                        } else if (level.type == LevelType.quiz) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizPage(documentId: documentId, topicId: level.id),
                            ),
                          );
                        }
                        
                        // Cuando cierras el minijuego y regresas a este mapa, le avisamos al cerebro
                        // que vuelva a checar la base de datos por si ganaste y hay que quitar candados
                        if (context.mounted) {
                          context.read<LevelBloc>().add(LoadLevels(documentId));
                        }
                      },
                // Decoración del círculo
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    // Si está bloqueado lo pintamos gris aburrido, si no, del color del mundo
                    color: level.isLocked ? Colors.grey[300] : color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4), // Borde blanco grueso
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4), // Sombrita hacia abajo
                      )
                    ],
                  ),
                  child: Icon(
                    // Si está bloqueado dibujamos un candado, si no, el ícono que elegimos arriba
                    level.isLocked ? Icons.lock : icon,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // El título del nivel (ej. "Ciclo de Krebs") en una cajita blanca flotante
              Container(
                constraints: const BoxConstraints(maxWidth: 140), // Para que el texto no se estire al infinito
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                  ],
                ),
                child: Text(
                  level.title,
                  textAlign: TextAlign.center,
                  maxLines: 2, // Si el título es muy largo, lo cortamos en dos líneas
                  overflow: TextOverflow.ellipsis, // Si sigue siendo largo, le ponemos tres puntitos (...)
                  style: TextStyle(
                    // El texto es gris si está bloqueado, o de color vivo si se puede jugar
                    color: level.isLocked ? Colors.grey : color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    height: 1.2, // Interlineado
                  ),
                ),
              ),
            ],
          ),
          // El otro empujón para terminar de centrarlo a ojo
          isLeft ? const Spacer() : const SizedBox(width: 40),
        ],
      ),
    );
  }

  // Función atajo que solo sirve para mover el cofre del final a la izquierda o derecha
  Widget _buildPathItem({required Widget child, required bool isLeft}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          isLeft ? const SizedBox(width: 60) : const Spacer(),
          child,
          isLeft ? const Spacer() : const SizedBox(width: 60),
        ],
      ),
    );
  }
}