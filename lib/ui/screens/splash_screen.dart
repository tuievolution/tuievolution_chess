import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'auth_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center( // Her şeyi ekranın tam ortasına yerleştirir
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('GROW OPENINGS', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.boxColor, 
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15) // Butonu büyütür
              ),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen())),
              child: const Text('START', style: TextStyle(color: AppColors.woodBrown, fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}