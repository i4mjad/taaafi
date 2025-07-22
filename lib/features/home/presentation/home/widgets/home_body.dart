import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/card_based_hub.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/home_header.dart';

class HomeBody extends ConsumerWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Welcome header with title and subtitle
        HomeHeader(),

        // Scrollable card-based content
        Expanded(
          child: CardBasedHub(),
        ),
      ],
    );
  }
}
