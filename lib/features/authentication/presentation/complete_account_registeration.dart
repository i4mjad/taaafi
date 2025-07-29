import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/authentication/presentation/registration_stepper_screen.dart';

/// Complete Account Registration Screen
///
/// This screen has been simplified to use the new step-by-step registration process
/// which provides a much clearer and less confusing user experience.
class CompleteAccountRegisterationScreen extends ConsumerWidget {
  const CompleteAccountRegisterationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the new stepper-based registration flow for better UX
    return const RegistrationStepperScreen();
  }
}
