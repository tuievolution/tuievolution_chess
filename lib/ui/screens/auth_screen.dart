import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'home_screen.dart';
import '../../main.dart'; // REQUIRED: To access the global supabaseService

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // 1. Create the controllers to capture the user's input
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // 2. Clean up the controllers when the screen is closed to prevent memory leaks
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // 3. Helper method to handle the Sign In / Sign Up logic
  Future<void> _handleAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen email ve şifre giriniz.")),
      );
      return;
    }

    try {
      // Attempt to sign in (or sign up if you map this to the signUp method later)
      await supabaseService.signIn(email, password);
      
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Giriş Hatası: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
              child: SingleChildScrollView( 
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Login / Sign Up', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.woodBrown)),
                    const SizedBox(height: 20),
                    
                    // Google Login Butonu (Şimdilik boş)
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
                    
                    // 4. ATTACH CONTROLLERS TO TEXT FIELDS
                    TextField(
                      controller: emailController, // Email brain attached
                      decoration: const InputDecoration(hintText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passwordController, // Password brain attached
                      decoration: const InputDecoration(hintText: 'Password'), 
                      obscureText: true, // Hides the password with dots
                    ),
                    
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
                    
                    // 5. TRIGGER THE AUTH FUNCTION
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      onPressed: _handleAuth, // Calls the function we built above
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