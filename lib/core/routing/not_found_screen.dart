import 'package:flutter/material.dart';
import 'package:reboot_app_3/core/routing/app_routes.dart';
import 'package:reboot_app_3/core/routing/empty_placeholder_widget.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: EmptyPlaceholderWidget(
        message: '404 - Page not found!',
      ),
    );
  }
}
