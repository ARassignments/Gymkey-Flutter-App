import 'package:flutter/material.dart';

class DashedDivider extends StatelessWidget {
  final Color color;
  final double height;
  final double dashWidth;
  final double dashSpace;

  const DashedDivider({
    super.key,
    this.color = Colors.grey,
    this.height = 2,
    this.dashWidth = 6,
    this.dashSpace = 4,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedLinePainter(
        color: color,
        strokeWidth: height,
        dashWidth: dashWidth,
        dashSpace: dashSpace,
      ),
      size: const Size(double.infinity, 0),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _DashedLinePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;

    double startX = 0;
    final space = dashSpace + dashWidth;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += space;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
