import 'dart:math';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart'; // <--- IMPORTAMOS TTS
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
  // Usamos Queue en lugar de List para el sistema Anki (Repetición Espaciada)
  final Queue<FlashcardEntity> _cardsQueue = Queue();
  int _totalInitialCards = 0;
  
  bool _isLoading = true;
  bool _showBack = false; 
  
  late AnimationController _controller;
  late Animation<double> _animation;

  // --- MOTOR TTS ---
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadCards();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  // --- CONFIGURACIÓN DE VOZ ---
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("es-MX"); 
    await _flutterTts.setSpeechRate(0.5);   
    await _flutterTts.setVolume(1.0);       
    await _flutterTts.setPitch(1.0);        
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _flutterTts.stop(); 
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    try {
      final cards = await di.sl<LevelRepository>().getFlashcards(widget.documentId, widget.topicId);
      setState(() {
        _cardsQueue.addAll(cards);
        _totalInitialCards = cards.length;
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
      // ¡Magia! Lee la parte de atrás automáticamente
      _speak(_cardsQueue.first.back); 
    } else {
      _controller.reverse();
      _flutterTts.stop(); 
    }
  }

  // --- LÓGICA DE APRENDIZAJE (SPACED REPETITION) ---

  void _markAsLearned() {
    _flutterTts.stop();
    // La aprendió: La sacamos definitivamente de la fila
    _cardsQueue.removeFirst();
    _moveToNextCard();
  }

  void _markForReview() {
    _flutterTts.stop();
    // Necesita repaso: La sacamos y la mandamos AL FINAL de la fila
    final currentCard = _cardsQueue.removeFirst();
    _cardsQueue.addLast(currentCard);
    _moveToNextCard();
  }

  void _moveToNextCard() {
    if (_cardsQueue.isEmpty) {
      _showCompletionDialog();
      return;
    }

    // Volteamos la carta súper rápido sin que se note para preparar la siguiente
    _controller.value = 0;
    setState(() {
      _showBack = false;
    });
  }

  void _showCompletionDialog() async {
    di.sl<AuthRepository>().addXp(10); 
    await di.sl<LevelRepository>().markLevelCompleted(widget.topicId);

    if (!mounted) return;

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

    if (_cardsQueue.isEmpty && _totalInitialCards == 0) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("No hay flashcards disponibles para este tema.")),
      );
    }

    // Calculamos el progreso basado en cuántas cartas se han ELIMINADO de la cola
    final int cardsLeft = _cardsQueue.length;
    final int cardsLearned = _totalInitialCards - cardsLeft;
    final double progress = (_totalInitialCards > 0) ? (cardsLearned / _totalInitialCards).clamp(0.0, 1.0) : 0.0;

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
              "Restantes: $cardsLeft",
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
                    final angle = _animation.value;
                    // Detectamos si la tarjeta pasó la mitad del giro (90 grados)
                    final isFront = angle < (pi / 2);

                    // Aquí está el truco REAL para evitar el espejo:
                    // Si estamos viendo la parte de atrás, giramos el contenedor entero
                    // usando una rotación inversa (-pi) para cancelar el espejo
                    final transform = Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // Perspectiva 3D
                      ..rotateY(isFront ? angle : angle - pi);

                    return Transform(
                      alignment: Alignment.center,
                      transform: transform,
                      child: _buildCardFace(
                        // Dependiendo del ángulo, mandamos el texto de enfrente o el de atrás
                        text: isFront ? _cardsQueue.first.front : _cardsQueue.first.back,
                        isFront: isFront,
                        color: isFront ? Colors.white : Colors.indigo[50]!,
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
                    _buildActionButton(Icons.close, Colors.red[400]!, "Repasar", _markForReview),
                    _buildActionButton(Icons.check, Colors.green[500]!, "Lo sé", _markAsLearned),
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