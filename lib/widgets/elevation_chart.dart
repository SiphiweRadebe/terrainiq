import 'package:flutter/material.dart';

class ElevationChart extends StatelessWidget {
  final List<double> elevations;
  final double maxElevation;
  final double minElevation;

  const ElevationChart({
    Key? key,
    required this.elevations,
    required this.maxElevation,
    required this.minElevation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (elevations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: const Text(
          'No elevation data',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final elevRange = maxElevation - minElevation;
    final chartHeight = 120.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '📈 Elevation Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${(maxElevation - minElevation).toStringAsFixed(0)}m gain',
                style: TextStyle(
                  color: Colors.green[300],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: chartHeight,
            child: CustomPaint(
              painter: ElevationChartPainter(
                elevations: elevations,
                minElevation: minElevation,
                maxElevation: maxElevation,
              ),
              size: Size(double.infinity, chartHeight),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min: ${minElevation.toStringAsFixed(0)}m',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                'Max: ${maxElevation.toStringAsFixed(0)}m',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ElevationChartPainter extends CustomPainter {
  final List<double> elevations;
  final double minElevation;
  final double maxElevation;

  ElevationChartPainter({
    required this.elevations,
    required this.minElevation,
    required this.maxElevation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (elevations.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue[400]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final elevRange = maxElevation - minElevation;
    if (elevRange == 0) return;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < elevations.length; i++) {
      final x = (i / (elevations.length - 1)) * size.width;
      final normalizedElev = (elevations[i] - minElevation) / elevRange;
      final y = size.height - (normalizedElev * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Complete the fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw fill
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    canvas.drawPath(path, paint);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final y = (i / 3) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(ElevationChartPainter oldDelegate) {
    return oldDelegate.elevations != elevations;
  }
}
