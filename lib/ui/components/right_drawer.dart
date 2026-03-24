import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../screens/auth_screen.dart';

class RightDrawer extends StatelessWidget {
  const RightDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: AppColors.boxColor),
            accountName: Text("Oyuncu 1", style: TextStyle(color: AppColors.woodBrown)),
            accountEmail: Text("oyuncu@growopenings.com", style: TextStyle(color: AppColors.woodBrown)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.woodBrown, 
              child: Icon(Icons.person, color: Colors.white)
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