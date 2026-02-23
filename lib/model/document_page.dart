/// In-memory representation of one processed document page before final save.
class DocumentPage {
  final String enhancedImagePath;
  final String originalImagePath;
  final String extractedText;
  final int textBlockCount;
  final int cropWidth;
  final int cropHeight;

  const DocumentPage({
    required this.enhancedImagePath,
    required this.originalImagePath,
    required this.extractedText,
    required this.textBlockCount,
    required this.cropWidth,
    required this.cropHeight,
  });
}
