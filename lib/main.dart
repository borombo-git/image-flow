import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'model/processing_record.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(ProcessingTypeAdapter());
  Hive.registerAdapter(ProcessingRecordAdapter());

  runApp(const App());
}
