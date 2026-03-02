import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

enum AvatarReaction { idle, success, fail, celebrate }

class ReactiveAvatar extends StatefulWidget {
  final AvatarReaction reaction;
  final double size;
  final String assetPath;

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
  // Estos son los "Inputs" de tu máquina de estados
  SMIBool? _isChecking;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMIBool? _isHandsUp;

  void _onRiveInit(Artboard artboard) {
    StateMachineController? controller;
    
    // Buscamos automáticamente la primera máquina de estados que tenga el archivo
    if (artboard.stateMachines.isNotEmpty) {
      controller = StateMachineController.fromArtboard(
        artboard, 
        artboard.stateMachines.first.name
      );
    }

    if (controller != null) {
      artboard.addController(controller);

      // Conectamos tus nombres exactos con los controladores
      _isChecking = controller.findSMI('isChecking');
      _trigSuccess = controller.findSMI('trigSuccess');
      _trigFail = controller.findSMI('trigFail');
      _isHandsUp = controller.findSMI('isHandsUp');
    }
  }

  @override
  void didUpdateWidget(covariant ReactiveAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reaction != oldWidget.reaction) {
      _triggerReaction();
    }
  }

  void _triggerReaction() {
    // 1. Apagamos los estados continuos (Booleanos)
    _isHandsUp?.value = false;
    _isChecking?.value = false;

    // 2. Activamos la reacción correspondiente
    switch (widget.reaction) {
      case AvatarReaction.idle:
        // En este avatar en particular, al no hacer nada, vuelve a su estado normal.
        // Si quieres que parezca que "presta atención" mientras respondes, 
        // podrías descomentar la siguiente línea:
        // _isChecking?.value = true; 
        break;
      case AvatarReaction.success:
        _trigSuccess?.fire(); // Los "trig" usan .fire()
        break;
      case AvatarReaction.fail:
        _trigFail?.fire();    // Los "trig" usan .fire()
        break;
      case AvatarReaction.celebrate:
        _isHandsUp?.value = true; // Los "is" usan .value = true
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RiveAnimation.asset(
        widget.assetPath,
        fit: BoxFit.contain,
        onInit: _onRiveInit,
      ),
    );
  }
}