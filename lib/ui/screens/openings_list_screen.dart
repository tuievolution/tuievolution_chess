import 'package:flutter/material.dart';
import '../../core/theme.dart';
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
      backgroundColor: AppColors.bg(context),
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
                  style: TextStyle(color: AppColors.textPrimary(context)),
                  decoration: InputDecoration(
                    hintText: 'Tüm Açılışlarda Ara...', 
                    hintStyle: TextStyle(color: AppColors.textSecondary(context)),
                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary(context)),
                    filled: true,
                    fillColor: AppColors.surface(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                  )
                ),
                const SizedBox(height: 20),
                
                // SONUÇ SAYISI
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${filteredOpenings.length} açılış bulundu', style: TextStyle(color: AppColors.textSecondary(context), fontWeight: FontWeight.bold)),
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
          color: AppColors.surface(context), 
          border: Border.all(color: AppColors.border(context)),
          borderRadius: BorderRadius.circular(8) // Biraz modernlik katar
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title, style: TextStyle(fontSize: 18, color: AppColors.textPrimary(context), fontWeight: FontWeight.bold))),
            Icon(Icons.menu_book, color: AppColors.textSecondary(context)), // Görsel zenginlik
          ],
        ),
      ),
    );
  }
}