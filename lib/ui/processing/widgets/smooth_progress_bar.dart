import 'package:flutter/material.dart';

import '../../../common/theme/app_theme.dart';

/// A [LinearProgressIndicator] that smoothly animates between value changes.
class SmoothProgressBar extends StatefulWidget {
  const SmoothProgressBar({super.key, required this.value});

  final double value;

  @override
  State<SmoothProgressBar> createState() => _SmoothProgressBarState();
}

class _SmoothProgressBarState extends State<SmoothProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _animation = Tween(begin: 0.0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.value > 0) _controller.forward();
  }

  @override
  void didUpdateWidget(SmoothProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween(
        begin: _animation.value,
        end: widget.value,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
      _controller
        ..reset()
        ..forward();
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
      animation: _animation,
      builder: (_, __) => LinearProgressIndicator(
        value: _animation.value,
        borderRadius: BorderRadius.circular(4),
        minHeight: 6,
        backgroundColor: kColorPrimary.withValues(alpha: 0.12),
      ),
    );
  }
}
