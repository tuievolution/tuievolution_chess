import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../components/custom_appbar.dart';
import 'tree_screen.dart';

class OpeningsListScreen extends StatelessWidget {
  const OpeningsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // Liste çok uzamasın diye web'de ortalanır
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const TextField(decoration: InputDecoration(hintText: 'Açılış Ara...', prefixIcon: Icon(Icons.search))),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      _buildOpeningBox(context, 'Ruy Lopez'),
                      _buildOpeningBox(context, 'Queen\'s Gambit'),
                      _buildOpeningBox(context, 'Sicilian Defense'),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpeningBox(BuildContext context, String title) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TreeScreen())),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.boxColor, border: Border.all(color: AppColors.border)),
        child: Text(title, style: const TextStyle(fontSize: 18, color: AppColors.woodBrown, fontWeight: FontWeight.bold)),
      ),
    );
  }
}