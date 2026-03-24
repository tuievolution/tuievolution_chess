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
  // We use this key to talk directly to the chessboard from the list
  final GlobalKey<ChessboardFixedState> _boardKey = GlobalKey<ChessboardFixedState>();
  
  late String initialFen;
  late String currentFen;
  late String originalOpeningName;

  @override
  void initState() {
    super.initState();
    final openingData = dataService.getOpeningDataForUI(widget.openingName);
    initialFen = openingData['fen'];
    currentFen = initialFen;
    originalOpeningName = openingData['name'];
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> nextMoves = dataService.getNextMovesForUI(currentFen);
    
    // Check how deep we are in the game
    int plyCount = _boardKey.currentState?.currentPlyCount ?? 0;
    
    // Find the current official opening name for this specific position
    String? currentPositionName = dataService.getOpeningNameByFen(currentFen);
    
    // SMART TITLE LOGIC: Only show deep variants after 3 full moves (6 plys)
    String displayTitle = originalOpeningName;
    if (plyCount >= 6 && currentPositionName != null) {
      displayTitle = currentPositionName;
    } else if (plyCount > 0) {
      displayTitle = "$originalOpeningName (Gelişim Aşaması)";
    }

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
              
              // 1. SOL KISIM: Varyantlar Listesi (SWAPPED!)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 400 : 500), 
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppColors.background, border: Border.all(color: AppColors.border, width: 2)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // If it's the start, say Openings, otherwise say Next Moves
                        plyCount == 0 ? 'Ana Devam Yolları:' : 'Sıradaki Hamleler:', 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.woodBrown)
                      ),
                      const Divider(color: AppColors.border, thickness: 2, height: 30),
                      
                      if (nextMoves.isEmpty)
                        const Text("Bu varyantın sonuna ulaştınız veya bilinmeyen bir hamle yaptınız.", style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textDark)),

                      // TIKLANABİLİR LİSTE: Tıklanınca tahtayı günceller
                      ...nextMoves.map((moveData) => InkWell(
                        onTap: () {
                          // Tell the chessboard to make this move!
                          _boardKey.currentState?.makeMoveFromExternal(moveData['move'], moveData['fen']);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white54,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(6)
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.woodBrown, borderRadius: BorderRadius.circular(4)),
                                child: Text(moveData['move'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded( 
                                child: Text(
                                  moveData["name"], 
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: moveData["isCompleted"] ? AppColors.activeGreen : AppColors.textDark, 
                                    fontWeight: moveData["isCompleted"] ? FontWeight.bold : FontWeight.w500
                                  )
                                ),
                              ),
                              if (moveData["isCompleted"]) const Icon(Icons.eco, color: AppColors.activeGreen, size: 20)
                            ],
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),

              SizedBox(width: isDesktop ? 60 : 0, height: isDesktop ? 40 : 40),

              // 2. SAĞ KISIM: Tahta ve Başlık (SWAPPED!)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    decoration: BoxDecoration(color: AppColors.boxColor, border: Border.all(color: AppColors.border, width: 2)),
                    child: Text(displayTitle, style: const TextStyle(fontSize: 20, color: AppColors.woodBrown, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                  ChessboardFixed(
                    key: _boardKey, // Attach the key here!
                    fen: initialFen, 
                    onPositionChanged: (newFen) {
                      setState(() {
                        currentFen = newFen;
                      });
                    },
                  ),
                ],
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}