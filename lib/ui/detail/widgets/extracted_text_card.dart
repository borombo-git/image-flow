import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/theme/app_theme.dart';
import '../../../common/utils/snackbar_utils.dart';
import 'highlighted_text_body.dart';
import 'text_search_bar.dart';

/// Collapsible card displaying OCR-extracted text with search and copy.
class ExtractedTextCard extends StatefulWidget {
  const ExtractedTextCard({super.key, required this.text});

  final String text;

  @override
  State<ExtractedTextCard> createState() => _ExtractedTextCardState();
}

class _ExtractedTextCardState extends State<ExtractedTextCard> {
  bool _expanded = false;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _query = '';
  int _currentMatchIndex = 0;
  List<int> _matchPositions = [];

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expanded ? _buildExpandedContent() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.text_snippet_outlined, size: 20, color: kColorPrimary),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Extracted Text', style: kFontBodyBold),
            ),
            GestureDetector(
              onTap: _copyText,
              child: const Icon(Icons.copy_outlined, size: 18, color: kColorFontSecondary),
            ),
            const SizedBox(width: 12),
            AnimatedRotation(
              turns: _expanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(
                Icons.keyboard_arrow_down,
                size: 22,
                color: kColorFontSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, color: Colors.grey.shade200),
        TextSearchBar(
          controller: _searchController,
          onChanged: _onQueryChanged,
          query: _query,
          matchCount: _matchPositions.length,
          currentMatchIndex: _currentMatchIndex,
          onPrevious: _previousMatch,
          onNext: _nextMatch,
        ),
        HighlightedTextBody(
          text: widget.text,
          scrollController: _scrollController,
          query: _query,
          matchPositions: _matchPositions,
          currentMatchIndex: _currentMatchIndex,
        ),
      ],
    );
  }

  void _copyText() {
    Clipboard.setData(ClipboardData(text: widget.text));
    HapticFeedback.lightImpact();
    showSuccessSnackbar('Copied', 'Text copied to clipboard');
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value.toLowerCase();
      _matchPositions = _findMatches();
      _currentMatchIndex = _matchPositions.isNotEmpty ? 0 : 0;
    });
    _scrollToMatch();
  }

  List<int> _findMatches() {
    if (_query.isEmpty) return [];
    final lower = widget.text.toLowerCase();
    final matches = <int>[];
    int start = 0;
    while (true) {
      final idx = lower.indexOf(_query, start);
      if (idx == -1) break;
      matches.add(idx);
      start = idx + 1;
    }
    return matches;
  }

  void _nextMatch() {
    if (_matchPositions.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matchPositions.length;
    });
    _scrollToMatch();
  }

  void _previousMatch() {
    if (_matchPositions.isEmpty) return;
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _matchPositions.length) % _matchPositions.length;
    });
    _scrollToMatch();
  }

  void _scrollToMatch() {
    if (_matchPositions.isEmpty || !_scrollController.hasClients) return;
    final pos = _matchPositions[_currentMatchIndex];
    final ratio = pos / widget.text.length;
    final maxScroll = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      (ratio * maxScroll).clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }
}
