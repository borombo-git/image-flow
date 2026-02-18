import 'package:flutter/material.dart';

import '../../../common/theme/app_theme.dart';

/// A stat entry to display in the [StatsRow].
typedef StatEntry = ({String label, String value});

/// Renders a row of stat columns inside a rounded bordered container,
/// separated by vertical dividers. Reusable across result screens.
class StatsRow extends StatelessWidget {
  final List<StatEntry> stats;

  const StatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kColorFontSecondary.withValues(alpha: 0.2)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: _buildChildren(),
        ),
      ),
    );
  }

  List<Widget> _buildChildren() {
    final children = <Widget>[];
    for (var i = 0; i < stats.length; i++) {
      if (i > 0) {
        children.add(
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: kColorFontSecondary.withValues(alpha: 0.2),
          ),
        );
      }
      children.add(
        Expanded(
          child: _StatColumn(label: stats[i].label, value: stats[i].value),
        ),
      );
    }
    return children;
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: kFontCaption),
        const SizedBox(height: 4),
        Text(value, style: kFontBodyBold),
      ],
    );
  }
}
