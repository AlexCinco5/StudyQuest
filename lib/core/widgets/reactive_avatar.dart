// Importamos las herramientas basicas visuales de Flutter.
import 'package:flutter/material.dart';

// Importamos el paquete de Rive. Rive es una herramienta increible para animaciones
// interactivas vectoriales (como las que usa Duolingo para sus personajes).
import 'package:rive/rive.dart';

// Un "enum" (enumeracion) es como una lista cerrada de opciones permitidas.
// Aqui definimos los 4 estados de animo unicos que nuestro avatar puede tener.
// Esto evita que alguien escriba mal "succes" o "felis" y rompa el programa.
enum AvatarReaction { idle, success, fail, celebrate }

// Esta clase es el "Widget" (componente visual) de nuestro avatar.
// Como su animacion va a cambiar mientras el usuario interactua, necesita ser un "StatefulWidget".
class ReactiveAvatar extends StatefulWidget {
  // Propiedades que necesitamos saber antes de dibujar al avatar:
  final AvatarReaction reaction; // Que emocion debe mostrar ahorita
  final double size;             // De que tamaño queremos dibujarlo (por defecto 150)
  final String assetPath;        // En que carpeta esta guardado el archivo de animacion (.riv)

  // Constructor que pide obligatoriamente la reaccion, pero deja el tamaño
  // y la ruta como opciones por defecto si no se especifican.
  const ReactiveAvatar({
    super.key,
    required this.reaction,
    this.size = 150,
    this.assetPath = 'assets/rive/avatar.riv',
  });

  @override
  State<ReactiveAvatar> createState() => _ReactiveAvatarState();
}

class _ReactiveAvatarState extends State<ReactiveAvatar> {
  // --- LOS CABLES DE CONTROL DE LA ANIMACION ---
  // Imagina que la animacion de Rive es un titere. 
  // Estas variables son los "hilos" o botones que jalaremos para que el titere se mueva.
  // SMI significa "State Machine Input" (Entrada de la maquina de estados de Rive).
  
  // SMIBool: Es un interruptor (Prendido/Apagado). 
  // SMITrigger: Es un boton de un solo toque (como un gatillo, se presiona y se suelta solo).
  SMIBool? _isChecking;   // Interruptor para que el avatar voltee a ver si lo hiciste bien.
  SMITrigger? _trigSuccess; // Boton de "Acierto" (sonrie o asiente).
  SMITrigger? _trigFail;    // Boton de "Fallo" (cara triste o niega con la cabeza).
  SMIBool? _isHandsUp;      // Interruptor para que levante las manos festejando.

  // Esta funcion es llamada AUTOMATICAMENTE en el instante en que el archivo .riv 
  // termina de cargar en la memoria del telefono.
  void _onRiveInit(Artboard artboard) {
    StateMachineController? controller;
    
    // Buscamos la "Maquina de Estados" (el cerebro de la animacion) dentro del archivo.
    if (artboard.stateMachines.isNotEmpty) {
      // Tomamos el control de la primera maquina de estados que encontremos.
      controller = StateMachineController.fromArtboard(
        artboard, 
        artboard.stateMachines.first.name
      );
    }

    // Si logramos tomar el control...
    if (controller != null) {
      artboard.addController(controller);

      // Enlazamos nuestras variables (nuestros hilos) con los nombres exactos 
      // que el diseñador le puso a los botones dentro del programa de Rive.
      _isChecking = controller.findSMI('isChecking');
      _trigSuccess = controller.findSMI('trigSuccess');
      _trigFail = controller.findSMI('trigFail');
      _isHandsUp = controller.findSMI('isHandsUp');
    }
  }

  // Esta funcion especial es como un "radar de cambios". 
  // Se ejecuta automaticamente cada vez que la pantalla padre le pasa un nuevo estado 
  // (por ejemplo, cuando pasas de 'idle' a 'success' al contestar bien).
  @override
  void didUpdateWidget(covariant ReactiveAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si la nueva reaccion es diferente a la vieja, activamos la animacion.
    if (widget.reaction != oldWidget.reaction) {
      _triggerReaction();
    }
  }

  // Esta es la funcion encargada de apretar los botones correctos del titere.
  void _triggerReaction() {
    // 1. Apagamos los interruptores continuos para "resetear" al personaje 
    // y asegurarnos de que no se quede trabado con las manos arriba, por ejemplo.
    _isHandsUp?.value = false;
    _isChecking?.value = false;

    // 2. Revisamos que reaccion nos pidieron y presionamos el boton correspondiente.
    switch (widget.reaction) {
      case AvatarReaction.idle:
        // 'idle' significa estar quieto esperando. Al apagar los botones arriba, 
        // el personaje ya volvio a su estado normal de respiracion, no hay que hacer mas.
        break;
        
      case AvatarReaction.success:
        // Usamos .fire() para apretar y soltar el gatillo de exito.
        _trigSuccess?.fire(); 
        break;
        
      case AvatarReaction.fail:
        // Usamos .fire() para apretar y soltar el gatillo de tristeza.
        _trigFail?.fire();    
        break;
        
      case AvatarReaction.celebrate:
        // Usamos .value = true porque queremos que mantenga los brazos arriba
        // hasta que nosotros le digamos lo contrario (como en el final del nivel).
        _isHandsUp?.value = true; 
        break;
    }
  }

  // Aqui finalmente dibujamos el componente en la pantalla.
  @override
  Widget build(BuildContext context) {
    // Lo encerramos en una "Caja" (SizedBox) para controlar su ancho y alto exacto.
    return SizedBox(
      width: widget.size,
      height: widget.size,
      // Le pasamos el archivo de Rive y le decimos que se ajuste (contain) sin deformarse.
      child: RiveAnimation.asset(
        widget.assetPath,
        fit: BoxFit.contain,
        onInit: _onRiveInit, // Cuando termines de cargar la imagen, ejecuta nuestra conexion.
      ),
    );
  }
}