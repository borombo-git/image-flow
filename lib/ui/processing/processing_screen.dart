import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_flow/common/theme/app_theme.dart';

import 'processing_controller.dart';
import 'widgets/scan_line_overlay.dart';

class ProcessingScreen extends GetView<ProcessingController> {
  const ProcessingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Processing', style: kFontH2)),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Image preview with scan animation
            Obx(() => controller.imagePath.value.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(controller.imagePath.value),
                              fit: BoxFit.cover,
                            ),
                            const ScanLineOverlay(),
                          ],
                        ),
                      ),
                    ),
                  )),
            const Spacer(),
            // Progress section
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() => LinearProgressIndicator(
                        value: controller.progress.value,
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      )),
                  const SizedBox(height: 20),
                  Obx(() => Text(
                        controller.currentStep.value,
                        style: kFontH2,
                        textAlign: TextAlign.center,
                      )),
                  const SizedBox(height: 6),
                  Obx(() => Text(
                        controller.stepDescription.value,
                        style: kFontCaption,
                        textAlign: TextAlign.center,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
