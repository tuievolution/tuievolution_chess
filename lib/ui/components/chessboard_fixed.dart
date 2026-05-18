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
  late chess_lib.Chess gameTracker; 
  List<String> fenHistory = []; 
  List<String> sanHistory = []; 
  int currentIndex = 0;         
  late bool isEngineEnabled;
  bool isInternalMove = false; // Kilitlenmeyi çözen bayrak

  @override
  void initState() {
    super.initState();
    isEngineEnabled = widget.initialEngineState;
    controller = ChessBoardController();
    _buildFullHistory();

    controller.addListener(() {
      if (!mounted || isInternalMove) return;
      
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
        String rawLast = sans.last; 
        List<String> tokens = rawLast.trim().split(RegExp(r'\s+'));
        String pureMove = tokens.last.replaceAll(RegExp(r'^\d+\.+'), '');

        _syncGameTrackerToCurrentIndex();
        bool moved = gameTracker.move(pureMove);
        String finalSan = pureMove;
        if (moved) {
            finalSan = gameTracker.pgn().split(RegExp(r'\s+')).last;
        }

        if (currentIndex < fenHistory.length - 1) {
          fenHistory.length = currentIndex + 1;
          sanHistory.length = currentIndex;
        }
        
        fenHistory.add(currentFen);
        sanHistory.add(finalSan);
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
        oldWidget.startFromBeginning != widget.startFromBeginning ||
        oldWidget.isWhiteBottom != widget.isWhiteBottom) {
      _buildFullHistory();
    }
  }

  void _syncGameTrackerToCurrentIndex() {
    gameTracker = chess_lib.Chess.fromFEN(widget.startingFen);
    for (int i = 0; i < currentIndex; i++) {
      if (i < sanHistory.length) {
         gameTracker.move(sanHistory[i]);
      }
    }
  }

  void _buildFullHistory() {
    isInternalMove = true;
    gameTracker = chess_lib.Chess.fromFEN(widget.startingFen);
    fenHistory = [gameTracker.fen];
    sanHistory = [];

    for (var move in widget.initialMoves) {
      bool moved = false;
      if (move.length >= 4 && !move.contains('x') && !move.contains('+') && !move.contains('-') && !move.contains('O') && !move.contains('N') && !move.contains('B') && !move.contains('R') && !move.contains('Q') && !move.contains('K')) {
        moved = gameTracker.move({
          'from': move.substring(0, 2),
          'to': move.substring(2, 4),
          if (move.length == 5) 'promotion': move.substring(4, 5)
        });
      } else {
        moved = gameTracker.move(move);
      }
      
      if (moved) {
        fenHistory.add(gameTracker.fen);
        List<String> pgnTokens = gameTracker.pgn().split(RegExp(r'\s+'));
        sanHistory.add(pgnTokens.last);
      }
    }

    if (widget.startFromBeginning || widget.isPracticeMode) {
      currentIndex = 0;
    } else {
      currentIndex = fenHistory.length - 1;
    }
    controller.loadFen(fenHistory[currentIndex]);
    isInternalMove = false;
  }

  // RANGE ERROR ÇÖZÜLDÜ: Motor hamlesi tamamen senkronize edildi
  void playUciMove(String uciMove) {
    if (uciMove.length >= 4 && mounted) {
      isInternalMove = true;
      String fromSquare = uciMove.substring(0, 2);
      String toSquare = uciMove.substring(2, 4);
      String? promotion = uciMove.length == 5 ? uciMove[4] : null;

      _syncGameTrackerToCurrentIndex();
      bool valid = gameTracker.move({
        'from': fromSquare,
        'to': toSquare,
        if (promotion != null) 'promotion': promotion
      });

      if (valid) {
        String finalSan = gameTracker.pgn().split(RegExp(r'\s+')).last;
        
        if (currentIndex < fenHistory.length - 1) {
          fenHistory.length = currentIndex + 1;
          sanHistory.length = currentIndex;
        }
        
        fenHistory.add(gameTracker.fen);
        sanHistory.add(finalSan);
        currentIndex++;
        
        controller.loadFen(gameTracker.fen);
        setState(() { isInternalMove = false; });
        widget.onPositionChanged?.call(gameTracker.fen);
      } else {
        isInternalMove = false;
      }
    }
  }

  void playSanMove(String san) {
    _syncGameTrackerToCurrentIndex();
    if (gameTracker.move(san)) {
       makeMoveFromExternal(san, gameTracker.fen);
    }
  }

  void takebackMove() {
    if (currentIndex > 0) {
      isInternalMove = true;
      currentIndex--;
      fenHistory.length = currentIndex + 1;
      sanHistory.length = currentIndex;
      controller.loadFen(fenHistory[currentIndex]);
      setState(() { isInternalMove = false; });
      widget.onPositionChanged?.call(controller.getFen());
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
    isInternalMove = true;
    setState(() {
      controller.resetBoard();
      fenHistory = [widget.startingFen];
      sanHistory = [];
      currentIndex = 0;
    });
    isInternalMove = false;
  }

  void makeMoveFromExternal(String san, String newFen) {
    isInternalMove = true;
    if (currentIndex < fenHistory.length - 1) {
      fenHistory.length = currentIndex + 1;
      sanHistory.length = currentIndex;
    }
    fenHistory.add(newFen);
    sanHistory.add(san);
    currentIndex++;
    controller.loadFen(newFen);
    setState(() { isInternalMove = false; });
    widget.onPositionChanged?.call(newFen); 
  }

  void _navigate(int newIndex) {
    if (newIndex == currentIndex) return;
    isInternalMove = true;
    setState(() {
      currentIndex = newIndex;
      controller.loadFen(fenHistory[currentIndex]); 
    });
    isInternalMove = false;
    widget.onPositionChanged?.call(fenHistory[currentIndex]);
  }

  int get currentPlyCount => currentIndex;

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
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.boardDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
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