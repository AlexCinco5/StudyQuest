import 'dart:math';
// Usamos collections para poder tener la "Queue" (fila de cartas)
import 'dart:collection';
import 'package:flutter/material.dart';
// Librería para hacer que el teléfono lea los textos en voz alta
import 'package:flutter_tts/flutter_tts.dart'; 
import '../../../../core/theme/app_theme.dart';
// Inyector para llamar a la base de datos sin enredarnos
import '../../../../injection_container.dart' as di;
import '../../domain/entities/flashcard_entity.dart';
import '../../domain/repositories/level_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

// Pantalla principal del modo de estudio con Flashcards.
class FlashcardsPage extends StatefulWidget {
  // Necesitamos saber qué documento y qué tema estamos estudiando
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

// El SingleTickerProviderStateMixin es necesario para que funcionen las animaciones (como girar la tarjeta)
class _FlashcardsPageState extends State<FlashcardsPage> with SingleTickerProviderStateMixin {
  
  // En lugar de una lista normal, usamos una "Queue" (cola/fila). 
  // Esto nos permite sacar la primera carta fácilmente y mandarla al final si nos equivocamos.
  final Queue<FlashcardEntity> _cardsQueue = Queue();
  int _totalInitialCards = 0;
  
  bool _isLoading = true;
  // Bandera para saber si estamos viendo la pregunta o la respuesta
  bool _showBack = false; 
  
  // Controladores para la animación 3D de girar la tarjeta
  late AnimationController _controller;
  late Animation<double> _animation;

  // Creamos el motor de lectura de voz
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
    // Empezamos a descargar las tarjetas desde internet
    _loadCards();
    
    // Configuramos cuánto dura el giro de la tarjeta (600 milisegundos)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // Le decimos que gire de 0 a 180 grados (pi en radianes) con un efecto suave (easeInOut)
    _animation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  // --- CONFIGURACIÓN DEL LECTOR DE VOZ ---
  Future<void> _initTts() async {
    // Lo configuramos en español de México, con velocidad y tono normales
    await _flutterTts.setLanguage("es-MX"); 
    await _flutterTts.setSpeechRate(0.5);   
    await _flutterTts.setVolume(1.0);       
    await _flutterTts.setPitch(1.0);        
  }

  // Función atajo para hacer hablar al teléfono
  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    // Si cerramos la pantalla, apagamos la voz y destruimos las animaciones para ahorrar memoria
    _flutterTts.stop(); 
    _controller.dispose();
    super.dispose();
  }

  // Descarga las tarjetas de Supabase usando el ID del documento y el tema
  Future<void> _loadCards() async {
    try {
      final cards = await di.sl<LevelRepository>().getFlashcards(widget.documentId, widget.topicId);
      setState(() {
        // Metemos todas las tarjetas descargadas a nuestra "fila" de estudio
        _cardsQueue.addAll(cards);
        _totalInitialCards = cards.length;
        _isLoading = false;
      });
    } catch (e) {
      print("Error cargando flashcards: $e");
      setState(() => _isLoading = false);
    }
  }

  // Acción que ocurre cuando tocamos la tarjeta con el dedo
  void _flipCard() {
    // Si ya está girando, no hacemos nada para que no se trabe
    if (_controller.isAnimating) return;
    
    setState(() {
      _showBack = !_showBack;
    });
    
    // Si acabamos de voltearla para ver la respuesta...
    if (_showBack) {
      _controller.forward(); // Hacemos la animación de giro
      // Y automáticamente leemos la respuesta en voz alta
      _speak(_cardsQueue.first.back); 
    } else {
      // Si la regresamos a la pregunta, deshacemos la animación y callamos a la voz
      _controller.reverse();
      _flutterTts.stop(); 
    }
  }

  // --- LÓGICA DE APRENDIZAJE (Estilo Anki) ---

  // Botón verde: Si nos sabíamos la respuesta
  void _markAsLearned() {
    _flutterTts.stop();
    
    // Sacamos la carta de la fila para siempre porque ya la dominamos
    _cardsQueue.removeFirst();
    _moveToNextCard(); // Pasamos a la que sigue
  }

  // Botón rojo: Si nos equivocamos
  void _markForReview() {
    _flutterTts.stop();
    
    // Sacamos la carta actual, pero la volvemos a meter HASTA ATRÁS de la fila
    // para obligar al usuario a repasarla más tarde.
    final currentCard = _cardsQueue.removeFirst();
    _cardsQueue.addLast(currentCard);
    
    _moveToNextCard();
  }

  // Lógica para acomodar la siguiente tarjeta en pantalla
  void _moveToNextCard() {
    // Si la fila ya se vació, ganamos el nivel
    if (_cardsQueue.isEmpty) {
      _showCompletionDialog();
      return;
    }

    // Truco visual: Reseteamos la animación de golpe a 0 grados sin que el usuario lo note
    // para que la siguiente tarjeta aparezca boca arriba (pregunta) lista para jugar
    _controller.value = 0;
    setState(() {
      _showBack = false;
    });
  }

  // Función que muestra el aviso de victoria cuando se vacía la fila
  void _showCompletionDialog() async {
    // Le regalamos 10 puntos de experiencia al usuario por su esfuerzo
    di.sl<AuthRepository>().addXp(10); 
    // Guardamos en internet que este nivel ya fue superado
    await di.sl<LevelRepository>().markLevelCompleted(widget.topicId);

    // Verificamos que la pantalla siga abierta antes de intentar mostrar un popup
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // Obligamos a que presione el botón de volver
      builder: (_) => AlertDialog(
        title: const Text("¡Nivel Completado! 🎉"),
        content: Column(
          mainAxisSize: MainAxisSize.min, // Que el popup mida solo lo necesario
          children: [
            const Text("Has repasado todos los conceptos clave."),
            const SizedBox(height: 16),
            // Mensaje motivacional de la experiencia ganada
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
              Navigator.pop(context); // Cierra el mensaje emergente
              Navigator.pop(context); // Nos regresa al mapa de niveles
            },
            child: const Text("Volver al Mapa"),
          ),
        ],
      ),
    );
  }

  // Construcción visual de la pantalla
  @override
  Widget build(BuildContext context) {
    // Mientras descarga las tarjetas, mostramos un circulo girando
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Si descargó y no había nada, mostramos un aviso en lugar de romper la app
    if (_cardsQueue.isEmpty && _totalInitialCards == 0) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("No hay flashcards disponibles para este tema.")),
      );
    }

    // Matemática simple para la barra verde de arriba: 
    // Vemos cuántas sacamos ya de la fila original para sacar un porcentaje de 0.0 a 1.0
    final int cardsLeft = _cardsQueue.length;
    final int cardsLearned = _totalInitialCards - cardsLeft;
    final double progress = (_totalInitialCards > 0) ? (cardsLearned / _totalInitialCards).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Repaso Rápido"),
        centerTitle: true,
        // Aquí pintamos la barra de progreso
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(value: progress, color: AppTheme.teal),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            // Contador de cartas que faltan por dominar
            Text(
              "Restantes: $cardsLeft",
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: Colors.grey[600]
              ),
            ),
            const SizedBox(height: 40),
            
            // Expanded hace que la tarjeta ocupe todo el espacio disponible en medio de la pantalla
            Expanded(
              // Este widget hace que la tarjeta reaccione al toque del dedo
              child: GestureDetector(
                onTap: _flipCard,
                // AnimatedBuilder redibuja la tarjeta frame por frame mientras gira
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final angle = _animation.value;
                    
                    // Verificamos si la tarjeta ya giró más de 90 grados (mitad del camino)
                    // Si es menos, estamos viendo el frente. Si es más, estamos viendo atrás.
                    final isFront = angle < (pi / 2);

                    // Matemática 3D para evitar que el texto de atrás se lea en espejo (al revés).
                    // Matrix4.identity crea un espacio 3D base.
                    // setEntry(3,2) le da un poco de perspectiva falsa para que se vea profundo al girar.
                    // rotateY es el giro horizontal en sí.
                    final transform = Matrix4.identity()
                      ..setEntry(3, 2, 0.001) 
                      ..rotateY(isFront ? angle : angle - pi);

                    return Transform(
                      alignment: Alignment.center,
                      transform: transform,
                      // Mandamos a dibujar el rectángulo con el texto que toque según de qué lado estamos
                      child: _buildCardFace(
                        text: isFront ? _cardsQueue.first.front : _cardsQueue.first.back,
                        isFront: isFront,
                        color: isFront ? Colors.white : Colors.indigo[50]!, // La parte de atrás es azul bajito
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Los botones rojos y verdes que solo aparecen cuando vemos la respuesta.
            // AnimatedOpacity los aparece suavemente en lugar de soltarlos de golpe.
            AnimatedOpacity(
              opacity: _showBack ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              // IgnorePointer evita que toquemos botones invisibles por accidente
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

  // Función reutilizable que dibuja el rectángulo visual de la tarjeta y le pone el texto adentro.
  Widget _buildCardFace({required String text, required bool isFront, required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        // Sombreado bonito para que parezca que flota
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 2, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Si estamos viendo atrás, ponemos el letrero chiquito de "RESPUESTA" arriba
          if (!isFront) ...[
            Text(
              "RESPUESTA",
              style: TextStyle(color: AppTheme.teal.withOpacity(0.7), letterSpacing: 1.5, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
          
          Expanded(
            child: Center(
              // Si el texto de la IA es larguísimo, esto permite hacerle scroll con el dedo
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(), 
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20, 
                    // La pregunta va en negritas, la respuesta normal
                    fontWeight: isFront ? FontWeight.bold : FontWeight.normal,
                    color: Colors.black87,
                    height: 1.4, 
                  ),
                ),
              ),
            ),
          ),
          
          // Si estamos viendo el frente, ponemos el letrero de "PREGUNTA" abajo
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

  // Función atajo para crear botones circulares iguales (verde o rojo) más rápido.
  Widget _buildActionButton(IconData icon, Color color, String label, VoidCallback onTap) {
    return Column(
      children: [
        FloatingActionButton(
          // HeroTag evita errores técnicos si Flutter confunde dos botones iguales
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