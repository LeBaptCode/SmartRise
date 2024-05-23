import 'package:flutter/material.dart';

class HypnogramChart extends StatelessWidget {
  final List<int> sleepRecord;

  const HypnogramChart({Key? key, required this.sleepRecord}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Largeur du conteneur basée sur 90% de la largeur de l'écran
    double containerWidth = MediaQuery.of(context).size.width * 0.9;

    // Calculer la largeur totale du graphique en fonction du nombre de points
    double totalWidth = sleepRecord.length * HypnogramPainter.stepWidth;

    // Vérifier si la largeur totale dépasse la largeur du conteneur
    if (totalWidth > containerWidth) {
      // Si la largeur totale dépasse la largeur du conteneur, réduire la largeur totale
      totalWidth = containerWidth;
    }

    return Container(
      padding: const EdgeInsets.all(20.0),
      width: containerWidth, // Définir la largeur du conteneur
      height : MediaQuery.of(context).size.height * 0.28,
      child: AspectRatio(
        aspectRatio: totalWidth / HypnogramPainter.stepHeight,
        child: CustomPaint(
          painter: HypnogramPainter(sleepRecord: sleepRecord),
        ),
      ),
    );
  }
}

class HypnogramPainter extends CustomPainter {
  final List<int> sleepRecord;
  static const double stepWidth = 20.0;
  static const double stepHeight = 40.0;

  const HypnogramPainter({required this.sleepRecord});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    final double startX = 10.0;
    double currentX = startX;
    double currentY = size.height; // Démarrez le dessin depuis le bas du widget

    // Définition des couleurs pour chaque phase de sommeil
    final colorMap = {
      3: Colors.orange.shade600,
      2: Colors.lightBlueAccent,
      1: Colors.blueAccent,
      0: Colors.indigoAccent,
    };

    // Dessiner les lignes représentant les différentes phases de sommeil
    for (int i = 1; i < sleepRecord.length; i++) {
      final color = colorMap[sleepRecord[i - 1]];
      paint.color = color ?? Colors.black;

      final startPoint = Offset(currentX, currentY); // Utilisez la position Y actuelle
      final endPoint = Offset(currentX + stepWidth, currentY - stepHeight * sleepRecord[i]); // Ajustez la position Y

      canvas.drawLine(startPoint, endPoint, paint);

      // Mettre à jour la position X et Y pour le prochain pas
      currentX += stepWidth;
      currentY = endPoint.dy; // Mettez à jour la position Y pour le prochain pas
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // Le graphique ne change pas, donc nous ne redessinons pas à chaque fois
  }
}


