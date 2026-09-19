import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2457D6);
  static const dark = Color(0xFF172033);
  static const text = Color(0xFF202938);
  static const secondaryText = Color(0xFF697386);
  static const background = Color(0xFFF6F7FB);
  static const border = Color(0xFFE4E7EC);
  static const green = Color(0xFF147D48);
  static const orange = Color(0xFFA85C00);
  static const red = Color(0xFFD92D20);
  static const lightBlue = Color(0xFFEAF0FF);
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
        gradient: const LinearGradient(
          colors: [Color(0xFF172B65), Color(0xFF2457D6)],
        ),
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
        padding: EdgeInsets.all(size * 0.13),
        child: const CustomPaint(painter: FlatverifyLogoPainter()),
      ),
    );
  }
}

class FlatverifyLogoPainter extends CustomPainter {
  const FlatverifyLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint white = Paint()..color = Colors.white;
    final Paint navy = Paint()..color = AppColors.dark;
    final Paint line = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .075
      ..strokeCap = StrokeCap.round;

    final Path roof = Path()
      ..moveTo(size.width * .08, size.height * .55)
      ..lineTo(size.width * .50, size.height * .15)
      ..lineTo(size.width * .92, size.height * .55)
      ..lineTo(size.width * .78, size.height * .55)
      ..lineTo(size.width * .50, size.height * .30)
      ..lineTo(size.width * .22, size.height * .55)
      ..close();
    canvas.drawPath(roof, white);

    final Path checkHouse = Path()
      ..moveTo(size.width * .22, size.height * .56)
      ..lineTo(size.width * .43, size.height * .76)
      ..lineTo(size.width * .82, size.height * .43)
      ..lineTo(size.width * .82, size.height * .78)
      ..lineTo(size.width * .50, size.height * .92)
      ..lineTo(size.width * .18, size.height * .76)
      ..close();
    canvas.drawPath(checkHouse, navy);

    canvas.drawLine(
      Offset(size.width * .43, size.height * .75),
      Offset(size.width * .80, size.height * .44),
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
        FLogo(size: compact ? 42 : 50),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Flatverify.ai',
                style: TextStyle(
                  fontSize: compact ? 20 : 25,
                  fontWeight: FontWeight.w900,
                  color: AppColors.dark,
                ),
              ),
              Text(
                'Understand Your Property',
                style: TextStyle(
                  fontSize: compact ? 11 : 12.5,
                  color: AppColors.secondaryText,
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
