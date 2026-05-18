import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../../core/theme.dart';
import '../../models/puzzle_model.dart';
import '../widgets/grow_button.dart';
import '../components/chessboard_fixed.dart';
import '../../main.dart'; 
import 'package:chess/chess.dart' as chess_lib;

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  final GlobalKey<ChessboardFixedState> _boardKey = GlobalKey<ChessboardFixedState>();

  List<PuzzleModel> puzzleQueue = [];
  int currentPuzzleIndex = 0;
  bool isLoading = true;

  int moveIndex = 0; 
  bool isPuzzleCompleted = false;
  bool isOpponentThinking = false;
  String feedbackMessage = "Yükleniyor...";
  Color feedbackColor = Colors.grey;
  
  String lastCorrectFen = ""; 
  int currentUserRating = 400; 

  @override
  void initState() {
    super.initState();
    _loadPuzzlesFromSupabase();
  }

  int _calculateUserRating() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return 1200; 
    } else {
      return 400; 
    }
  }

  Future<void> _loadPuzzlesFromSupabase() async {
    setState(() => isLoading = true);
    
    int targetRating = _calculateUserRating();
    setState(() {
      currentUserRating = targetRating;
    });
    
    final fetchedPuzzles = await supabaseService.fetchPuzzlesByRating(targetRating, limit: 5);
    
    if (mounted) {
      setState(() {
        puzzleQueue = fetchedPuzzles;
        currentPuzzleIndex = 0;
        isLoading = false;
      });

      if (puzzleQueue.isNotEmpty) {
        _initializeCurrentPuzzle();
      }
    }
  }

  void _initializeCurrentPuzzle() {
    if (puzzleQueue.isEmpty) return;
    final puzzle = puzzleQueue[currentPuzzleIndex];
    setState(() {
      moveIndex = 0;
      isPuzzleCompleted = false;
      isOpponentThinking = true;
      lastCorrectFen = puzzle.fen;
      // GÜNCELLENDİ: Kullanıcıya hazırlanması için zaman ve mesaj veriyoruz
      feedbackMessage = "Bulmaca hazırlandı. Tahta inceleniyor...";
      feedbackColor = Colors.grey;
    });

    _boardKey.currentState?.resetBoard();
    
    // GÜNCELLENDİ: Başlangıç gecikmesi 1 saniyeden 1.5 saniyeye (1500ms) çıkarıldı
    Future.delayed(const Duration(milliseconds: 1500), () {
      _playOpponentMove();
    });
  }

  void _playOpponentMove() {
    if (isPuzzleCompleted || puzzleQueue.isEmpty) return;
    final puzzle = puzzleQueue[currentPuzzleIndex];

    if (moveIndex < puzzle.moves.length && mounted) {
      String uciMove = puzzle.moves[moveIndex];
      
      setState(() { isOpponentThinking = true; });
      _boardKey.currentState?.playUciMove(uciMove);
      
      setState(() {
        lastCorrectFen = _boardKey.currentState?.controller.getFen() ?? puzzle.fen;
        moveIndex++; 
        isOpponentThinking = false;
        feedbackMessage = "Sıra sizde! En iyi hamleyi bulun.";
        feedbackColor = AppColors.primary;
      });
    }
  }

  void _onPositionChanged(String newFen) {
    if (isLoading || puzzleQueue.isEmpty || isPuzzleCompleted || isOpponentThinking) return;
    
    if (dataService.normalizeFen(newFen) == dataService.normalizeFen(lastCorrectFen)) {
      return;
    }

    final puzzle = puzzleQueue[currentPuzzleIndex];
    if (moveIndex >= puzzle.moves.length) return;

    String expectedUci = puzzle.moves[moveIndex];
    final tempChess = chess_lib.Chess.fromFEN(lastCorrectFen);
    
    String fromSquare = expectedUci.substring(0, 2);
    String toSquare = expectedUci.substring(2, 4);
    String? promotion = expectedUci.length == 5 ? expectedUci[4] : null;

    Map<String, dynamic> moveObj = {
      'from': fromSquare,
      'to': toSquare,
    };
    if (promotion != null) moveObj['promotion'] = promotion;

    bool valid = tempChess.move(moveObj);

    if (valid && dataService.normalizeFen(newFen) == dataService.normalizeFen(tempChess.fen)) {
      setState(() {
        lastCorrectFen = newFen;
        moveIndex++;
        feedbackMessage = "Harika! Doğru hamle. 🎯";
        feedbackColor = Colors.green;
      });

      if (moveIndex >= puzzle.moves.length) {
        setState(() {
          isPuzzleCompleted = true;
          feedbackMessage = "Tebrikler! Bulmacayı Başarıyla Çözdünüz 🍃";
        });
        _showSuccessDialog();
      } else {
        setState(() { isOpponentThinking = true; });
        // GÜNCELLENDİ: Rakibin cevap süresi 800ms'den 1200ms'ye uzatıldı (Daha sakin bir oyun)
        Future.delayed(const Duration(milliseconds: 1200), () {
          _playOpponentMove();
        });
      }
    } else {
      setState(() { isOpponentThinking = true; }); 
      _boardKey.currentState?.takebackMove();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Hatalı hamle! Rakibin hamlesine dikkat edin.', style: TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
          backgroundColor: const Color(0xFFC94B4B), 
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );

      if (moveIndex > 0) {
        _boardKey.currentState?.takebackMove(); 
        
        setState(() {
          moveIndex--; 
          lastCorrectFen = _boardKey.currentState?.controller.getFen() ?? puzzle.fen;
        });
        
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _playOpponentMove();
        });
      } else {
        setState(() { isOpponentThinking = false; });
      }
    }
  }

  void _getHint() {
    if (puzzleQueue.isEmpty || isPuzzleCompleted) return;
    final puzzle = puzzleQueue[currentPuzzleIndex];
    
    if (moveIndex < puzzle.moves.length) {
      String hintMove = puzzle.moves[moveIndex];
      
      final tempChess = chess_lib.Chess.fromFEN(lastCorrectFen);
      String fromSquare = hintMove.substring(0, 2);
      String toSquare = hintMove.substring(2, 4);
      String? promotion = hintMove.length == 5 ? hintMove[4] : null;

      Map<String, dynamic> moveObj = {
        'from': fromSquare,
        'to': toSquare,
      };
      if (promotion != null) moveObj['promotion'] = promotion;

      bool valid = tempChess.move(moveObj);
      
      String displaySan = hintMove;
      if (valid) {
        displaySan = tempChess.pgn().split(RegExp(r'\s+')).last;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('İpucu Hamlesi: $displaySan', style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          backgroundColor: const Color(0xFFD9822B), 
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _playHintForUser() {
    if (puzzleQueue.isEmpty || isPuzzleCompleted) return;
    final puzzle = puzzleQueue[currentPuzzleIndex];
    if (moveIndex < puzzle.moves.length) {
      _boardKey.currentState?.playUciMove(puzzle.moves[moveIndex]);
    }
  }

  void _nextPuzzle() {
    if (currentPuzzleIndex < puzzleQueue.length - 1) {
      setState(() {
        currentPuzzleIndex++;
      });
      _initializeCurrentPuzzle();
    } else {
      _loadPuzzlesFromSupabase(); 
    }
  }

  void _showSuccessDialog() {
    final puzzle = puzzleQueue[currentPuzzleIndex];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 28),
              SizedBox(width: 8),
              Text('Tebrikler! 🎉', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
            ],
          ),
          content: Text(
            'Bulmacayı başarıyla çözdünüz. (Puan: ${puzzle.rating})',
            style: TextStyle(color: AppColors.textPrimary(context)),
          ),
          actions: [
            if (Supabase.instance.client.auth.currentSession == null)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _nextPuzzle();
                },
                child: const Text('Sonraki Bulmaca →', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              )
            else ...[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _nextPuzzle(); 
                },
                child: const Text('Aynı ELO ile Devam Et →', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: const Color(0xFF2A2118),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ayarlar ekranı yakında kurulacaktır. Buradan ELO seviyenizi güncelleyebileceksiniz.'), behavior: SnackBarBehavior.floating),
                  );
                },
                child: const Text('ELO Güncelle / Ayarlar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (puzzleQueue.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        appBar: AppBar(title: const Text('TuiEvolution Puzzles')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text("Şu an $currentUserRating ELO seviyesine uygun\nbulmaca bulunamadı.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
            ],
          )
        ),
      );
    }

    final puzzle = puzzleQueue[currentPuzzleIndex];
    bool isWhiteToMoveInitially = puzzle.fen.split(' ')[1] == 'w';
    bool amIWhite = !isWhiteToMoveInitially; 
    
    // GÜNCELLENDİ: Sıra kimde olduğunu belirleyen mantık
    bool isWhiteTurn = true;
    if (lastCorrectFen.isNotEmpty) {
      final parts = lastCorrectFen.split(' ');
      if (parts.length > 1) {
        isWhiteTurn = parts[1] == 'w';
      }
    }
    bool isMyTurn = (isWhiteTurn && amIWhite) || (!isWhiteTurn && !amIWhite);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(title: const Text('TuiEvolution Puzzles')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bulmaca #${puzzle.id}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text('BULMACA ELO: ${puzzle.rating}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary(context), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryDark),
                      ),
                      child: Text('Kuyruk: ${currentPuzzleIndex + 1} / ${puzzleQueue.length}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                
                // YENİ: SIRA KİMDE GÖSTERGESİ (Turn Indicator)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isWhiteTurn ? const Color(0xFFE8E8E8) : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isMyTurn && !isOpponentThinking ? AppColors.primary : Colors.transparent, 
                          width: 2
                        ),
                        boxShadow: [
                          if (isMyTurn && !isOpponentThinking)
                            BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 1)
                        ]
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isWhiteTurn ? Icons.circle : Icons.circle_outlined, 
                            color: isWhiteTurn ? Colors.black87 : Colors.white, 
                            size: 14
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOpponentThinking 
                                ? 'Rakip Düşünüyor (${isWhiteTurn ? 'Beyaz' : 'Siyah'})' 
                                : '${isWhiteTurn ? 'Beyaz' : 'Siyah'} Oynar',
                            style: TextStyle(
                              color: isWhiteTurn ? Colors.black87 : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                ChessboardFixed(
                  key: _boardKey,
                  startingFen: puzzle.fen,
                  isWhiteBottom: amIWhite, 
                  onPositionChanged: _onPositionChanged,
                ),
                
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: feedbackColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: feedbackColor.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: Text(
                      feedbackMessage,
                      style: TextStyle(color: feedbackColor, fontWeight: feedbackColor == Colors.green ? FontWeight.bold : FontWeight.w600, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: GrowButton(
                        text: 'Hamleyi Göster',
                        icon: Icons.lightbulb_outline,
                        type: GrowButtonType.secondary,
                        onPressed: isPuzzleCompleted ? null : _getHint,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GrowButton(
                        text: isPuzzleCompleted ? 'Sonraki Bulmaca' : 'Benim Yerime Oyna',
                        icon: isPuzzleCompleted ? Icons.skip_next : Icons.play_arrow,
                        type: GrowButtonType.primary,
                        onPressed: isPuzzleCompleted ? _nextPuzzle : _playHintForUser,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}