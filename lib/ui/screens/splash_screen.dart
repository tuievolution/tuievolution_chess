import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../widgets/grow_button.dart';
import 'auth_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border(context), width: 2),
              ),
              child: const Icon(Icons.eco, color: AppColors.primary, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'GROW OPENINGS', 
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
            ),
            const SizedBox(height: 12),
            Text(
              'Nurture your chess mastery.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 64),
            SizedBox(
              width: 200,
              child: GrowButton(
                text: 'START →',
                type: GrowButtonType.primary,
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen())),
              ),
            ),
          ],
        ),
      ),
    );
  }
}