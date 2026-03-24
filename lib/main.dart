import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'ui/screens/splash_screen.dart';

void main() {
  runApp(const GrowOpeningsApp());
}

class GrowOpeningsApp extends StatelessWidget {
  const GrowOpeningsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GROW OPENINGS',
      debugShowCheckedModeBanner: false,
      theme: growOpeningTheme(),
      home: const SplashScreen(),
    );
  }
}