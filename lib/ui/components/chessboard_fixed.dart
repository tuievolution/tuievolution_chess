import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:chess/chess.dart' as chess_lib; // Move calculation helper
import '../../core/theme.dart';

class ChessboardFixed extends StatefulWidget {
  final String startingFen; // Usually the standard chess start
  final List<String> initialMoves; // The history of moves played to get here
  final ValueChanged<String>? onPositionChanged; 

  const ChessboardFixed({
    super.key, 
    required this.startingFen, 
    this.initialMoves = const [], 
    this.onPositionChanged
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

  @override
  void initState() {
    super.initState();
    controller = ChessBoardController();
    
    // Build the history from the very beginning
    _buildFullHistory();
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
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 2)),
            child: ChessBoard(
              controller: controller,
              boardColor: BoardColor.brown,
              boardOrientation: isWhiteBottom ? PlayerColor.white : PlayerColor.black,
            ),
          ),
        ),
        // Navigation Buttons
        Container(
          color: AppColors.woodBrown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(icon: const Icon(Icons.flip_camera_android, color: Colors.white), onPressed: () => setState(() => isWhiteBottom = !isWhiteBottom)),
              IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white), onPressed: () => _navigate(0)),
              IconButton(icon: const Icon(Icons.navigate_before, color: Colors.white), onPressed: () => _navigate(currentIndex > 0 ? currentIndex - 1 : 0)),
              IconButton(icon: const Icon(Icons.navigate_next, color: Colors.white), onPressed: () => _navigate(currentIndex < fenHistory.length - 1 ? currentIndex + 1 : currentIndex)),
              IconButton(icon: const Icon(Icons.skip_next, color: Colors.white), onPressed: () => _navigate(fenHistory.length - 1)),
            ],
          ),
        ),
        // Notation Panel
        Container(
          width: double.infinity, height: 120, padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(color: AppColors.background, border: Border(bottom: BorderSide(color: AppColors.border, width: 2))),
          child: SingleChildScrollView(
            child: Wrap(
              children: List.generate(sanHistory.length, (i) {
                bool isCurrent = (i == currentIndex - 1);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (i % 2 == 0) Text('${(i ~/ 2) + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    InkWell(
                      onTap: () => _navigate(i + 1),
                      child: Text("${sanHistory[i]} ", style: TextStyle(color: isCurrent ? AppColors.activeGreen : AppColors.textDark, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}