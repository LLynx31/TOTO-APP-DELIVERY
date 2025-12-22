import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

/// Widget pour afficher une animation de confetti
class CelebrationConfetti extends StatefulWidget {
  final Duration duration;
  final bool autoStart;

  const CelebrationConfetti({
    super.key,
    this.duration = const Duration(seconds: 3),
    this.autoStart = true,
  });

  @override
  State<CelebrationConfetti> createState() => _CelebrationConfettiState();
}

class _CelebrationConfettiState extends State<CelebrationConfetti> {
  late ConfettiController _controllerCenter;
  late ConfettiController _controllerLeft;
  late ConfettiController _controllerRight;

  @override
  void initState() {
    super.initState();

    _controllerCenter = ConfettiController(duration: widget.duration);
    _controllerLeft = ConfettiController(duration: widget.duration);
    _controllerRight = ConfettiController(duration: widget.duration);

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startConfetti();
      });
    }
  }

  void _startConfetti() {
    _controllerCenter.play();
    _controllerLeft.play();
    _controllerRight.play();
  }

  @override
  void dispose() {
    _controllerCenter.dispose();
    _controllerLeft.dispose();
    _controllerRight.dispose();
    super.dispose();
  }

  Path _drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(
        halfWidth + externalRadius * cos(step),
        halfWidth + externalRadius * sin(step),
      );
      path.lineTo(
        halfWidth + internalRadius * cos(step + halfDegreesPerStep),
        halfWidth + internalRadius * sin(step + halfDegreesPerStep),
      );
    }
    path.close();
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti central
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _controllerCenter,
            blastDirection: pi / 2, // Vers le bas
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.1,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
            ],
            createParticlePath: _drawStar,
          ),
        ),
        // Confetti gauche
        Align(
          alignment: Alignment.topLeft,
          child: ConfettiWidget(
            confettiController: _controllerLeft,
            blastDirection: 0, // Vers la droite
            emissionFrequency: 0.05,
            numberOfParticles: 15,
            gravity: 0.1,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
            ],
          ),
        ),
        // Confetti droite
        Align(
          alignment: Alignment.topRight,
          child: ConfettiWidget(
            confettiController: _controllerRight,
            blastDirection: pi, // Vers la gauche
            emissionFrequency: 0.05,
            numberOfParticles: 15,
            gravity: 0.1,
            shouldLoop: false,
            colors: const [
              Colors.purple,
              Colors.yellow,
              Colors.pink,
              Colors.blue,
            ],
          ),
        ),
      ],
    );
  }
}
