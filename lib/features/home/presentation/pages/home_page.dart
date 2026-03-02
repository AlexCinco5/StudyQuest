import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/document_entity.dart';
import '../bloc/home_bloc.dart';
import 'level_map_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<HomeBloc>()..add(LoadDocuments()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  
  Future<void> _pickAndUploadFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;

      if (context.mounted) {
        context.read<HomeBloc>().add(UploadDocumentRequested(file, fileName));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Subiendo '$fileName'..."),
            backgroundColor: AppTheme.darkBlue,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else {
      if (result != null && result.files.single.path == null) {
         print("Error: El path del archivo es nulo (¿Estás en Web?)");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      
      // --- APPBAR ACTUALIZADO CON BLOCBUILDER ---
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            String xpDisplay = "0";
            String streakDisplay = "0";

            if (state is HomeLoaded && state.profile != null) {
              xpDisplay = state.profile.totalXp.toString();
              streakDisplay = state.profile.currentStreak.toString();
            }

            return AppBar(
              title: const Text("Mis Mundos", style: TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: false,
              backgroundColor: Colors.white,
              elevation: 0,
              foregroundColor: Colors.black,
              actions: [
                _buildStatBadge(Icons.local_fire_department, streakDisplay, Colors.orange),
                _buildStatBadge(Icons.diamond, xpDisplay, Colors.blueAccent),
                const SizedBox(width: 16),
              ],
            );
          },
        ),
      ),
      
      // --- EL RESTO QUEDA EXACTAMENTE IGUAL ---
      body: BlocConsumer<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state is HomeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is HomeLoaded) {
            // Aquí podrías mostrar un confetti
          }
        },
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.teal));
          } else if (state is HomeLoaded) {
            if (state.documents.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<HomeBloc>().add(LoadDocuments());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: _buildEmptyState(),
                  ),
                ),
              );
            }
            
            return RefreshIndicator(
              color: AppTheme.teal,
              backgroundColor: Colors.white,
              onRefresh: () async {
                context.read<HomeBloc>().add(LoadDocuments());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: state.documents.length,
                itemBuilder: (context, index) {
                  final doc = state.documents[index];
                  return _buildWorldCard(context, doc);
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickAndUploadFile(context),
        label: const Text("Nuevo Mundo PDF"),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.teal,
      ),
    );
  }

  Widget _buildWorldCard(BuildContext context, DocumentEntity doc) {
    final isProcessing = doc.status == 'processing';
    final progress = isProcessing ? 0.05 : 0.0; 

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isProcessing 
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("La IA está creando tu mundo, espera un momento...")),
              );
            }
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LevelMapPage(
                    documentId: doc.id,
                    worldTitle: doc.title,
                    worldColor: AppTheme.darkBlue,
                  ),
                ),
              );
            },
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: isProcessing ? Colors.grey[400] : AppTheme.darkBlue,
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: Icon(
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
                      Text(
                        doc.title,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (isProcessing)
                        const Row(
                          children: [
                            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                            SizedBox(width: 8),
                            Text("Creando lecciones...", style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic)),
                          ],
                        )
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
                const Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

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