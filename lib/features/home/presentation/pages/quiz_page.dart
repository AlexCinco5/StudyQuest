import 'package:flutter/material.dart';
// Herramienta para hacer llover papelitos de colores cuando el usuario gana
import 'package:confetti/confetti.dart'; 
// Lector de voz para ayudar a la accesibilidad
import 'package:flutter_tts/flutter_tts.dart'; 
// Nuevo paquete para poder reproducir sonidos de "Ding!" o "Buzzer"
import 'package:audioplayers/audioplayers.dart'; 
import '../../../../core/theme/app_theme.dart';
// Importamos nuestro muñequito que cambia de cara
import '../../../../core/widgets/reactive_avatar.dart'; 
import '../../../../injection_container.dart' as di;
import '../../domain/entities/quiz_entity.dart';
import '../../domain/repositories/level_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

// Pantalla donde se juega el minijuego de preguntas de opción múltiple (Quiz)
class QuizPage extends StatefulWidget {
  final String documentId;
  final String topicId; 

  const QuizPage({
    super.key, 
    required this.documentId, 
    required this.topicId, 
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  // Aquí guardamos la lista de preguntas que nos manda la base de datos
  List<QuizEntity> _questions = [];
  bool _isLoading = true;
  // Para saber en qué número de pregunta vamos
  int _currentIndex = 0;
  
  // Variables para saber qué tocó el usuario y si le atinó o no
  int? _selectedOptionIndex;
  bool _isAnswered = false;
  bool _isCorrect = false;

  // --- SISTEMA DE VIDAS (Estilo videojuego) ---
  int _lives = 3; 

  // Variables para controlar la animación del muñequito (Avatar)
  AvatarReaction _currentReaction = AvatarReaction.idle;
  bool _showAvatarPopUp = false; 
  
  // Controladores para los efectos especiales
  late ConfettiController _confettiController;
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer(); // El reproductor de música

  @override
  void initState() {
    super.initState();
    // Preparamos el disparador de confeti
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _initTts(); 
    // Empezamos a descargar las preguntas apenas se abre la pantalla
    _loadQuizzes();
  }

  // Configuramos la voz del celular
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("es-MX"); 
    await _flutterTts.setSpeechRate(0.5);   
    await _flutterTts.setVolume(1.0);       
    await _flutterTts.setPitch(1.0);        
  }

  // Atajo para hacer hablar al celular
  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  // Reproductor de efectos de sonido
  Future<void> _playSound(bool isCorrect) async {
    try {
      // Dependiendo de si acertó o no, buscamos el archivo mp3 correcto en la carpeta del proyecto
      if (isCorrect) {
        await _audioPlayer.play(AssetSource('sounds/correct.mp3'));
      } else {
        await _audioPlayer.play(AssetSource('sounds/wrong.mp3'));
      }
    } catch (e) {
      // Si falla, avisamos en consola pero no cerramos la app
      print("Error reproduciendo audio: $e (Asegúrate de agregar los mp3 a assets/sounds/)");
    }
  }

  @override
  void dispose() {
    // Apagamos todo cuando el usuario se sale para no gastar batería a lo tonto
    _flutterTts.stop(); 
    _audioPlayer.dispose(); 
    _confettiController.dispose();
    super.dispose();
  }

  // Va a internet por las preguntas
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

  // Lógica principal: ¿Qué pasa cuando el usuario toca una respuesta?
  void _checkAnswer(int selectedIndex) {
    // Si ya había contestado, ignoramos los toques extra para evitar trampa o errores
    if (_isAnswered) return;

    final currentQ = _questions[_currentIndex];
    // Vemos si el índice del botón que tocó es igual al índice de la respuesta correcta de la base de datos
    final isCorrectNow = (selectedIndex == currentQ.correctIndex);

    setState(() {
      _selectedOptionIndex = selectedIndex;
      _isAnswered = true;
      _isCorrect = isCorrectNow;
      
      // Cambiamos la cara del muñequito y lo hacemos saltar a la pantalla
      _currentReaction = isCorrectNow ? AvatarReaction.success : AvatarReaction.fail;
      _showAvatarPopUp = true; 
    });

    // Hacemos el ruidito
    _playSound(isCorrectNow);

    // Si se equivocó, le quitamos una vida
    if (!isCorrectNow) {
      setState(() {
        _lives--;
      });
      
      // Si ya no le quedan corazones, sacamos el aviso de "Game Over"
      if (_lives <= 0) {
        _showGameOverDialog();
        return; // Detenemos la función aquí mismo
      }
    }

    // Un temporizador automático: Esperamos 1.5 segundos y luego ocultamos al muñequito
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _lives > 0) {
        setState(() {
          _showAvatarPopUp = false;
          _currentReaction = AvatarReaction.idle; // Lo regresamos a su cara normal
        });
      }
    });
  }

  // Avanzar a la siguiente pregunta
  void _nextQuestion() {
    _flutterTts.stop(); // Callamos a la voz por si seguía leyendo
    
    // Si todavía hay preguntas en la lista...
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        // Limpiamos la pantalla para la pregunta nueva
        _selectedOptionIndex = null;
        _isAnswered = false;
        _isCorrect = false;
        _showAvatarPopUp = false; 
      });
    } else {
      // Si ya no hay más preguntas, mostramos el premio
      _showCompletionDialog();
    }
  }

  // --- AVISO DE DERROTA ---
  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Obliga a apretar el botón
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("¡Te quedaste sin vidas! 💔", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Metemos al muñequito llorando directamente en el mensaje
            const ReactiveAvatar(reaction: AvatarReaction.fail, size: 120),
            const SizedBox(height: 16),
            const Text("No te desanimes. Repasa los apuntes y vuelve a intentarlo.", textAlign: TextAlign.center),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                _flutterTts.stop();
                Navigator.pop(context); // Cierra popup
                Navigator.pop(context); // Lo patea de regreso al mapa
              },
              child: const Text("Terminar Intento"),
            ),
          ),
        ],
      ),
    );
  }

  // Aviso de victoria (es casi igual que el de flashcards)
  void _showCompletionDialog() async {
    // Le damos más puntos porque el examen es más difícil
    di.sl<AuthRepository>().addXp(20);
    await di.sl<LevelRepository>().markLevelCompleted(widget.topicId);
    
    // Disparamos los papelitos de colores
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
                _flutterTts.stop();
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

  // Dibujado principal de la pantalla
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
    // Matemática para la barra verde
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Prueba Rápida", style: TextStyle(fontSize: 18)),
        centerTitle: true,
        actions: [
          // --- BARRA DE CORAZONES EN LA ESQUINA SUPERIOR DERECHA ---
          Row(
            // Genera una lista de 3 íconos de corazón usando un ciclo
            children: List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Icon(
                  // Si el número del corazón que está dibujando es menor a mis vidas actuales, lo pinta relleno.
                  // Si no, lo pinta vacío (corazón roto).
                  index < _lives ? Icons.favorite : Icons.favorite_border,
                  color: Colors.redAccent,
                  size: 26,
                ),
              );
            }),
          ),
          const SizedBox(width: 16),
        ],
        // La barra verde de progreso abajo del título
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(value: progress, color: AppTheme.teal),
        ),
      ),
      
      // Usamos Stack para poder encimar cosas (como el muñequito y el confeti sobre las preguntas)
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          
          // --- CAPA 1: EL EXAMEN (AL FONDO) ---
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Contador de "Pregunta 1 / 5"
                        Text(
                          "Pregunta ${_currentIndex + 1} / ${_questions.length}",
                          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        
                        // Cajita blanca de la pregunta principal
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!, width: 2),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Botón de la bocinita
                              IconButton(
                                onPressed: () => _speak(currentQ.question),
                                icon: const Icon(Icons.volume_up_rounded, size: 32, color: AppTheme.teal),
                                tooltip: "Escuchar pregunta",
                              ),
                              const SizedBox(width: 12),
                              // El texto real de la pregunta
                              Expanded(
                                child: Text(
                                  currentQ.question,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Generador mágico de botones de opciones. 
                        // Crea un botón por cada opción que nos haya mandado la base de datos
                        ...List.generate(currentQ.options.length, (index) {
                          return _buildOptionCard(index, currentQ.options[index], currentQ.correctIndex);
                        }),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Cajita de "Correcto/Incorrecto" que aparece ABAJO cuando respondes
                if (_isAnswered && _lives > 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isCorrect ? Colors.green[50] : Colors.red[50], // Fondo pastel
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _isCorrect ? Colors.green : Colors.red), // Borde fuerte
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
                        // Si la IA nos mandó una explicación de por qué es la respuesta correcta, la mostramos
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
                        // Botón gigante para pasar a la siguiente pregunta
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

          // --- CAPA 2: EL MUÑEQUITO GIGANTE (ENCIMA DE TODO) ---
          // IgnorePointer hace que si el usuario le pica al muñeco por error, 
          // el toque traspase y le de al botón que está atrás
          IgnorePointer(
            ignoring: !_showAvatarPopUp,
            child: Container(
              alignment: Alignment.center, 
              margin: const EdgeInsets.only(bottom: 100), 
              // Animación para que aparezca suave y no de golpe
              child: AnimatedOpacity(
                opacity: _showAvatarPopUp ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                // Animación de rebote como si saltara a la pantalla (elasticOut)
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

          // --- CAPA 3: EL CONFETI ---
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive, // Estalla en todas direcciones
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.1, // Cae despacito
          ),
        ],
      ),
    );
  }

  // Función constructora para los botones de las opciones A, B, C, D
  Widget _buildOptionCard(int index, String text, int correctIndex) {
    // Por defecto todos los botones son blancos
    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey[300]!;
    
    // Si el usuario ya contestó, pintamos de colores para darle retroalimentación
    if (_isAnswered) {
      // Pintamos de verde LA RESPUESTA CORRECTA SIEMPRE, para que el usuario aprenda
      if (index == correctIndex) {
        backgroundColor = Colors.green[100]!;
        borderColor = Colors.green;
      // Si tocó ESTE botón en específico, y ESTE botón estaba mal, lo pintamos de rojo
      } else if (index == _selectedOptionIndex && index != correctIndex) {
        backgroundColor = Colors.red[100]!;
        borderColor = Colors.red;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        // Si ya contestaste, apagamos el botón pasando un 'null'
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
              // La bolita que tiene la letra (A, B, C, D)
              CircleAvatar(
                radius: 12,
                backgroundColor: borderColor,
                child: Text(
                  // Un truco de programación para convertir números (0,1,2,3) en letras (A,B,C,D) usando código ASCII
                  String.fromCharCode(65 + index), 
                  style: TextStyle(fontSize: 12, color: _isAnswered ? Colors.white : Colors.grey[600]),
                ),
              ),
              const SizedBox(width: 12),
              // El texto de la respuesta
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