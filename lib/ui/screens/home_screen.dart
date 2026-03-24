import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../components/custom_appbar.dart';
import '../components/chessboard_fixed.dart';
import '../components/left_drawer.dart';
import '../components/right_drawer.dart';
import 'tree_screen.dart';
import 'openings_list_screen.dart';
import '../../main.dart'; // Backend dataService'e erişmek için

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    // 1. Backend'den tüm açılışları al ve arama kutusuna göre filtrele
    final allOpenings = dataService.allAvailableOpenings;
    final filteredOpenings = allOpenings
        .where((opening) => opening.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    // Ana ekranda çok yer kaplamaması için sadece ilk 4 sonucu gösterelim
    final topOpenings = filteredOpenings.take(4).toList();

    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: const LeftDrawer(),
      endDrawer: const RightDrawer(),
      body: Center(
        child: SingleChildScrollView( 
          padding: const EdgeInsets.all(24.0),
          child: Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. SOL/ÜST KISIM: Satranç Tahtası
              const ChessboardFixed(fen: AppConstants.startingFen),
              
              SizedBox(width: isDesktop ? 40 : 0, height: isDesktop ? 0 : 40),
              
              // 2. SAĞ/ALT KISIM: Canlı Arama ve Dinamik Liste
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 400 : double.infinity),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CANLI ARAMA KUTUSU
                    TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: const InputDecoration(
                        hintText: 'Açılış Ara (Örn: Ruy Lopez)...', 
                        prefixIcon: Icon(Icons.search)
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    const Text('Popüler Açılışlar:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.woodBrown)),
                    const SizedBox(height: 10),

                    if (topOpenings.isEmpty)
                      const Text('Eşleşen açılış bulunamadı.', style: TextStyle(color: AppColors.textDark, fontStyle: FontStyle.italic)),

                    // GERÇEK VERİLERLE LİSTE OLUŞTURMA
                    ...topOpenings.map((openingName) => InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TreeScreen(openingName: openingName))),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.boxColor, border: Border.all(color: AppColors.border, width: 1)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(openingName, style: const TextStyle(fontSize: 16, color: AppColors.woodBrown, fontWeight: FontWeight.bold))),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.woodBrown),
                          ],
                        ),
                      ),
                    )),

                    const SizedBox(height: 10),
                    
                    // TÜMÜNÜ GÖR BUTONU
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        side: const BorderSide(color: AppColors.woodBrown, width: 2)
                      ),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OpeningsListScreen())),
                      child: const Text('Tüm Açılışları Gör', style: TextStyle(color: AppColors.woodBrown, fontSize: 16, fontWeight: FontWeight.bold)),
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