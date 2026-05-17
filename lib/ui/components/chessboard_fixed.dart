import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../../core/theme.dart';

class ChessboardFixed extends StatefulWidget {
  final String startingFen;
  final List<String> initialMoves;
  final ValueChanged<String>? onPositionChanged; 
  final ValueChanged<bool>? onEngineToggled;
  final bool initialEngineState;
  final bool isWhiteBottom; 

  const ChessboardFixed({
    super.key, 
    required this.startingFen, 
    this.initialMoves = const [], 
    this.onPositionChanged,
    this.onEngineToggled,
    this.initialEngineState = false,
    this.isWhiteBottom = true,
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
  late bool isEngineEnabled;

  @override
  void initState() {
    super.initState();
    isEngineEnabled = widget.initialEngineState;
    controller = ChessBoardController();
    
    _buildFullHistory();

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
    final chess = chess_lib.Chess();
    fenHistory = [chess.fen];
    sanHistory = [];

    for (var move in widget.initialMoves) {
      bool moved = false;
      if (move.length >= 4 && !move.contains('x') && !move.contains('+') && !move.contains('-') && !move.contains('O')) {
        moved = chess.move({
          'from': move.substring(0, 2),
          'to': move.substring(2, 4),
          if (move.length == 5) 'promotion': move.substring(4, 5)
        });
      } else {
        moved = chess.move(move);
      }
      
      if (moved) {
        fenHistory.add(chess.fen);
        sanHistory.add(move);
      }
    }

    currentIndex = fenHistory.length - 1;
    controller.loadFen(fenHistory[currentIndex]);
  }

  // MOTOR HAMLESİ İÇİN (UCI Formatı: e2e4)
  void makeEngineMove(String uciMove) {
    if (uciMove.length >= 4 && mounted) {
      String fromSquare = uciMove.substring(0, 2);
      String toSquare = uciMove.substring(2, 4);
      controller.makeMove(from: fromSquare, to: toSquare);
    }
  }

  // AÇILIŞ ÖĞRETİCİSİ İÇİN (SAN Formatı: Nf3, O-O)
  bool makeMoveWithSan(String san) {
    final tempChess = chess_lib.Chess.fromFEN(controller.getFen());
    bool valid = tempChess.move(san);
    if (valid) {
      var moveHistory = tempChess.history; 
      if (moveHistory.isNotEmpty) {
        var lastState = moveHistory.last; 
        // DÜZELTME BURADA: lastState.move üzerinden fromAlgebraic ve toAlgebraic değerlerine ulaşıyoruz
        controller.makeMove(from: lastState.move.fromAlgebraic, to: lastState.move.toAlgebraic);
        return true;
      }
    }
    return false;
  }

  // KULLANICI YANLIŞ HAMLE YAPTIĞINDA GERİ ALMAK İÇİN
  void undoMove() {
    if (currentIndex > 0) {
      setState(() => isNavigating = true);
      controller.undoMove();
      fenHistory.removeLast();
      sanHistory.removeLast();
      currentIndex--;
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) setState(() => isNavigating = false);
      });
    }
  }

  // TAHTAYI BAŞA SARMAK İÇİN
  void resetBoard() {
    setState(() {
      isNavigating = true;
      controller.resetBoard();
      fenHistory = [widget.startingFen];
      sanHistory = [];
      currentIndex = 0;
    });
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) setState(() => isNavigating = false);
    });
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
                  boardOrientation: widget.isWhiteBottom ? PlayerColor.white : PlayerColor.black,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border(context), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Spacer(),
                  IconButton(icon: Icon(Icons.skip_previous, color: AppColors.textSecondary(context)), onPressed: () => _navigate(0)),
                  IconButton(icon: Icon(Icons.navigate_before, color: AppColors.textSecondary(context)), onPressed: () => _navigate(currentIndex > 0 ? currentIndex - 1 : 0)),
                  IconButton(icon: Icon(Icons.navigate_next, color: AppColors.textSecondary(context)), onPressed: () => _navigate(currentIndex < fenHistory.length - 1 ? currentIndex + 1 : currentIndex)),
                  IconButton(icon: Icon(Icons.skip_next, color: AppColors.textSecondary(context)), onPressed: () => _navigate(fenHistory.length - 1)),
                ],
              ),
            ),
            const SizedBox(height: 12),
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