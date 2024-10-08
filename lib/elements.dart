import 'main.dart';
import 'package:flutter/material.dart';

class SpeechBubbleLeft extends StatelessWidget {
  final String message;

  const SpeechBubbleLeft({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      // Added Material widget
      color: Colors.transparent, // Make sure the background remains transparent
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main bubble
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Triangle (pointer)
          Positioned(
            left: -10,
            top: 15,
            child: CustomPaint(
              painter: TrianglePainterLeft(),
            ),
          ),
        ],
      ),
    );
  }
}

class SpeechBubbleRight extends StatelessWidget {
  final String message;

  const SpeechBubbleRight({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      // Added Material widget
      color: Colors.transparent, // Make sure the background remains transparent
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main bubble
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Triangle (pointer)
          Positioned(
            right: 0,
            top: 15,
            child: CustomPaint(
              painter: TrianglePainterRight(),
            ),
          ),
        ],
      ),
    );
  }
}

class TrianglePainterLeft extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    var path = Path();
    // Start from the right point of the triangle
    path.moveTo(10, 0); // Start at the top-right corner
    // Draw a line to the left point
    path.lineTo(0, 5); // This is the tip of the triangle pointing left
    // Draw a line to the bottom-right corner
    path.lineTo(10, 10);
    // Close the path to form the triangle
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class TrianglePainterRight extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    var path = Path();
    // Start from the left point of the triangle
    path.moveTo(0, 0); // Start at the top-left corner
    // Draw a line to the right point
    path.lineTo(10, 5); // This is the tip of the triangle pointing right
    // Draw a line to the bottom-left corner
    path.lineTo(0, 10); // Bottom-left corner
    // Close the path to form the triangle
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
