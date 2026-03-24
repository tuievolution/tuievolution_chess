import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'home_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // Ekran dar ise (Mobil) kenarlardan boşluk bırakır, geniş ise (Web) max 400px olur.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.boxColor,
                border: Border.all(color: AppColors.border, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView( // Klavye açılınca ekranın taşmasını (overflow) önler
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Login / Sign Up', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.woodBrown)),
                    const SizedBox(height: 20),
                    
                    // Google Login Butonu
                    OutlinedButton.icon(
                      icon: const Icon(Icons.g_mobiledata, size: 32, color: AppColors.woodBrown),
                      label: const Text('Sign in with Google', style: TextStyle(color: AppColors.woodBrown)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        side: const BorderSide(color: AppColors.woodBrown),
                        backgroundColor: Colors.white, 
                      ),
                      onPressed: () {}, 
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('OR', style: TextStyle(color: AppColors.woodBrown, fontWeight: FontWeight.bold)),
                    ),
                    
                    const TextField(decoration: InputDecoration(hintText: 'Email')),
                    const SizedBox(height: 10),
                    const TextField(decoration: InputDecoration(hintText: 'Password'), obscureText: true),
                    
                    // Şifreyi Kaydet ve Unuttum kısmı responsive yapıldı (Wrap kullanıldı)
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(value: false, onChanged: (v){}),
                            const Text('Save Password', style: TextStyle(color: AppColors.woodBrown)),
                          ],
                        ),
                        TextButton(onPressed: (){}, child: const Text('Forgot?', style: TextStyle(color: AppColors.woodBrown))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      onPressed: () {}, 
                      child: const Text('Sign In / Sign Up', style: TextStyle(color: AppColors.woodBrown)),
                    ),
                    const Divider(color: AppColors.border, height: 30),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        side: const BorderSide(color: AppColors.woodBrown)
                      ),
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
                      child: const Text('Continue as Guest', style: TextStyle(color: AppColors.woodBrown)),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}