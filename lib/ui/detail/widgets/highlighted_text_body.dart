import 'package:flutter/material.dart';

import '../../../common/theme/app_theme.dart';

const _kActiveHighlight = Color(0xFFFFD54F);
const _kPassiveHighlight = Color(0xFFFFF9C4);

/// Scrollable text body with highlighted search matches.
class HighlightedTextBody extends StatelessWidget {
  const HighlightedTextBody({
    super.key,
    required this.text,
    required this.scrollController,
    this.query = '',
    this.matchPositions = const [],
    this.currentMatchIndex = 0,
  });

  final String text;
  final ScrollController scrollController;
  final String query;
  final List<int> matchPositions;
  final int currentMatchIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: SingleChildScrollView(
          controller: scrollController,
          child: SizedBox(
            width: double.infinity,
            child: Text.rich(
              _buildSpans(),
              style: kFontBody.copyWith(height: 1.6),
            ),
          ),
        ),
      ),
    );
  }

  TextSpan _buildSpans() {
    if (query.isEmpty || matchPositions.isEmpty) {
      return TextSpan(text: text);
    }

    final spans = <TextSpan>[];
    int prev = 0;

    for (int i = 0; i < matchPositions.length; i++) {
      final matchStart = matchPositions[i];
      final matchEnd = matchStart + query.length;

      if (matchStart > prev) {
        spans.add(TextSpan(text: text.substring(prev, matchStart)));
      }

      final isActive = i == currentMatchIndex;
      spans.add(TextSpan(
        text: text.substring(matchStart, matchEnd),
        style: TextStyle(
          backgroundColor: isActive ? _kActiveHighlight : _kPassiveHighlight,
          fontWeight: isActive ? FontWeight.w700 : null,
        ),
      ));

      prev = matchEnd;
    }

    if (prev < text.length) {
      spans.add(TextSpan(text: text.substring(prev)));
    }

    return TextSpan(children: spans);
  }
}
