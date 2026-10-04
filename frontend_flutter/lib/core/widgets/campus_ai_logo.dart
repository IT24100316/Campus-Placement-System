import 'package:flutter/material.dart';

class CampusAILogo extends StatelessWidget {
  final double size;
  final Color color;

  const CampusAILogo({
    super.key,
    this.size = 20.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CampusAILogoPainter(color: color),
    );
  }
}

class _CampusAILogoPainter extends CustomPainter {
  final Color color;

  _CampusAILogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    final path1 = Path()
      ..moveTo(12, 2)
      ..lineTo(2, 7)
      ..lineTo(12, 12)
      ..lineTo(22, 7)
      ..close();

    final path2 = Path()
      ..moveTo(2, 12)
      ..lineTo(12, 17)
      ..lineTo(22, 12);

    final path3 = Path()
      ..moveTo(2, 17)
      ..lineTo(12, 22)
      ..lineTo(22, 17);

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
