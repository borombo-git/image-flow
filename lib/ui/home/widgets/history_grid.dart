import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../model/processing_record.dart';
import '../../../routes/app_routes.dart';
import '../home_controller.dart';
import 'delete_record_sheet.dart';
import 'history_card.dart';

/// 2-column grid of history cards with long-press delete.
class HistoryGrid extends StatefulWidget {
  const HistoryGrid({super.key, required this.controller});

  final HomeController controller;

  @override
  State<HistoryGrid> createState() => _HistoryGridState();
}

class _HistoryGridState extends State<HistoryGrid> {
  bool _navigating = false;
  final _appearedIds = <String>{};

  HomeController get controller => widget.controller;

  Future<void> _onTap(ProcessingRecord record) async {
    if (_navigating) return;
    _navigating = true;
    await Get.toNamed(AppRoutes.detail, arguments: record);
    _navigating = false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 3 / 4,
        ),
        itemCount: controller.records.length,
        itemBuilder: (context, index) {
          final record = controller.records[index];
          final isDeleting = controller.deletingId.value == record.id;
          final alreadySeen = _appearedIds.contains(record.id);
          if (!alreadySeen) _appearedIds.add(record.id);

          // Stagger delay: 60ms per card, max 360ms
          final delay = alreadySeen
              ? Duration.zero
              : Duration(milliseconds: (index * 60).clamp(0, 360));

          Widget card = HistoryCard(
            key: ValueKey(record.id),
            record: record,
            onTap: () => _onTap(record),
            onLongPress: () {
              HapticFeedback.mediumImpact();
              DeleteRecordSheet.show(
                context,
                onConfirm: () => controller.deleteRecord(record.id),
              );
            },
          );

          // Delete exit animation
          card = AnimatedScale(
            scale: isDeleting ? 0.85 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: isDeleting ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: card,
            ),
          );

          // Entrance animation (only on first appearance)
          if (!alreadySeen) {
            card = _StaggeredEntrance(delay: delay, child: card);
          }

          return card;
        },
      ),
    );
  }
}

class _StaggeredEntrance extends StatefulWidget {
  const _StaggeredEntrance({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  State<_StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<_StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
