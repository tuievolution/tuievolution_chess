import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../../core/theme.dart';

class ChessboardFixed extends StatefulWidget {
  final String startingFen;
  final List<String> initialMoves;
  final bool isPracticeMode;
  final bool startFromBeginning;
  final ValueChanged<String>? onPositionChanged; 
  final ValueChanged<bool>? onEngineToggled;
  final VoidCallback? onWrongMove;
  final VoidCallback? onCorrectMove;
  final bool initialEngineState;
  final bool isWhiteBottom; 

  const ChessboardFixed({
    super.key, 
    required this.startingFen, 
    this.initialMoves = const [], 
    this.isPracticeMode = false,
    this.startFromBeginning = false,
    this.onPositionChanged,
    this.onEngineToggled,
    this.onWrongMove,
    this.onCorrectMove,
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
  late bool isEngineEnabled;

  @override
  void initState() {
    super.initState();
    isEngineEnabled = widget.initialEngineState;
    controller = ChessBoardController();
    _buildFullHistory();

    controller.addListener(() {
      if (!mounted) return;
      String currentFen = controller.getFen();
      
      if (fenHistory.isNotEmpty && currentFen == fenHistory[currentIndex]) return; 

      if (widget.isPracticeMode && currentIndex + 1 < fenHistory.length && currentFen == fenHistory[currentIndex + 1]) {
        currentIndex++;
        setState(() {});
        widget.onCorrectMove?.call(); 
        widget.onPositionChanged?.call(currentFen);
        return;
      }

      if (widget.isPracticeMode) {
        controller.undoMove(); 
        widget.onWrongMove?.call();
        return;
      }

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

  @override
  void didUpdateWidget(ChessboardFixed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPracticeMode != widget.isPracticeMode ||
        oldWidget.initialMoves != widget.initialMoves ||
        oldWidget.startFromBeginning != widget.startFromBeginning) {
      _buildFullHistory();
    }
  }

  void _buildFullHistory() {
    final chess = chess_lib.Chess();
    fenHistory = [chess.fen];
    sanHistory = [];

    for (var move in widget.initialMoves) {
      bool moved = false;
      if (move.length >= 4 && !move.contains('x') && !move.contains('+') && !move.contains('-') && !move.contains('O') && !move.contains('N') && !move.contains('B') && !move.contains('R') && !move.contains('Q') && !move.contains('K')) {
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

    if (widget.startFromBeginning || widget.isPracticeMode) {
      currentIndex = 0;
    } else {
      currentIndex = fenHistory.length - 1;
    }
    controller.loadFen(fenHistory[currentIndex]);
  }

  void playUciMove(String uciMove) {
    if (uciMove.length >= 4 && mounted) {
      String fromSquare = uciMove.substring(0, 2);
      String toSquare = uciMove.substring(2, 4);
      String? promotion = uciMove.length == 5 ? uciMove[4] : null;

      final tempChess = chess_lib.Chess.fromFEN(controller.getFen());
      bool valid = tempChess.move({
        'from': fromSquare,
        'to': toSquare,
        if (promotion != null) 'promotion': promotion
      });

      if (valid) {
        makeMoveFromExternal("${fromSquare}${toSquare}", tempChess.fen);
      } else {
        controller.makeMove(from: fromSquare, to: toSquare);
      }
    }
  }

  void playSanMove(String san) {
    final tempChess = chess_lib.Chess.fromFEN(controller.getFen());
    if (tempChess.move(san)) {
      var moveHistory = tempChess.history; 
      if (moveHistory.isNotEmpty) {
        var lastState = moveHistory.last; 
        controller.makeMove(from: lastState.move.fromAlgebraic, to: lastState.move.toAlgebraic);
      }
    }
  }

  void takebackMove() {
    if (currentIndex > 0) {
      controller.undoMove();
      fenHistory.removeLast();
      sanHistory.removeLast();
      currentIndex--;
      setState(() {});
      widget.onPositionChanged?.call(controller.getFen());
    }
  }

  void undoMove() {
    if (currentIndex > 0) {
      controller.undoMove();
      fenHistory.removeLast();
      sanHistory.removeLast();
      currentIndex--;
      setState(() {});
    }
  }

  bool navigateForward() {
    if (currentIndex < fenHistory.length - 1) {
      _navigate(currentIndex + 1);
      return true;
    }
    return false;
  }

  void resetBoard() {
    setState(() {
      controller.resetBoard();
      fenHistory = [widget.startingFen];
      sanHistory = [];
      currentIndex = 0;
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
    controller.loadFen(newFen);
    setState(() {});
    widget.onPositionChanged?.call(newFen); 
  }

  void _navigate(int newIndex) {
    if (newIndex == currentIndex) return;
    setState(() {
      currentIndex = newIndex;
      controller.loadFen(fenHistory[currentIndex]); 
      widget.onPositionChanged?.call(fenHistory[currentIndex]);
    });
  }

  int get currentPlyCount => currentIndex;

  // SİMETRİK KOORDİNAT YARDIMCILARI
  Widget _buildLettersRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(8, (i) {
        String file = String.fromCharCode(97 + (widget.isWhiteBottom ? i : 7 - i));
        return Text(file, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12));
      }),
    );
  }

  Widget _buildNumbersCol() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(8, (i) {
        int rank = widget.isWhiteBottom ? 8 - i : i + 1;
        return Text('$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12));
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              // YENİ: Koordinatlar artık tahtanın dışında, tamamen simetrik
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.boardDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Üst Harfler
                    SizedBox(
                      height: 18,
                      child: Row(
                        children: [
                          const SizedBox(width: 18),
                          Expanded(child: _buildLettersRow()),
                          const SizedBox(width: 18),
                        ],
                      ),
                    ),
                    // Orta: Sol Rakamlar + Tahta + Sağ Rakamlar
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(width: 18, child: _buildNumbersCol()),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: ChessBoard(
                                controller: controller,
                                boardColor: BoardColor.brown,
                                boardOrientation: widget.isWhiteBottom ? PlayerColor.white : PlayerColor.black,
                              ),
                            ),
                          ),
                          SizedBox(width: 18, child: _buildNumbersCol()),
                        ],
                      ),
                    ),
                    // Alt Harfler
                    SizedBox(
                      height: 18,
                      child: Row(
                        children: [
                          const SizedBox(width: 18),
                          Expanded(child: _buildLettersRow()),
                          const SizedBox(width: 18),
                        ],
                      ),
                    ),
                  ],
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
                  IconButton(
                    icon: const Icon(Icons.undo), 
                    color: AppColors.primary,
                    tooltip: '1 Hamle Geri Al',
                    onPressed: takebackMove,
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