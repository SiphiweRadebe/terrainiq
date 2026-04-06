import 'package:flutter/material.dart';

class RouteWarning {
  final String type; // 'steep_climb', 'steep_descent', 'moderate_climb'
  final double position; // percentage along route (0-100)
  final double gradient;
  final String message;

  RouteWarning({
    required this.type,
    required this.position,
    required this.gradient,
    required this.message,
  });
}

class WarningsPanel extends StatelessWidget {
  final List<RouteWarning> warnings;

  const WarningsPanel({
    Key? key,
    required this.warnings,
  }) : super(key: key);

  static List<RouteWarning> generateWarnings(List<double> gradients, double totalDistance) {
    final warnings = <RouteWarning>[];
    if (gradients.isEmpty) return warnings;

    final segmentDistance = totalDistance / gradients.length;

    for (int i = 0; i < gradients.length; i++) {
      final gradient = gradients[i];
      final position = (i / gradients.length) * 100;

      if (gradient >= 10) {
        // Steep gradient
        final distanceAhead = ((gradients.length - i) * segmentDistance / 1000).toStringAsFixed(1);
        warnings.add(RouteWarning(
          type: 'steep_section',
          position: position,
          gradient: gradient,
          message: '🔴 Steep section ($distanceAhead km ahead, ${gradient.toStringAsFixed(1)}%)',
        ));
      } else if (gradient >= 6) {
        // Moderate gradient
        final distanceAhead = ((gradients.length - i) * segmentDistance / 1000).toStringAsFixed(1);
        warnings.add(RouteWarning(
          type: 'moderate_section',
          position: position,
          gradient: gradient,
          message: '🟡 Moderate slope ($distanceAhead km ahead, ${gradient.toStringAsFixed(1)}%)',
        ));
      }
    }

    return warnings;
  }

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[700]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Route looks good - no steep sections',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚠️ Route Warnings',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...warnings.take(3).map((w) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              w.message,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          )).toList(),
          if (warnings.length > 3)
            Text(
              '+${warnings.length - 3} more warnings',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
        ],
      ),
    );
  }
}
