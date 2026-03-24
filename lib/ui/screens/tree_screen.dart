import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart'; // REQUIRED: To get AppConstants.startingFen
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
  final GlobalKey<ChessboardFixedState> _boardKey = GlobalKey<ChessboardFixedState>();
  
  late String initialFen;
  late String currentFen;
  late String originalOpeningName;
  late List<String> initialHistory; // NEW: Holds the path to the opening

  // Stockfish State variables
  String? engineBestMove;
  bool isEngineThinking = false;

  @override
  void initState() {
    super.initState();
    final openingData = dataService.getOpeningDataForUI(widget.openingName);
    
    initialFen = openingData['fen'];
    currentFen = initialFen;
    originalOpeningName = openingData['name'];
    
    // FETCH THE HISTORY PATH FROM THE DATA SERVICE
    initialHistory = List<String>.from(openingData['history'] ?? []);

    // Stockfish cevabını dinle
    stockfishService.onBestMoveFound = (uciMove) {
      if (mounted) {
        setState(() {
          engineBestMove = uciMove;
          isEngineThinking = false;
        });
      }
    };
  }

  void _onBoardPositionChanged(String newFen) {
    setState(() {
      currentFen = newFen;
      engineBestMove = null; // Eski motor analizini temizle
    });

    // 1. JSON Dataset'te bu hamle var mı diye bak
    final nextMoves = dataService.getNextMovesForUI(newFen);
    
    // 2. Yoksa Stockfish'i uyandır!
    if (nextMoves.isEmpty) {
      setState(() {
        isEngineThinking = true;
      });
      stockfishService.calculateBestMove(newFen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> nextMoves = dataService.getNextMovesForUI(currentFen);
    int plyCount = _boardKey.currentState?.currentPlyCount ?? 0;
    String? currentPositionName = dataService.getOpeningNameByFen(currentFen);
    
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
              
              // 1. SOL KISIM: Tahta ve Başlık 
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
                    key: _boardKey, 
                    // FIX: Pass the starting point and the history to replay!
                    startingFen: AppConstants.startingFen, 
                    initialMoves: initialHistory, 
                    onPositionChanged: _onBoardPositionChanged, 
                  ),
                ],
              ),
              
              SizedBox(width: isDesktop ? 60 : 0, height: isDesktop ? 0 : 40),

              // 2. SAĞ KISIM: Olası Hamleler veya Stockfish Analizi
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 400 : 500), 
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppColors.background, border: Border.all(color: AppColors.border, width: 2)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plyCount == 0 ? 'Ana Devam Yolları:' : 'Sıradaki Hamleler:', 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.woodBrown)
                      ),
                      const Divider(color: AppColors.border, thickness: 2, height: 30),
                      
                      // DURUM A: Dataset'te hamleler var
                      if (nextMoves.isNotEmpty)
                        ...nextMoves.map((moveData) => InkWell(
                          onTap: () {
                            _boardKey.currentState?.makeMoveFromExternal(moveData['move'], moveData['fen']);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white54, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(6)),
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
                                    style: TextStyle(fontSize: 16, color: moveData["isCompleted"] ? AppColors.activeGreen : AppColors.textDark, fontWeight: moveData["isCompleted"] ? FontWeight.bold : FontWeight.w500)
                                  ),
                                ),
                                if (moveData["isCompleted"]) const Icon(Icons.eco, color: AppColors.activeGreen, size: 20)
                              ],
                            ),
                          ),
                        )),

                      // DURUM B: Dataset bitti, Stockfish Düşünüyor
                      if (nextMoves.isEmpty && isEngineThinking)
                        const Row(
                          children: [
                            CircularProgressIndicator(color: AppColors.woodBrown),
                            SizedBox(width: 15),
                            Expanded(child: Text("Veriseti dışına çıkıldı.\nStockfish en iyi hamleyi hesaplıyor...", style: TextStyle(color: AppColors.woodBrown, fontStyle: FontStyle.italic))),
                          ],
                        ),

                      // DURUM C: Stockfish Hamle Buldu
                      if (nextMoves.isEmpty && !isEngineThinking && engineBestMove != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.blueGrey.shade100, border: Border.all(color: Colors.blueGrey), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.memory, color: Colors.blueGrey),
                                  SizedBox(width: 8),
                                  Text("Stockfish Önerisi", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text("En iyi devam yolu: $engineBestMove", style: const TextStyle(fontSize: 16, color: Colors.black87)),
                              const SizedBox(height: 5),
                              const Text("(Hamleyi tahtada oynayarak devam edebilirsiniz)", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}