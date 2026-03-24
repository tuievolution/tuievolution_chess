import 'package:flutter/material.dart';
import '../../core/theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Center(
        child: Text('GROW OPENINGS', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      actions: [
        // Sağ köşedeki profil ikonu (Tıklanınca sağ çekmeceyi açar)
        IconButton(
          icon: const Icon(Icons.account_circle, size: 32, color: AppColors.woodBrown),
          onPressed: () => Scaffold.of(context).openEndDrawer(),
        )
      ],
    );
  }

  // AppBar'ın standart yüksekliğini belirliyoruz
  @override
  Size get preferredSize => const Size.fromHeight(60);
}