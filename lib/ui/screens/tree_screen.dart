import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../components/custom_appbar.dart';
import '../components/chessboard_fixed.dart';
import '../../main.dart'; 

class TreeScreen extends StatefulWidget {
  final String openingName;
  const TreeScreen({super.key, required this.openingName});

  @override
  State<TreeScreen> createState() => _TreeScreenState();
}

class _TreeScreenState extends State<TreeScreen> {
  late String initialFen;
  late String currentFen;
  late String rootOpeningName;

  @override
  void initState() {
    super.initState();
    // 1. Fetch the starting point from the backend
    final openingData = dataService.getOpeningDataForUI(widget.openingName);
    initialFen = openingData['fen'];
    currentFen = initialFen;
    rootOpeningName = openingData['name'];
  }

  @override
  Widget build(BuildContext context) {
    // 2. Fetch the dynamic list of next moves based on CURRENT board position
    final List<Map<String, dynamic>> nextMoves = dataService.getNextMovesForUI(currentFen);

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
                  ChessboardFixed(
                    fen: initialFen, // Give the board the starting position
                    onPositionChanged: (newFen) {
                      // 3. When the user navigates the board, update our current FEN and rebuild!
                      setState(() {
                        currentFen = newFen;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    decoration: BoxDecoration(color: AppColors.boxColor, border: Border.all(color: AppColors.border, width: 2)),
                    child: Text(rootOpeningName, style: const TextStyle(fontSize: 20, color: AppColors.woodBrown, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              
              SizedBox(width: isDesktop ? 60 : 0, height: isDesktop ? 0 : 40),
              
              // 2. SAĞ/ALT KISIM: Dinamik Olası Hamleler Listesi
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 400 : 500), 
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppColors.background, border: Border.all(color: AppColors.border, width: 2)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sıradaki Olası Hamleler:', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.woodBrown)
                      ),
                      const Divider(color: AppColors.border, thickness: 2, height: 30),
                      
                      if (nextMoves.isEmpty)
                        const Text("Bu varyantın sonuna ulaştınız veya bilinmeyen bir hamle yaptınız.", style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textDark)),

                      // Sadece bir sonraki hamleleri listele
                      ...nextMoves.map((moveData) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded( 
                              child: Text(
                                '- ${moveData["name"]}', 
                                style: TextStyle(
                                  fontSize: 16,
                                  color: moveData["isCompleted"] ? AppColors.activeGreen : AppColors.woodBrown, 
                                  fontWeight: moveData["isCompleted"] ? FontWeight.bold : FontWeight.normal
                                )
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (moveData["isCompleted"]) const Icon(Icons.eco, color: AppColors.activeGreen, size: 20)
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