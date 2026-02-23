import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../common/theme/app_theme.dart';
import '../../../../common/utils/logger.dart';
import '../../../../common/utils/path_utils.dart';
import '../../../../common/utils/snackbar_utils.dart';
import '../../../../model/processing_record.dart';
import '../../../home/home_controller.dart';
import '../../../home/widgets/delete_record_sheet.dart';
import 'detail_action_bar.dart';
import 'detail_info_sheet.dart';

const _log = AppLogger('🔍', 'FACE_DETAIL');

/// Full-screen detail view for face processing records.
class FaceDetailView extends StatelessWidget {
  const FaceDetailView({super.key, required this.record});

  final ProcessingRecord record;

  @override
  Widget build(BuildContext context) {
    final resultFile = File(resolveDocPath(record.resultPath));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Full-screen result image
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
                  onShare: (origin) => _share(origin),
                  onDelete: () => _delete(context),
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
      ),
    );
  }

  Future<void> _saveToPhotos(String path) async {
    try {
      await Gal.requestAccess(toAlbum: true);
      await Gal.putImage(path, album: 'ImageFlow');
      HapticFeedback.mediumImpact();
      _log.info('Image saved to Photos');
      showSuccessSnackbar('Saved', 'Image saved to Photos');
    } catch (e) {
      _log.error('Save failed', e);
      showErrorSnackbar('Error', 'Could not save image to Photos');
    }
  }

  Future<void> _share(Rect shareOrigin) async {
    _log.info('Sharing image');
    await Share.shareXFiles([
      XFile(resolveDocPath(record.resultPath)),
    ], sharePositionOrigin: shareOrigin);
  }

  void _delete(BuildContext context) {
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
