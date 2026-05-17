import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../screens/auth_screen.dart';

class RightDrawer extends StatelessWidget {
  const RightDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.bg(context),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: AppColors.surface(context)),
            accountName: const Text("Oyuncu 1", style: TextStyle(color: AppColors.primary)),
            accountEmail: const Text("oyuncu@growopenings.com", style: TextStyle(color: AppColors.primary)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.primary, 
              child: Icon(Icons.person, color: AppColors.bg(context))
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Çıkış Yap'),
            onTap: () {
              // Uygulamayı tamamen sıfırlayıp Login ekranına atar
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthScreen()), (route) => false);
            },
          ),
        ],
      ),
    );
  }
}