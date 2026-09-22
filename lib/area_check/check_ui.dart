import 'package:flutter/material.dart';
import 'dart:math' as math;

class CheckPalette {
  static const ink = Color(0xFF14233D);
  static const muted = Color(0xFF68758B);
  static const canvas = Color(0xFFF5F7FB);
  static const blue = Color(0xFF2563EB);
  static const teal = Color(0xFF0B8279);
  static const line = Color(0xFFE7ECF3);
}

class CheckSurface extends StatelessWidget {
  const CheckSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = Colors.white,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: CheckPalette.line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x040F172A),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

class CheckSectionTitle extends StatelessWidget {
  const CheckSectionTitle(this.title, {super.key, this.caption, this.trailing});
  final String title;
  final String? caption;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: CheckPalette.ink,
                  letterSpacing: -.4,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 5),
                Text(
                  caption!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CheckPalette.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class CheckBadge extends StatelessWidget {
  const CheckBadge(
    this.text, {
    super.key,
    this.icon,
    this.color = CheckPalette.teal,
    this.dark = false,
  });
  final String text;
  final IconData? icon;
  final Color color;
  final bool dark;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: dark
          ? Colors.white.withValues(alpha: .1)
          : color.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: dark ? const Color(0xFFAFD6FF) : color),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: dark ? const Color(0xFFDCEBFF) : color,
            ),
          ),
        ),
      ],
    ),
  );
}

class CheckIcon extends StatelessWidget {
  const CheckIcon(
    this.icon, {
    super.key,
    this.color = CheckPalette.blue,
    this.size = 46,
  });
  final IconData icon;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, size: size * .48, color: color),
  );
}

class CheckHint extends StatelessWidget {
  const CheckHint(
    this.text, {
    super.key,
    this.icon = Icons.info_outline_rounded,
    this.warning = false,
  });
  final String text;
  final IconData icon;
  final bool warning;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFF8EA) : const Color(0xFFEEF4FC),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: warning ? const Color(0xFF9A640E) : CheckPalette.blue,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: warning
                  ? const Color(0xFF805512)
                  : const Color(0xFF4E6483),
            ),
          ),
        ),
      ],
    ),
  );
}

class CheckEmptyState extends StatelessWidget {
  const CheckEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => CheckSurface(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          CheckIcon(icon, size: 68),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: CheckPalette.muted, height: 1.6),
          ),
        ],
      ),
    ),
  );
}

class CheckActionTile extends StatelessWidget {
  const CheckActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = CheckPalette.blue,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final Color color;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: CheckPalette.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CheckIcon(icon, color: color),
                const Spacer(),
                const Icon(
                  Icons.north_east_rounded,
                  size: 18,
                  color: CheckPalette.muted,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: CheckPalette.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class CheckActionGrid extends StatelessWidget {
  const CheckActionGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 700 ? 4 : 2;
      return Column(
        children: [
          for (int row = 0; row < children.length; row += columns)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int col = 0; col < columns; col++) ...[
                      if (col > 0) const SizedBox(width: 12),
                      Expanded(
                        child: row + col < children.length
                            ? children[row + col]
                            : const SizedBox(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

class CheckProgress extends StatelessWidget {
  const CheckProgress({super.key, required this.step});
  final int step;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        4,
        (index) => Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == 0
                          ? Colors.transparent
                          : index <= step
                          ? CheckPalette.blue
                          : CheckPalette.line,
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: index <= step ? CheckPalette.blue : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: index <= step
                            ? CheckPalette.blue
                            : CheckPalette.line,
                      ),
                    ),
                    child: index < step
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: index == step
                                  ? Colors.white
                                  : CheckPalette.muted,
                            ),
                          ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == 3
                          ? Colors.transparent
                          : index < step
                          ? CheckPalette.blue
                          : CheckPalette.line,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ['Property', 'Spaces', 'Compare', 'Results'][index],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: index == step ? FontWeight.w800 : FontWeight.w500,
                  color: index == step ? CheckPalette.blue : CheckPalette.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class CheckHero extends StatelessWidget {
  const CheckHero({super.key, required this.onStart, required this.onHelp});
  final VoidCallback onStart, onHelp;
  Widget startButton() => FilledButton(
    onPressed: onStart,
    style: FilledButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF173865),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: Text('Start Area Check', textAlign: TextAlign.center)),
        SizedBox(width: 12),
        Icon(Icons.arrow_forward_rounded, size: 19),
      ],
    ),
  );
  Widget helpButton() => TextButton(
    onPressed: onHelp,
    style: TextButton.styleFrom(foregroundColor: const Color(0xFFCDDFF8)),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.play_circle_outline, size: 17),
        SizedBox(width: 7),
        Flexible(child: Text('View How It Works', textAlign: TextAlign.center)),
      ],
    ),
  );
  List<Widget> get introduction => const [
    CheckBadge(
      'YOUR HOME. YOUR NUMBERS.',
      dark: true,
      icon: Icons.auto_awesome_outlined,
    ),
    SizedBox(height: 20),
    Text(
      'Know your space.\nOwn your decision.',
      style: TextStyle(
        fontSize: 28,
        letterSpacing: -1,
        height: 1.18,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    ),
    SizedBox(height: 12),
    Text(
      'Turn your room measurements into a clear picture of your home.',
      style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFFC0CEE2)),
    ),
  ];
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 24),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFF12294C),
      borderRadius: BorderRadius.circular(26),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 620) {
          return Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...introduction,
                    const SizedBox(height: 24),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: SizedBox(
                        width: double.infinity,
                        child: startButton(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    helpButton(),
                  ],
                ),
              ),
              const SizedBox(width: 28),
              const Expanded(
                flex: 4,
                child: SizedBox(
                  height: 230,
                  child: CustomPaint(painter: FloorPlanArtwork()),
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...introduction,
            const SizedBox(height: 20),
            const SizedBox(
              height: 112,
              width: double.infinity,
              child: CustomPaint(painter: FloorPlanArtwork()),
            ),
            const SizedBox(height: 22),
            SizedBox(width: double.infinity, child: startButton()),
            const SizedBox(height: 6),
            Center(child: helpButton()),
          ],
        );
      },
    ),
  );
}

/// A schematic illustration only; it never depicts measured user values.
class FloorPlanArtwork extends CustomPainter {
  const FloorPlanArtwork({this.light = false});
  final bool light;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 310, size.height / 158);
    canvas.save();
    canvas.translate(
      (size.width - 310 * scale) / 2,
      (size.height - 158 * scale) / 2,
    );
    canvas.scale(scale);
    final grid = Paint()
      ..color = (light ? CheckPalette.blue : Colors.white).withValues(
        alpha: .055,
      )
      ..strokeWidth = .6;
    for (double x = 0; x <= 310; x += 15) {
      canvas.drawLine(Offset(x, 0), Offset(x, 158), grid);
    }
    for (double y = 0; y <= 158; y += 15) {
      canvas.drawLine(Offset(0, y), Offset(310, y), grid);
    }
    final stroke = Paint()
      ..color = light ? const Color(0xFF739ACD) : const Color(0xFF9BBCED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rooms = [
      const Rect.fromLTWH(48, 16, 103, 71),
      const Rect.fromLTWH(158, 16, 102, 44),
      const Rect.fromLTWH(158, 67, 102, 70),
      const Rect.fromLTWH(48, 94, 103, 43),
    ];
    for (int i = 0; i < rooms.length; i++) {
      final rect = RRect.fromRectAndRadius(rooms[i], const Radius.circular(3));
      canvas.drawRRect(
        rect,
        Paint()
          ..color = (i == 2 ? const Color(0xFF5AD6C1) : const Color(0xFF7EAFFA))
              .withValues(alpha: .13),
      );
      canvas.drawRRect(rect, stroke);
    }
    canvas.drawRect(
      const Rect.fromLTWH(61, 30, 31, 40),
      stroke..strokeWidth = 1,
    );
    canvas.drawLine(const Offset(61, 39), const Offset(92, 39), stroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(174, 84, 65, 17),
        const Radius.circular(4),
      ),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(192, 111, 27, 12),
        const Radius.circular(4),
      ),
      stroke,
    );
    canvas.drawRect(const Rect.fromLTWH(174, 28, 70, 10), stroke);
    final accent = Paint()
      ..color = const Color(0xFF6DE0CA)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(48, 150), const Offset(260, 150), accent);
    for (final x in [48.0, 260.0]) {
      canvas.drawLine(Offset(x, 146), Offset(x, 154), accent);
    }
    canvas.drawCircle(
      const Offset(264, 20),
      13,
      Paint()..color = const Color(0xFF43C5AD),
    );
    canvas.drawPath(
      Path()
        ..moveTo(258, 20)
        ..lineTo(262, 24)
        ..lineTo(270, 16),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(FloorPlanArtwork oldDelegate) =>
      oldDelegate.light != light;
}
