import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_flow/common/theme/app_theme.dart';

import 'home_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ImageFlow')),
      body: const Center(child: Text('Hello World', style: kFontBodyMedium)),
    );
  }
}
