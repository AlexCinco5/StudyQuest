// Importacion de un paquete externo llamado Equatable.
// Este paquete nos ayuda a comparar objetos en Dart de forma sencilla. 
// Sin esto, Dart pensaria que dos errores iguales son distintos solo por estar en diferente lugar de la memoria.
import 'package:equatable/equatable.dart';

// Definicion de la clase base principal para manejar todos los errores en la aplicacion.
// Es "abstracta" (abstract class) porque nunca vamos a crear un error generico llamado "Failure", 
// sino que la usaremos como molde para crear errores mas especificos despues.
// Al extender de Equatable, le damos a esta clase la capacidad de compararse facilmente.
abstract class Failure extends Equatable {
  
  // Esta variable guardara el mensaje de texto del error, por ejemplo "No hay conexion a internet".
  // La palabra "final" significa que una vez que se le asigne un texto, este no podra cambiar.
  final String message;
  
  // Este es el constructor. Es la funcion que se ejecuta al momento de crear un nuevo error.
  // Pide obligatoriamente el mensaje de texto y lo guarda en la variable de arriba.
  const Failure(this.message);

  // Esta funcion viene del paquete Equatable.
  // Sirve para decirle al programa: "Si dos errores tienen exactamente el mismo mensaje de texto, 
  // consideralos el mismo error". Es vital para que la logica de la aplicacion no se confunda.
  @override
  List<Object> get props => [message];
}

// Creacion de un error especifico basado en nuestro molde principal.
// Al decir "extends Failure", este error hereda todo lo que definimos arriba (el mensaje y la comparacion).
// Usaremos "ServerFailure" cuando algo salga mal al intentar conectarnos a internet o a la base de datos (Supabase).
class ServerFailure extends Failure {
  
  // El constructor simplemente toma el mensaje y se lo pasa a la clase padre (Failure) usando "super".
  const ServerFailure(super.message);
}

// Otro tipo de error especifico, tambien basado en el molde principal.
// Usaremos "CacheFailure" cuando algo salga mal al intentar leer o guardar informacion 
// en la memoria interna del telefono (por ejemplo, si falla al guardar datos localmente).
class CacheFailure extends Failure {
  
  const CacheFailure(super.message);
}