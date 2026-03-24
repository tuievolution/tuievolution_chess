import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../components/custom_appbar.dart';
import '../components/chessboard_fixed.dart';
import '../../main.dart'; // Import this to access dataService!

class TreeScreen extends StatelessWidget {
  // 1. Require the openingName in the constructor
  final String openingName;
  const TreeScreen({super.key, required this.openingName});

  @override
  Widget build(BuildContext context) {
    // 2. Fetch the real data from the JSON tree instead of MockData
    final opening = dataService.getOpeningDataForUI(openingName);
    final variants = opening['variants'] as List;

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Center(
        child: SingleChildScrollView( 
          padding: const EdgeInsets.all(24.0),
          child: Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. SOL/ÜST KISIM: Tahta ve Başlık
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChessboardFixed(fen: opening['fen']),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    decoration: BoxDecoration(color: AppColors.boxColor, border: Border.all(color: AppColors.border, width: 2)),
                    child: Text(opening['name'], style: const TextStyle(fontSize: 20, color: AppColors.woodBrown, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              
              SizedBox(width: isDesktop ? 60 : 0, height: isDesktop ? 0 : 40),
              
              // 2. SAĞ/ALT KISIM: Varyantlar Listesi
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 400 : 500), 
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppColors.background, border: Border.all(color: AppColors.border, width: 2)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Seçilen Açılışın Varyantları:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.woodBrown)),
                      const Divider(color: AppColors.border, thickness: 2, height: 30),
                      
                      // Varyantları döngüyle listeleme
                      ...variants.map((v) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded( 
                              child: Text(
                                '${v["id"]}. ${v["name"]}', 
                                style: TextStyle(
                                  fontSize: 16,
                                  color: v["isCompleted"] ? AppColors.activeGreen : AppColors.woodBrown, 
                                  fontWeight: v["isCompleted"] ? FontWeight.bold : FontWeight.normal
                                )
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (v["isCompleted"]) const Icon(Icons.eco, color: AppColors.activeGreen, size: 20)
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}