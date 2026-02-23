import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Payload for the document edge detection isolate.
class EdgeDetectionPayload {
  final Uint8List bytes;

  /// Seed region from text block union: [x, y, w, h].
  /// Used as starting point for luminance-based edge detection.
  final List<int> seedBounds;

  const EdgeDetectionPayload(this.bytes, this.seedBounds);
}

/// Result from the isolate: enhanced JPEG bytes + detected document bounds.
class EdgeDetectionResult {
  final Uint8List jpegBytes;
  final int cropWidth;
  final int cropHeight;

  const EdgeDetectionResult(this.jpegBytes, this.cropWidth, this.cropHeight);
}

/// Top-level function for [Isolate.run].
///
/// Pipeline: decode pre-normalized image → luminance edge detection (using seed
/// bounds from text blocks) → crop to paper edges → contrast enhancement → JPEG.
/// Bytes are already EXIF-corrected by the orchestrator, so no bakeOrientation needed.
EdgeDetectionResult detectAndCrop(EdgeDetectionPayload payload) {
  final image = img.decodeImage(payload.bytes);
  if (image == null) throw Exception('Failed to decode image');

  // --- Edge detection: find paper boundaries via luminance scanning ---
  final seed = payload.seedBounds;
  final seedX = seed[0].clamp(0, image.width - 1);
  final seedY = seed[1].clamp(0, image.height - 1);
  final seedW = min(seed[2], image.width - seedX);
  final seedH = min(seed[3], image.height - seedY);

  // Sample the paper luminance from the center of the text area
  final paperLum = _sampleLuminance(
    image,
    seedX + seedW ~/ 2,
    seedY + seedH ~/ 2,
    min(seedW, seedH) ~/ 6,
  );

  // Threshold: paper edge is where luminance drops below 60% of paper brightness.
  // This accounts for shadows and slight color variations.
  final threshold = (paperLum * 0.60).round();

  // Scan outward from seed bounds to find actual paper edges
  final top = _scanUp(image, seedY, seedX, seedX + seedW, threshold);
  final bottom = _scanDown(
    image, seedY + seedH, seedX, seedX + seedW, threshold,
  );
  final left = _scanLeft(image, seedX, seedY, seedY + seedH, threshold);
  final right = _scanRight(
    image, seedX + seedW, seedY, seedY + seedH, threshold,
  );

  // Small fixed margin (8px) to avoid cutting right at the edge
  const margin = 8;
  final cropX = max(0, left - margin);
  final cropY = max(0, top - margin);
  final cropW = min(image.width - cropX, right - left + margin * 2);
  final cropH = min(image.height - cropY, bottom - top + margin * 2);

  final cropped = (cropW > 0 && cropH > 0)
      ? img.copyCrop(image, x: cropX, y: cropY, width: cropW, height: cropH)
      : image;

  // Enhance for readability
  final enhanced = img.adjustColor(
    cropped,
    contrast: 1.4,
    saturation: 0.4,
    brightness: 1.05,
  );

  return EdgeDetectionResult(
    img.encodeJpg(enhanced, quality: 92),
    cropped.width,
    cropped.height,
  );
}

// ---------------------------------------------------------------------------
// Luminance helpers (run inside isolate)
// ---------------------------------------------------------------------------

/// Samples average luminance in a square region around (cx, cy).
int _sampleLuminance(img.Image image, int cx, int cy, int radius) {
  int sum = 0;
  int count = 0;
  final r = max(radius, 4);

  for (int y = max(0, cy - r); y < min(image.height, cy + r); y++) {
    for (int x = max(0, cx - r); x < min(image.width, cx + r); x++) {
      sum += image.getPixel(x, y).luminance.round();
      count++;
    }
  }

  return count > 0 ? sum ~/ count : 128;
}

/// Average luminance of a horizontal row between [xStart] and [xEnd].
int _rowLuminance(img.Image image, int y, int xStart, int xEnd) {
  if (y < 0 || y >= image.height) return 0;
  final x0 = max(0, xStart);
  final x1 = min(image.width, xEnd);
  if (x1 <= x0) return 0;

  int sum = 0;
  // Sample every 4th pixel for speed on large images
  int count = 0;
  for (int x = x0; x < x1; x += 4) {
    sum += image.getPixel(x, y).luminance.round();
    count++;
  }
  return count > 0 ? sum ~/ count : 0;
}

/// Average luminance of a vertical column between [yStart] and [yEnd].
int _colLuminance(img.Image image, int x, int yStart, int yEnd) {
  if (x < 0 || x >= image.width) return 0;
  final y0 = max(0, yStart);
  final y1 = min(image.height, yEnd);
  if (y1 <= y0) return 0;

  int sum = 0;
  int count = 0;
  for (int y = y0; y < y1; y += 4) {
    sum += image.getPixel(x, y).luminance.round();
    count++;
  }
  return count > 0 ? sum ~/ count : 0;
}

/// Scans upward from [startY] until row luminance drops below [threshold].
int _scanUp(img.Image image, int startY, int xStart, int xEnd, int threshold) {
  for (int y = startY; y >= 0; y--) {
    if (_rowLuminance(image, y, xStart, xEnd) < threshold) return y + 1;
  }
  return 0;
}

/// Scans downward from [startY] until row luminance drops below [threshold].
int _scanDown(
  img.Image image, int startY, int xStart, int xEnd, int threshold,
) {
  for (int y = startY; y < image.height; y++) {
    if (_rowLuminance(image, y, xStart, xEnd) < threshold) return y - 1;
  }
  return image.height - 1;
}

/// Scans left from [startX] until column luminance drops below [threshold].
int _scanLeft(
  img.Image image, int startX, int yStart, int yEnd, int threshold,
) {
  for (int x = startX; x >= 0; x--) {
    if (_colLuminance(image, x, yStart, yEnd) < threshold) return x + 1;
  }
  return 0;
}

/// Scans right from [startX] until column luminance drops below [threshold].
int _scanRight(
  img.Image image, int startX, int yStart, int yEnd, int threshold,
) {
  for (int x = startX; x < image.width; x++) {
    if (_colLuminance(image, x, yStart, yEnd) < threshold) return x - 1;
  }
  return image.width - 1;
}
