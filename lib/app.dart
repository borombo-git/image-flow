import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_binding.dart';
import 'common/theme/app_theme.dart';
import 'routes/app_routes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ImageFlow',
      debugShowCheckedModeBanner: false,
      theme: theme,
      initialRoute: AppRoutes.home,
      getPages: AppRoutes.pages,
      initialBinding: AppBinding(),
    );
  }
}
