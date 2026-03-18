// Definicion enumerada de las modalidades operativas disponibles en el motor de juego.
// Facilita el enrutamiento y la instanciacion del tipo correcto de sesion de estudio.
enum LevelType { flashcards, quiz, mixed, exam }

// Representacion de un nodo de progresion o "nivel" dentro de la trayectoria de estudio.
class LevelEntity {
  // Identificador de la etapa.
  final String id;
  
  // Nombre descriptivo de la tematica cubierta en este nivel.
  final String title;
  
  // Clasificacion mecanica del nivel vinculada al enumerador superior.
  final LevelType type;
  
  // Bandera logica para gestionar el control de acceso secuencial.
  // Determina si la UI debe renderizar un candado e impedir la entrada.
  final bool isLocked;
  
  // Bandera logica que rastrea la finalizacion exitosa de los requisitos del nivel.
  final bool isCompleted;
  
  // Metrica numerica escalar (1-5) para determinar la complejidad intrinseca,
  // util futura para algoritmos de calculo de experiencia o matchmaking.
  final int difficulty; 

  // Constructor optimizado para instanciacion en tiempo de compilacion donde sea posible.
  // Inyecta defaults operativos sensatos para evitar inicializaciones repetitivas.
  const LevelEntity({
    required this.id,
    required this.title,
    required this.type,
    this.isLocked = false,
    this.isCompleted = false,
    this.difficulty = 1,
  });
}