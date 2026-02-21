import 'package:flutter/material.dart';

import '../../../common/theme/app_theme.dart';

/// Search input with match counter and prev/next navigation.
class TextSearchBar extends StatelessWidget {
  const TextSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.query,
    required this.matchCount,
    required this.currentMatchIndex,
    required this.onPrevious,
    required this.onNext,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String query;
  final int matchCount;
  final int currentMatchIndex;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: kFontBody.copyWith(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: kFontCaption.copyWith(fontSize: 13),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: kColorFontSecondary,
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 36),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          if (query.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              matchCount == 0
                  ? '0/0'
                  : '${currentMatchIndex + 1}/$matchCount',
              style: kFontCaption.copyWith(fontSize: 11),
            ),
            const SizedBox(width: 4),
            _navButton(Icons.keyboard_arrow_up, onPrevious),
            _navButton(Icons.keyboard_arrow_down, onNext),
          ],
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, size: 20, color: kColorFontSecondary),
      ),
    );
  }
}
