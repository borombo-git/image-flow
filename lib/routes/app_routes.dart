import 'package:get/get.dart';

import '../ui/home/home_binding.dart';
import '../ui/home/home_screen.dart';

abstract class AppRoutes {
  static const home = '/home';

  static final pages = [
    GetPage(
      name: home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
  ];
}
