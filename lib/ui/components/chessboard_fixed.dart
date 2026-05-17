import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:chess/chess.dart' as chess_lib; // Move calculation helper
import '../../core/theme.dart';

class ChessboardFixed extends StatefulWidget {
  final String startingFen; // Usually the standard chess start
  final List<String> initialMoves; // The history of moves played to get here
  final ValueChanged<String>? onPositionChanged; 
  final ValueChanged<bool>? onEngineToggled;
  final bool initialEngineState;

  const ChessboardFixed({
    super.key, 
    required this.startingFen, 
    this.initialMoves = const [], 
    this.onPositionChanged,
    this.onEngineToggled,
    this.initialEngineState = false,
  });

  @override
  State<ChessboardFixed> createState() => ChessboardFixedState();
}

class ChessboardFixedState extends State<ChessboardFixed> {
  late ChessBoardController controller;
  List<String> fenHistory = []; 
  List<String> sanHistory = []; 
  int currentIndex = 0;         
  bool isNavigating = false;    
  bool isWhiteBottom = true;    
  late bool isEngineEnabled;

  @override
  void initState() {
    super.initState();
    isEngineEnabled = widget.initialEngineState;
    controller = ChessBoardController();
    
    // Build the history from the very beginning
    _buildFullHistory();

    // Listen to manual user moves on the board
    controller.addListener(() {
      if (isNavigating) return; 
      
      String currentFen = controller.getFen();
      if (currentFen == fenHistory[currentIndex]) return; 

      var sans = controller.getSan().whereType<String>().toList();
      if (sans.isNotEmpty) {
        String lastElement = sans.last; 
        List<String> tokens = lastElement.trim().split(RegExp(r'\s+'));
        String pureMove = tokens.last.replaceAll(RegExp(r'^\d+\.+'), '');

        if (currentIndex < fenHistory.length - 1) {
          fenHistory.length = currentIndex + 1;
          sanHistory.length = currentIndex;
        }
        
        fenHistory.add(currentFen);
        sanHistory.add(pureMove);
        currentIndex++;
        
        setState(() {}); 
        widget.onPositionChanged?.call(currentFen); 
      }
    });
  }

  void _buildFullHistory() {
    final chess = chess_lib.Chess(); // Use a virtual board to calculate FENs for history
    fenHistory = [chess.fen];
    sanHistory = [];

    // Replay the history moves to populate the "Time Machine"
    for (var move in widget.initialMoves) {
      if (chess.move(move)) {
        fenHistory.add(chess.fen);
        sanHistory.add(move);
      }
    }

    currentIndex = fenHistory.length - 1;
    controller.loadFen(fenHistory[currentIndex]);
  }

  void makeMoveFromExternal(String san, String newFen) {
    if (currentIndex < fenHistory.length - 1) {
      fenHistory.length = currentIndex + 1;
      sanHistory.length = currentIndex;
    }
    fenHistory.add(newFen);
    sanHistory.add(san);
    currentIndex++;
    setState(() { isNavigating = true; controller.loadFen(newFen); });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) isNavigating = false;
      widget.onPositionChanged?.call(newFen); 
    });
  }

  void _navigate(int newIndex) {
    if (newIndex == currentIndex) return;
    setState(() {
      isNavigating = true; 
      currentIndex = newIndex;
      controller.loadFen(fenHistory[currentIndex]); 
      widget.onPositionChanged?.call(fenHistory[currentIndex]);
    });
    Future.delayed(const Duration(milliseconds: 100), () { if (mounted) isNavigating = false; });
  }

  int get currentPlyCount => currentIndex;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border(context), width: 2),
                ),
                child: ChessBoard(
                  controller: controller,
                  boardColor: BoardColor.brown,
                  boardOrientation: isWhiteBottom ? PlayerColor.white : PlayerColor.black,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Navigation Buttons
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border(context), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.flip_camera_android, color: AppColors.textSecondary(context), size: 20),
                    onPressed: () => setState(() => isWhiteBottom = !isWhiteBottom),
                    tooltip: "Flip Board",
                  ),
                  IconButton(
                    icon: Icon(Icons.memory, color: isEngineEnabled ? AppColors.primary : AppColors.textSecondary(context), size: 20),
                    onPressed: () {
                      setState(() => isEngineEnabled = !isEngineEnabled);
                      widget.onEngineToggled?.call(isEngineEnabled);
                    },
                    tooltip: "Toggle Engine",
                  ),
                  const Spacer(),
                  IconButton(icon: Icon(Icons.skip_previous, color: AppColors.textSecondary(context)), onPressed: () => _navigate(0)),
                  IconButton(icon: Icon(Icons.navigate_before, color: AppColors.textSecondary(context)), onPressed: () => _navigate(currentIndex > 0 ? currentIndex - 1 : 0)),
                  IconButton(icon: Icon(Icons.navigate_next, color: AppColors.textSecondary(context)), onPressed: () => _navigate(currentIndex < fenHistory.length - 1 ? currentIndex + 1 : currentIndex)),
                  IconButton(icon: Icon(Icons.skip_next, color: AppColors.textSecondary(context)), onPressed: () => _navigate(fenHistory.length - 1)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Notation Panel (Move History)
            Container(
              width: double.infinity, 
              height: 120, 
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface(context), 
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border(context), width: 1),
              ),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: List.generate(sanHistory.length, (i) {
                    bool isCurrent = (i == currentIndex - 1);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (i % 2 == 0) Text('${(i ~/ 2) + 1}. ', style: TextStyle(color: AppColors.textSecondary(context), fontWeight: FontWeight.bold)),
                        InkWell(
                          onTap: () => _navigate(i + 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCurrent ? AppColors.primaryDark : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "${sanHistory[i]} ", 
                              style: TextStyle(
                                color: isCurrent ? AppColors.primary : AppColors.textPrimary(context), 
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal
                              )
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}