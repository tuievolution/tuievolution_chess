import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../components/custom_appbar.dart';
import '../components/chessboard_fixed.dart';
import '../components/left_drawer.dart';
import '../components/right_drawer.dart';
import 'tree_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ekran genişliğini ölçüyoruz. 800px'den büyükse masaüstü (yan yana), küçükse mobil (alt alta) sayacağız.
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: const LeftDrawer(),
      endDrawer: const RightDrawer(),
      body: Center(
        child: SingleChildScrollView( // Mobilde aşağı kaydırabilmek için
          padding: const EdgeInsets.all(24.0),
          child: Flex(
            // Ekran genişse ROW (Yan Yana), darsa COLUMN (Alt Alta) yapar!
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. SOL/ÜST KISIM: Satranç Tahtası
              const ChessboardFixed(fen: AppConstants.startingFen),
              
              SizedBox(width: isDesktop ? 40 : 0, height: isDesktop ? 0 : 40), // Ekran tipine göre araya boşluk atar
              
              // 2. SAĞ/ALT KISIM: Açılış Arama ve Liste
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 400 : double.infinity),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TextField(decoration: InputDecoration(hintText: 'Açılış veya Hamle Ara...', prefixIcon: Icon(Icons.search))),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TreeScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.boxColor, border: Border.all(color: AppColors.border, width: 1)),
                        child: const Text('Ruy Lopez (Test Açılışı - İncele)', style: TextStyle(fontSize: 18, color: AppColors.woodBrown)),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}