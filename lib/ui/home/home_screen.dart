import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../common/theme/app_theme.dart';
import 'home_controller.dart';
import 'widgets/history_grid.dart';
import 'widgets/home_empty_state.dart';
import '../capture/capture_bottom_sheet.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: false,
        title: const Text(
          'Image Flow 🪄',
          style: TextStyle(
            fontFamily: kSatoshi,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: kColorFont,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kColorPrimary.withValues(alpha: 0.4),
                  kColorBadgeFace.withValues(alpha: 0.3),
                  kColorBadgeDoc.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: Obx(() => controller.records.isEmpty
          ? const HomeEmptyState()
          : HistoryGrid(controller: controller)),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B82F6), kColorPrimary],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x402563EB),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              if (Get.isBottomSheetOpen ?? false) return;
              HapticFeedback.lightImpact();
              CaptureBottomSheet.show(context);
            },
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
        ),
      ),
    ),
    );
  }
}
