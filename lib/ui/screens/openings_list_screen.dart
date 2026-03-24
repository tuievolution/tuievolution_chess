import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../components/custom_appbar.dart';
import 'tree_screen.dart';
import '../../main.dart'; // Backend dataService'e erişmek için

class OpeningsListScreen extends StatefulWidget {
  const OpeningsListScreen({super.key});

  @override
  State<OpeningsListScreen> createState() => _OpeningsListScreenState();
}

class _OpeningsListScreenState extends State<OpeningsListScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Backend'den tüm verileri al ve arama kutusuna göre anlık olarak filtrele
    final allOpenings = dataService.allAvailableOpenings;
    final filteredOpenings = allOpenings
        .where((opening) => opening.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // ÇALIŞAN ARAMA KUTUSU
                TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: const InputDecoration(
                    hintText: 'Tüm Açılışlarda Ara...', 
                    prefixIcon: Icon(Icons.search)
                  )
                ),
                const SizedBox(height: 20),
                
                // SONUÇ SAYISI
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${filteredOpenings.length} açılış bulundu', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: ListView.builder(
                    itemCount: filteredOpenings.length,
                    itemBuilder: (context, index) {
                      return _buildOpeningBox(context, filteredOpenings[index]);
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
      // Seçilen açılışı doğrudan TreeScreen'e gönder
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TreeScreen(openingName: title))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.boxColor, 
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8) // Biraz modernlik katar
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18, color: AppColors.woodBrown, fontWeight: FontWeight.bold))),
            const Icon(Icons.menu_book, color: AppColors.woodBrown), // Görsel zenginlik
          ],
        ),
      ),
    );
  }
}