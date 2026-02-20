import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/flashcard_entity.dart';
import '../../domain/repositories/level_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class FlashcardsPage extends StatefulWidget {
  final String documentId;

  const FlashcardsPage({super.key, required this.documentId});

  @override
  State<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends State<FlashcardsPage> with SingleTickerProviderStateMixin {
  List<FlashcardEntity> _cards = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _showBack = false; // ¿Estamos viendo la respuesta?
  
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
      final cards = await di.sl<LevelRepository>().getFlashcards(widget.documentId);
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (e) {
      print("Error cargando cartas: $e");
      setState(() => _isLoading = false);
    }
  }

  void _flipCard() {
    if (_showBack) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _showBack = !_showBack);
  }

  void _nextCard() {
    if (_currentIndex < _cards.length - 1) {
      _controller.reset();
      setState(() {
        _currentIndex++;
        _showBack = false;
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    // 1. Sumar XP en segundo plano
    di.sl<AuthRepository>().addXp(10); 

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
              children: const [
                Icon(Icons.bolt, color: Colors.orange),
                SizedBox(width: 8),
                Text("+10 XP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
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
            child: const Text("Genial"),
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
        body: const Center(child: Text("No hay cartas disponibles.")),
      );
    }

    final currentCard = _cards[_currentIndex];
    final progress = (_currentIndex + 1) / _cards.length;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Conceptos Clave"),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(value: progress, color: AppTheme.teal),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            "Carta ${_currentIndex + 1} de ${_cards.length}",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 20),
          
          // --- ÁREA DE LA TARJETA ---
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _flipCard,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final angle = _animation.value;
                    final isFront = angle < pi / 2;
                    
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      alignment: Alignment.center,
                      child: isFront
                          ? _buildCardFace(currentCard.front, isFront: true)
                          : Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(pi),
                              child: _buildCardFace(currentCard.back, isFront: false),
                            ),
                    );
                  },
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // --- CONTROLES ---
          // Usamos un Container con altura fija para evitar saltos en la UI
          SizedBox(
            height: 100,
            child: _showBack
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.refresh, Colors.orange, "Repasar", _nextCard),
                    _buildActionButton(Icons.check, Colors.green, "Lo sabía", _nextCard),
                  ],
                )
              : const Center(
                  child: Text(
                    "Toca la carta para ver la respuesta",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCardFace(String text, {required bool isFront}) {
    return Container(
      width: 320, // Un poco más ancho
      height: 450, // Un poco más alto
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: isFront ? null : Border.all(color: AppTheme.teal, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFront ? Icons.help_outline : Icons.lightbulb,
            size: 40,
            color: isFront ? AppTheme.darkBlue : AppTheme.teal,
          ),
          const SizedBox(height: 20),
          
          // --- CORRECCIÓN DE OVERFLOW ---
          // Usamos Expanded + SingleChildScrollView para que el texto sea deslizable
          // si es demasiado largo.
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(), // Efecto de rebote al scrollear
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20, // Letra un poco más legible
                    fontWeight: isFront ? FontWeight.bold : FontWeight.normal,
                    color: Colors.black87,
                    height: 1.4, // Mejor interlineado para lectura
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