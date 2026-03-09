import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/flashcard_entity.dart';
import '../../domain/repositories/level_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class FlashcardsPage extends StatefulWidget {
  final String documentId;
  final String topicId; 

  const FlashcardsPage({
    super.key, 
    required this.documentId, 
    required this.topicId, 
  });

  @override
  State<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends State<FlashcardsPage> with SingleTickerProviderStateMixin {
  List<FlashcardEntity> _cards = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _showBack = false; 
  
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadCards();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: pi).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    try {
      final cards = await di.sl<LevelRepository>().getFlashcards(widget.documentId, widget.topicId);
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (e) {
      print("Error cargando flashcards: $e");
      setState(() => _isLoading = false);
    }
  }

  void _flipCard() {
    if (_controller.isAnimating) return;
    
    setState(() {
      _showBack = !_showBack;
    });
    
    if (_showBack) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _nextCard() {
    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
        _showBack = false; 
      });
      _controller.reset();
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() async{
    di.sl<AuthRepository>().addXp(10); 
    
    // --- MARCAR NIVEL COMO COMPLETADO EN DB ---
    await di.sl<LevelRepository>().markLevelCompleted(widget.topicId);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("¡Nivel Completado! 🎉"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Has repasado todos los conceptos clave."),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt, color: Colors.orange),
                const SizedBox(width: 8),
                const Text("+10 XP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
              ],
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
              Navigator.pop(context); 
            },
            child: const Text("Volver al Mapa"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("No hay flashcards disponibles para este tema.")),
      );
    }

    final progress = (_currentIndex + 1) / _cards.length;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Repaso Rápido"),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(value: progress, color: AppTheme.teal),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            Text(
              "${_currentIndex + 1} / ${_cards.length}",
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: Colors.grey[600]
              ),
            ),
            const SizedBox(height: 40),
            
            Expanded(
              child: GestureDetector(
                onTap: _flipCard,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final isUnder = _animation.value > pi / 2;
                    final rotation = isUnder ? _animation.value - pi : _animation.value;
                    
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001) 
                        ..rotateY(rotation),
                      child: isUnder 
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(pi),
                              child: _buildCardFace(
                                text: _cards[_currentIndex].back, 
                                isFront: false,
                                color: Colors.indigo[50]!,
                              ),
                            )
                          : _buildCardFace(
                              text: _cards[_currentIndex].front, 
                              isFront: true,
                              color: Colors.white,
                            ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            AnimatedOpacity(
              opacity: _showBack ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_showBack,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.close, Colors.red[400]!, "Repasar", () {
                      _nextCard(); 
                    }),
                    _buildActionButton(Icons.check, Colors.green[500]!, "Lo sé", () {
                      _nextCard();
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFace({required String text, required bool isFront, required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 2, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isFront) ...[
            Text(
              "RESPUESTA",
              style: TextStyle(color: AppTheme.teal.withOpacity(0.7), letterSpacing: 1.5, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
          
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(), 
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: isFront ? FontWeight.bold : FontWeight.normal,
                    color: Colors.black87,
                    height: 1.4, 
                  ),
                ),
              ),
            ),
          ),
          
          if (isFront) ...[
            const SizedBox(height: 20),
            Text(
              "PREGUNTA",
              style: TextStyle(color: Colors.grey[400], letterSpacing: 1.5, fontSize: 12),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, String label, VoidCallback onTap) {
    return Column(
      children: [
        FloatingActionButton(
          heroTag: label,
          onPressed: onTap,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}