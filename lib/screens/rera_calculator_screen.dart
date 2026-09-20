import 'package:flutter/material.dart';
import 'mobile_main_screen.dart';

/// Legacy alias routing directly into the mobile main screen
class ReraCalculatorScreen extends StatelessWidget {
  const ReraCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MobileMainScreen();
  }
}
