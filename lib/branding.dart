import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2563EB);
  static const dark = Color(0xFF0F172A);
  static const text = Color(0xFF1E293B);
  static const secondaryText = Color(0xFF64748B);
  static const background = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const green = Color(0xFF059669);
  static const orange = Color(0xFFD97706);
  static const red = Color(0xFFEF4444);
  static const lightBlue = Color(0xFFEFF6FF);
}

// ============================================================
// BRANDING
// ============================================================

class FLogo extends StatelessWidget {
  final double size;

  const FLogo({super.key, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1D4ED8),
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.08),
        child: const CustomPaint(painter: FlatverifyLogoPainter()),
      ),
    );
  }
}

class FlatverifyLogoPainter extends CustomPainter {
  const FlatverifyLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64, size.height / 64);
    final line = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(12, 29)
        ..lineTo(32, 12)
        ..lineTo(52, 29)
        ..moveTo(19, 25)
        ..lineTo(19, 49)
        ..lineTo(45, 49)
        ..lineTo(45, 25),
      line,
    );
    final shield = Path()
      ..moveTo(32, 26)
      ..lineTo(44, 31)
      ..lineTo(44, 39)
      ..quadraticBezierTo(44, 47, 32, 54)
      ..quadraticBezierTo(20, 47, 20, 39)
      ..lineTo(20, 31)
      ..close();
    canvas.drawPath(shield, Paint()..color = const Color(0xFF2563EB));
    canvas.drawPath(shield, line);
    canvas.drawPath(
      Path()
        ..moveTo(26, 39)
        ..lineTo(30, 43)
        ..lineTo(38, 34),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BrandHeader extends StatelessWidget {
  final bool compact;

  const BrandHeader({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FLogo(size: compact ? 36 : 50),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Flatverify.ai',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: compact ? 18 : 25,
                    fontWeight: FontWeight.w900,
                    color: AppColors.dark,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Understand your property',
                  style: TextStyle(
                    fontSize: compact ? 10 : 12.5,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// MAIN NAVIGATION
// ============================================================
