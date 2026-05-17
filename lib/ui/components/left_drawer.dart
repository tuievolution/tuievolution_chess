import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../screens/openings_list_screen.dart';

class LeftDrawer extends StatelessWidget {
  const LeftDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.bg(context),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppColors.surface(context)),
            child: const Text('Menü', style: TextStyle(color: AppColors.primary, fontSize: 24)),
          ),
          ListTile(
            leading: Icon(Icons.list, color: AppColors.textSecondary(context)),
            title: const Text('Tüm Açılışlar'),
            onTap: () {
              Navigator.pop(context); // Çekmeceyi kapatır
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OpeningsListScreen()));
            },
          ),
        ],
      ),
    );
  }
}