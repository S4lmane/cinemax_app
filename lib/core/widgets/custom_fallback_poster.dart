import 'package:flutter/material.dart';

class CustomFallbackPoster extends StatelessWidget {
  final String title;
  final bool isMovie;
  final double width;
  final double height;
  final double borderRadius;

  const CustomFallbackPoster({
    super.key,
    required this.title,
    required this.isMovie,
    this.width = 200,
    this.height = 300,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isMovie
                ? [Colors.blue.shade800, Colors.purple.shade900]
                : [Colors.purple.shade700, Colors.pink.shade900],
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: Opacity(
                opacity: 0.2,
                child: CustomPaint(
                  painter: GridPainter(),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Icon(
                    isMovie ? Icons.movie : Icons.tv,
                    color: Colors.white.withOpacity(0.8),
                    size: width * 0.3,
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: width * 0.08,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Content type
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isMovie ? 'Movie' : 'TV Show',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.06,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // No poster text
                  Text(
                    'No Poster Available',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: width * 0.05,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines
    double spacing = size.height / 12;
    for (int i = 0; i <= 12; i++) {
      double y = i * spacing;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw vertical lines
    spacing = size.width / 8;
    for (int i = 0; i <= 8; i++) {
      double x = i * spacing;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Extension for easy checking if a MovieModel has a poster
extension PosterChecker on String {
  bool hasPoster() {
    return isNotEmpty && this != 'null';
  }
}