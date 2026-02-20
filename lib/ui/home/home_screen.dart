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
    return Scaffold(
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
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      body: Obx(() => controller.records.isEmpty
          ? const HomeEmptyState()
          : HistoryGrid(controller: controller)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (Get.isBottomSheetOpen ?? false) return;
          HapticFeedback.lightImpact();
          CaptureBottomSheet.show(context);
        },
        backgroundColor: kColorPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }
}
