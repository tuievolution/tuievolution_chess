import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../components/custom_appbar.dart';
import 'tree_screen.dart';
import '../../main.dart'; // Import this to access dataService!

class OpeningsListScreen extends StatelessWidget {
  const OpeningsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Fetch the dynamic list from your backend service
    final openings = dataService.allAvailableOpenings;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const TextField(decoration: InputDecoration(hintText: 'Açılış Ara...', prefixIcon: Icon(Icons.search))),
                const SizedBox(height: 20),
                Expanded(
                  // 2. Use ListView.builder for dynamic, scalable lists instead of hardcoding
                  child: ListView.builder(
                    itemCount: openings.length,
                    itemBuilder: (context, index) {
                      return _buildOpeningBox(context, openings[index]);
                    },
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
      // 3. Pass the title to the TreeScreen so it knows what to load
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TreeScreen(openingName: title))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.boxColor, border: Border.all(color: AppColors.border)),
        child: Text(title, style: const TextStyle(fontSize: 18, color: AppColors.woodBrown, fontWeight: FontWeight.bold)),
      ),
    );
  }
}