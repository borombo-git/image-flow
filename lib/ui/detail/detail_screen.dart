import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../common/theme/app_theme.dart';
import '../../common/utils/logger.dart';
import '../../common/utils/path_utils.dart';
import '../../model/processing_record.dart';
import '../../ui/home/home_controller.dart';
import '../../ui/home/widgets/delete_record_sheet.dart';
import 'widgets/detail_action_bar.dart';
import 'widgets/detail_info_sheet.dart';

const _log = AppLogger('🔍', 'DETAIL');

/// Full-screen detail view for a processing record from history.
class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final record = Get.arguments as ProcessingRecord?;
    if (record == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Get.back());
      return const SizedBox.shrink();
    }
    final resultFile = File(resolveDocPath(record.resultPath));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen result image (fills from top, overlaps behind info sheet)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 80,
            child: Hero(
              tag: 'record_${record.id}',
              child: Image.file(
                resultFile,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Colors.black,
                  child: Icon(
                    Icons.broken_image,
                    color: kColorFontSecondary,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),

          // Top action bar
          Positioned(
            top: 0,
            left: 16,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: DetailActionBar(
                onBack: Get.back,
                onShare: (origin) => _share(record, origin),
                onDelete: () => _delete(context, record),
              ),
            ),
          ),

          // Bottom info sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: DetailInfoSheet(
              record: record,
              onSave: () => _saveToPhotos(resultFile.path),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToPhotos(String path) async {
    try {
      await Gal.requestAccess(toAlbum: true);
      await Gal.putImage(path, album: 'ImageFlow');
      _log.info('Image saved to Photos');
      Get.snackbar(
        'Saved',
        'Image saved to Photos',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: kColorFont,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      _log.error('Save failed', e);
      Get.snackbar(
        'Error',
        'Could not save image to Photos',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade500,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> _share(ProcessingRecord record, Rect shareOrigin) async {
    final metadata = record.metadata ?? {};
    final pdfPath = metadata['pdfPath'] as String?;

    // For documents with a PDF, share the PDF; otherwise share the result image
    final File shareFile;
    if (record.type == ProcessingType.document && pdfPath != null) {
      shareFile = File(resolveDocPath(pdfPath));
      _log.info('Sharing PDF: $pdfPath');
    } else {
      shareFile = File(resolveDocPath(record.resultPath));
      _log.info('Sharing image');
    }

    await Share.shareXFiles(
      [XFile(shareFile.path)],
      sharePositionOrigin: shareOrigin,
    );
  }

  void _delete(BuildContext context, ProcessingRecord record) {
    DeleteRecordSheet.show(
      context,
      onConfirm: () {
        Get.find<HomeController>().deleteRecord(record.id);
        _log.info('Record deleted: ${record.id}');
        Get.back();
      },
    );
  }
}
