import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/theme/app_theme.dart';
import '../../../../common/utils/path_utils.dart';
import '../../document_collector_controller.dart';

/// Horizontal thumbnail strip with reorder, select, and remove.
class PageThumbnailStrip extends GetView<DocumentCollectorController> {
  const PageThumbnailStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 98,
      child: Obx(() {
        final pageCount = controller.pages.length;
        final selected = controller.selectedIndex.value;

        return ReorderableListView.builder(
          scrollDirection: Axis.horizontal,
          buildDefaultDragHandles: false,
          proxyDecorator: (child, _, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (_, child) => Material(
                color: Colors.transparent,
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                child: child,
              ),
              child: child,
            );
          },
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: pageCount,
          onReorder: controller.reorderPages,
          itemBuilder: (context, index) {
            final page = controller.pages[index];
            final isSelected = index == selected;

            return ReorderableDragStartListener(
              key: ValueKey(page.enhancedImagePath),
              index: index,
              child: GestureDetector(
                onTap: () => controller.selectPage(index),
                child: Padding(
                  padding: EdgeInsets.only(
                    // Top/right padding so the delete badge isn't clipped
                    top: pageCount > 1 ? 8 : 0,
                    right: index < pageCount - 1 ? 10 : 0,
                  ),
                  child: SizedBox(
                    width: 64,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Card with border
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? kColorPrimary
                                  : Colors.grey.shade300,
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Thumbnail image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(resolveDocPath(page.enhancedImagePath)),
                                  width: 64,
                                  height: 88,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.shade100,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      size: 20,
                                      color: kColorFontSecondary,
                                    ),
                                  ),
                                ),
                              ),

                              // Page number badge
                              Positioned(
                                bottom: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontFamily: kSatoshi,
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Remove button — positioned on the outer Stack so it
                        // overflows the card border cleanly
                        if (pageCount > 1)
                          Positioned(
                            top: -6,
                            right: -6,
                            child: GestureDetector(
                              onTap: () => controller.removePage(index),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: kColorDanger,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
