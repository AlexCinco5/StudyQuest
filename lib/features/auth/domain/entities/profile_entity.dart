// Definicion de la entidad ProfileEntity.
// En arquitectura limpia, una entidad es la representacion mas pura de un objeto de negocio.
// Contiene solo datos, no sabe nada de bases de datos, internet o interfaces de usuario.
class ProfileEntity {
  
  // Identificador unico del perfil, extraido de la base de datos o de la sesion.
  // Es obligatorio, por lo que no puede ser nulo.
  final String id;
  
  // Nombre de usuario elegido por la persona.
  // El simbolo "?" significa que puede ser nulo, ya que a veces el usuario puede no haberlo definido.
  final String? username;
  
  // Direccion URL o ruta donde se encuentra almacenada la foto de perfil.
  // Tambien puede ser nulo si el usuario no ha subido ninguna imagen.
  final String? avatarUrl;
  
  // Cantidad total de experiencia (puntos) que ha acumulado el usuario.
  // Al ser un numero fundamental para la gamificacion, no puede ser nulo.
  final int totalXp;
  
  // Numero de dias consecutivos que el usuario ha ingresado a estudiar.
  // Al igual que la experiencia, es un valor obligatorio para el calculo de progreso.
  final int currentStreak;

  // Constructor principal de la entidad.
  // "required" obliga a quien cree este objeto a proporcionar el "id", "totalXp" y "currentStreak".
  // "username" y "avatarUrl" son opcionales y pueden pasarse como null.
  ProfileEntity({
    required this.id,
    this.username,
    this.avatarUrl,
    required this.totalXp,
    required this.currentStreak,
  });

  // Constructor tipo Factory.
  // Su proposito es tomar un diccionario de datos (Map<String, dynamic>), comunmente conocido como JSON,
  // y extraer cada pieza de informacion para armar y devolver un objeto ProfileEntity completo.
  factory ProfileEntity.fromMap(Map<String, dynamic> map) {
    return ProfileEntity(
      // Se fuerza a interpretar el valor de la clave 'id' como un String.
      id: map['id'] as String,
      
      // Se intenta leer el 'username'. Si no existe, se asigna null silenciosamente.
      username: map['username'] as String?,
      
      // Se intenta leer el 'avatar_url'. Si no existe, se asigna null.
      avatarUrl: map['avatar_url'] as String?,
      
      // Se lee el valor de 'total_xp'. Si el campo no existe en el diccionario o llega como null,
      // el operador "?? 0" entra en accion y le asigna el valor cero por defecto para evitar errores matematicos.
      totalXp: map['total_xp'] as int? ?? 0,
      
      // Se lee el valor de 'current_streak'. Si el campo no existe o es null,
      // se protege la aplicacion asignando el valor cero por defecto.
      currentStreak: map['current_streak'] as int? ?? 0,
    );
  }
}