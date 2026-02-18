import 'package:get/get.dart';

import '../ui/home/home_binding.dart';
import '../ui/home/home_screen.dart';
import '../ui/processing/processing_binding.dart';
import '../ui/processing/processing_screen.dart';

abstract class AppRoutes {
  static const home = '/home';
  static const processing = '/processing';

  static final pages = [
    GetPage(
      name: home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: processing,
      page: () => const ProcessingScreen(),
      binding: ProcessingBinding(),
    ),
  ];
}
