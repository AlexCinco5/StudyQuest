import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/level_entity.dart';
import '../bloc/level_bloc.dart';
import 'flashcards_page.dart'; // <--- IMPORTANTE: Importamos la pantalla de juego

class LevelMapPage extends StatelessWidget {
  final String documentId; // Necesitamos el ID para buscar en DB
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
    return BlocProvider(
      create: (_) => di.sl<LevelBloc>()..add(LoadLevels(documentId)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(worldTitle),
          backgroundColor: worldColor,
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [worldColor.withOpacity(0.1), Colors.white],
            ),
          ),
          child: BlocBuilder<LevelBloc, LevelState>(
            builder: (context, state) {
              if (state is LevelLoading) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.teal));
              } else if (state is LevelError) {
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
                return _buildPath(context, state.levels); // Pasamos context para navegar
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPath(BuildContext context, List<LevelEntity> levels) {
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 40),
      itemCount: levels.length + 1, // +1 para la meta final (Cofre)
      itemBuilder: (context, index) {
        if (index == levels.length) {
          // Meta Final (Cofre)
          return _buildPathItem(
            child: Column(
              children: [
                const Icon(Icons.emoji_events, size: 60, color: Colors.amber),
                const SizedBox(height: 8),
                Text("¡Meta Final!", style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.bold)),
              ],
            ),
            isLeft: index % 2 == 0,
          );
        }

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

  // Nodo del Nivel mejorado
  Widget _buildLevelNode({
    required BuildContext context,
    required LevelEntity level,
    required Color color,
    required bool isLeft,
  }) {
    // Icono según tipo de nivel
    IconData icon;
    switch (level.type) {
      case LevelType.flashcards:
        icon = Icons.style; // Cartas
        break;
      case LevelType.quiz:
        icon = Icons.quiz; // Preguntas
        break;
      case LevelType.exam:
        icon = Icons.history_edu; // Examen
        break;
      default:
        icon = Icons.star;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          isLeft ? const SizedBox(width: 40) : const Spacer(),
          Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: level.isLocked
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Completa el nivel anterior para desbloquear este.")),
                        );
                      }
                    : () {
                        // --- LÓGICA DE NAVEGACIÓN ---
                        if (level.type == LevelType.flashcards) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FlashcardsPage(documentId: documentId),
                            ),
                          );
                        } else if (level.type == LevelType.quiz) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("🚧 Modo Quiz: ¡Próximamente! 🚧"),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: level.isLocked ? Colors.grey[300] : color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Icon(
                    level.isLocked ? Icons.lock : icon,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: Text(
                  level.title,
                  style: TextStyle(
                    color: level.isLocked ? Colors.grey : color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          isLeft ? const Spacer() : const SizedBox(width: 40),
        ],
      ),
    );
  }

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