import 'package:flutter/material.dart';
import '../../../common/theme/app_theme.dart';

class ScanLineOverlay extends StatefulWidget {
  const ScanLineOverlay({super.key, this.animate = true});

  final bool animate;

  @override
  State<ScanLineOverlay> createState() => _ScanLineOverlayState();
}

class _ScanLineOverlayState extends State<ScanLineOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(ScanLineOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ScanLinePainter(
            progress: _controller.value,
            color: kColorPrimary,
          ),
        );
      },
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScanLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;

    // Outer glow — wide & faint
    final outerGlow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.08),
          color.withValues(alpha: 0.18),
          color.withValues(alpha: 0.08),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTRB(0, y - 60, size.width, y + 60));

    canvas.drawRect(Rect.fromLTRB(0, y - 60, size.width, y + 60), outerGlow);

    // Inner glow — tighter & brighter
    final innerGlow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.35),
          color.withValues(alpha: 0.5),
          color.withValues(alpha: 0.35),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTRB(0, y - 16, size.width, y + 16));

    canvas.drawRect(Rect.fromLTRB(0, y - 16, size.width, y + 16), innerGlow);

    // Core line — bright with blur
    final corePaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, y), Offset(size.width, y), corePaint);

    // Sharp center line on top for crispness
    final sharpPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, y), Offset(size.width, y), sharpPaint);
  }

  @override
  bool shouldRepaint(_ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
