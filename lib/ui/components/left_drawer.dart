import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../screens/openings_list_screen.dart';

class LeftDrawer extends StatelessWidget {
  const LeftDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppColors.boxColor),
            child: Text('Menü', style: TextStyle(color: AppColors.woodBrown, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.list, color: AppColors.textDark),
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