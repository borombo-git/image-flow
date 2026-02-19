import 'package:flutter/material.dart';

/// Top overlay action bar with back, share, and delete buttons.
class DetailActionBar extends StatelessWidget {
  const DetailActionBar({
    super.key,
    required this.onBack,
    required this.onShare,
    required this.onDelete,
  });

  final VoidCallback onBack;
  final void Function(Rect shareOrigin) onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _circleButton(Icons.arrow_back, Colors.white, onBack),
        const Spacer(),
        _shareButton(),
        const SizedBox(width: 12),
        _circleButton(Icons.delete_outline, Colors.red.shade400, onDelete),
      ],
    );
  }

  /// Share button that computes its own screen rect for the share sheet origin.
  Widget _shareButton() {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          final box = context.findRenderObject() as RenderBox;
          final origin = box.localToGlobal(Offset.zero) & box.size;
          onShare(origin);
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}
