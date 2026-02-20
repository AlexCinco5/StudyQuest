import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/quiz_entity.dart';
import '../../domain/repositories/level_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
class QuizPage extends StatefulWidget {
  final String documentId;

  const QuizPage({super.key, required this.documentId});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<QuizEntity> _questions = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  
  // Estado de la respuesta actual
  int? _selectedOptionIndex;
  bool _isAnswered = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    try {
      final questions = await di.sl<LevelRepository>().getQuizzes(widget.documentId);
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
    if (_isAnswered) return; // Evitar doble toque

    final currentQ = _questions[_currentIndex];
    setState(() {
      _selectedOptionIndex = selectedIndex;
      _isAnswered = true;
      _isCorrect = (selectedIndex == currentQ.correctIndex);
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
        _isAnswered = false;
        _isCorrect = false;
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    // 2. Sumar XP (Más puntos por ser Quiz)
    di.sl<AuthRepository>().addXp(20);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("¡Examen Completado! 🎓"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Has demostrado tu conocimiento."),
            const SizedBox(height: 16),
             Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.bolt, color: Colors.orange),
                SizedBox(width: 8),
                Text("+20 XP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
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
            child: const Text("Reclamar Recompensa"),
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
        body: const Center(child: Text("No hay preguntas disponibles.")),
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Contador
            Text(
              "Pregunta ${_currentIndex + 1} / ${_questions.length}",
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Pregunta
            Text(
              currentQ.question,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Opciones
            ...List.generate(currentQ.options.length, (index) {
              return _buildOptionCard(index, currentQ.options[index], currentQ.correctIndex);
            }),

            const Spacer(),

            // Área de Retroalimentación (Solo visible al responder)
            if (_isAnswered)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isCorrect ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isCorrect ? Colors.green : Colors.red),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(_isCorrect ? Icons.check_circle : Icons.error, 
                             color: _isCorrect ? Colors.green : Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          _isCorrect ? "¡Correcto!" : "Incorrecto",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isCorrect ? Colors.green[800] : Colors.red[800],
                          ),
                        ),
                      ],
                    ),
                    if (currentQ.explanation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        currentQ.explanation,
                        style: TextStyle(color: Colors.grey[800]),
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(int index, String text, int correctIndex) {
    // Definir colores según estado
    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey[300]!;
    
    if (_isAnswered) {
      if (index == correctIndex) {
        // Esta es la correcta (siempre verde al final)
        backgroundColor = Colors.green[100]!;
        borderColor = Colors.green;
      } else if (index == _selectedOptionIndex && index != correctIndex) {
        // Esta fue la elegida incorrectamente (rojo)
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
                  String.fromCharCode(65 + index), // A, B, C, D...
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