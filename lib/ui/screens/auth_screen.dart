import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'main_scaffold.dart';
import '../../main.dart'; // REQUIRED: To access the global supabaseService
import '../widgets/grow_button.dart';
import '../widgets/grow_text_field.dart';
import '../widgets/grow_card.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
      await supabaseService.signIn(email, password);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScaffold()));
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
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Placeholder
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: const Icon(Icons.eco, color: AppColors.primary, size: 36),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    'Grow Openings',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nurture your chess mastery from root to result.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 48),
                  
                  // Login Form Card
                  GrowCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GrowTextField(
                          label: 'Username or Email',
                          hintText: 'grandmaster@chess.io',
                          prefixIcon: Icons.alternate_email,
                          controller: emailController,
                        ),
                        const SizedBox(height: 20),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Password',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.primary,
                                  textBaseline: TextBaseline.alphabetic,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          style: TextStyle(color: AppColors.textPrimary(context)),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: TextStyle(color: AppColors.textSecondary(context)),
                            prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondary(context)),
                            filled: true,
                            fillColor: AppColors.bg(context),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.border(context)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        GrowButton(
                          text: 'Login →',
                          onPressed: _handleAuth,
                          type: GrowButtonType.primary,
                        ),
                        
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.border(context))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('OR', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary(context))),
                            ),
                            Expanded(child: Divider(color: AppColors.border(context))),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        GrowButton(
                          text: 'Continue with Nature ID',
                          icon: Icons.park,
                          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScaffold())),
                          type: GrowButtonType.secondary,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('New to the garden? ', style: Theme.of(context).textTheme.bodyMedium),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Plant your account',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.circle, color: AppColors.primary, size: 10),
                      const SizedBox(width: 8),
                      Text('Server Healthy', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(width: 16),
                      Icon(Icons.circle, color: AppColors.textSecondary(context), size: 10),
                      const SizedBox(width: 8),
                      Text('v1.4.0-sprout', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}