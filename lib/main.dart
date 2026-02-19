import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'common/utils/path_utils.dart';
import 'model/processing_record.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow caching more decoded images (default ~100 MB may evict on grid rebuild)
  PaintingBinding.instance.imageCache.maximumSizeBytes = 200 << 20;

  await Hive.initFlutter();
  await initDocsDir();

  Hive.registerAdapter(ProcessingTypeAdapter());
  Hive.registerAdapter(ProcessingRecordAdapter());

  runApp(const App());
}
