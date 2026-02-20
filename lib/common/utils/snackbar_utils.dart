import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_theme.dart';

/// Shows a styled success snackbar with a checkmark icon.
void showSuccessSnackbar(String title, String message) {
  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: kColorFont,
    colorText: Colors.white,
    icon: const Padding(
      padding: EdgeInsets.only(left: 12),
      child: Icon(Icons.check_circle, color: kColorSuccess, size: 24),
    ),
    borderRadius: 14,
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 2),
    titleText: Text(
      title,
      style: const TextStyle(
        fontFamily: kSatoshi,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        fontSize: kSizeBody,
      ),
    ),
    messageText: Text(
      message,
      style: TextStyle(
        fontFamily: kSatoshi,
        color: Colors.white.withValues(alpha: 0.8),
        fontSize: kSizeCaption,
      ),
    ),
  );
}

/// Shows a styled error snackbar with a warning icon.
void showErrorSnackbar(String title, String message) {
  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: kColorDanger,
    colorText: Colors.white,
    icon: const Padding(
      padding: EdgeInsets.only(left: 12),
      child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
    ),
    borderRadius: 14,
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 3),
    titleText: Text(
      title,
      style: const TextStyle(
        fontFamily: kSatoshi,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        fontSize: kSizeBody,
      ),
    ),
    messageText: Text(
      message,
      style: TextStyle(
        fontFamily: kSatoshi,
        color: Colors.white.withValues(alpha: 0.85),
        fontSize: kSizeCaption,
      ),
    ),
  );
}
