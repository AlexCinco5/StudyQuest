import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart'; 
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/reactive_avatar.dart'; 
import '../../../../injection_container.dart' as di;
import '../../domain/entities/quiz_entity.dart';
import '../../domain/repositories/level_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class QuizPage extends StatefulWidget {
  final String documentId;
  final String topicId; // <--- NUEVO

  const QuizPage({
    super.key, 
    required this.documentId, 
    required this.topicId, // <--- NUEVO
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<QuizEntity> _questions = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  
  int? _selectedOptionIndex;
  bool _isAnswered = false;
  bool _isCorrect = false;

  AvatarReaction _currentReaction = AvatarReaction.idle;
  bool _showAvatarPopUp = false; 
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadQuizzes();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizzes() async {
    try {
      final questions = await di.sl<LevelRepository>().getQuizzes(widget.documentId, widget.topicId);
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      print("Error cargando quizzes: $e");
      setState(() => _isLoading = false);
    }
  }

  void _checkAnswer(int selectedIndex) {
    if (_isAnswered) return;

    final currentQ = _questions[_currentIndex];
    final isCorrectNow = (selectedIndex == currentQ.correctIndex);

    setState(() {
      _selectedOptionIndex = selectedIndex;
      _isAnswered = true;
      _isCorrect = isCorrectNow;
      
      _currentReaction = isCorrectNow ? AvatarReaction.success : AvatarReaction.fail;
      _showAvatarPopUp = true; 
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showAvatarPopUp = false;
          _currentReaction = AvatarReaction.idle; 
        });
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
        _isAnswered = false;
        _isCorrect = false;
        _showAvatarPopUp = false; 
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    di.sl<AuthRepository>().addXp(20);
    _confettiController.play();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("¡Examen Completado! 🎓", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ReactiveAvatar(
              reaction: AvatarReaction.celebrate, 
              size: 120
            ),
            const SizedBox(height: 16),
            const Text("Has demostrado tu conocimiento.", textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, color: Colors.orange),
                  SizedBox(width: 8),
                  Text("+20 XP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
                ],
              ),
            )
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context); 
                Navigator.pop(context); 
              },
              child: const Text("Reclamar Recompensa"),
            ),
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

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("No hay preguntas disponibles para este tema.")),
      );
    }

    final currentQ = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Prueba Rápida"),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(value: progress, color: AppTheme.teal),
        ),
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- ZONA ARRIBA: PREGUNTA Y OPCIONES (SCROLLABLE) ---
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Pregunta ${_currentIndex + 1} / ${_questions.length}",
                          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentQ.question,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 30),

                        ...List.generate(currentQ.options.length, (index) {
                          return _buildOptionCard(index, currentQ.options[index], currentQ.correctIndex);
                        }),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // --- ZONA ABAJO: FEEDBACK Y BOTÓN (FIJA) ---
                if (_isAnswered)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isCorrect ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _isCorrect ? Colors.green : Colors.red),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(_isCorrect ? Icons.check_circle : Icons.error, 
                                 color: _isCorrect ? Colors.green : Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isCorrect ? "¡Correcto!" : "Incorrecto",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isCorrect ? Colors.green[800] : Colors.red[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (currentQ.explanation.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 120),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Text(
                                currentQ.explanation,
                                style: TextStyle(color: Colors.grey[800]),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _nextQuestion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isCorrect ? Colors.green : AppTheme.darkBlue,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(_currentIndex == _questions.length - 1 ? "Terminar" : "Siguiente"),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // --- POP-UP AVATAR ---
          IgnorePointer(
            ignoring: !_showAvatarPopUp,
            child: Container(
              alignment: Alignment.center, 
              margin: const EdgeInsets.only(bottom: 100), 
              child: AnimatedOpacity(
                opacity: _showAvatarPopUp ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedScale(
                  scale: _showAvatarPopUp ? 1.0 : 0.1,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut, 
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5)
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: ReactiveAvatar(
                      reaction: _currentReaction,
                      size: 150, 
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- CONFETTI ---
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.1,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(int index, String text, int correctIndex) {
    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey[300]!;
    
    if (_isAnswered) {
      if (index == correctIndex) {
        backgroundColor = Colors.green[100]!;
        borderColor = Colors.green;
      } else if (index == _selectedOptionIndex && index != correctIndex) {
        backgroundColor = Colors.red[100]!;
        borderColor = Colors.red;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: _isAnswered ? null : () => _checkAnswer(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: borderColor,
                child: Text(
                  String.fromCharCode(65 + index), 
                  style: TextStyle(fontSize: 12, color: _isAnswered ? Colors.white : Colors.grey[600]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}