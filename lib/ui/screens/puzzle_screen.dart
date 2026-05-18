import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme.dart';
import '../../models/puzzle_model.dart';
import '../widgets/grow_button.dart';
import '../components/chessboard_fixed.dart';
import '../../main.dart'; // supabaseService ve dataService erişimi için
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
  
  // Döngü kilitlenmelerini önlemek ve hamle doğrulamak için kritik FEN takibi
  String lastCorrectFen = ""; 

  @override
  void initState() {
    super.initState();
    _loadPuzzlesFromSupabase();
  }

  Future<void> _loadPuzzlesFromSupabase() async {
    setState(() => isLoading = true);
    
    // Kullanıcının mevcut seviyesine göre (Örn: 1500) Supabase'den 5 bulmaca getiriyoruz
    final fetchedPuzzles = await supabaseService.fetchPuzzlesByRating(1500, limit: 5);
    
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
    final puzzle = puzzleQueue[currentPuzzleIndex];
    setState(() {
      moveIndex = 0;
      isPuzzleCompleted = false;
      isOpponentThinking = true;
      lastCorrectFen = puzzle.fen;
      feedbackMessage = "Bulmaca hazırlandı. Rakip hamlesi bekleniyor...";
      feedbackColor = Colors.grey;
    });

    // Tahtayı temizle ve FEN düzenini kur
    _boardKey.currentState?.resetBoard();
    
    // Rakibin bulmacayı başlatan hatalı/feda hamlesini oynaması için tetikliyoruz
    Future.delayed(const Duration(milliseconds: 1000), () {
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
        moveIndex++; // Sıra kullanıcıya geçti
        isOpponentThinking = false;
        feedbackMessage = "Sıra sizde! En iyi hamleyi bulun.";
        feedbackColor = AppColors.primary;
      });
    }
  }

  // GERÇEK ZAMANLI KESİN DOĞRULAMA MOTORU (Strict Verification)
  void _onPositionChanged(String newFen) {
    if (isLoading || puzzleQueue.isEmpty || isPuzzleCompleted || isOpponentThinking) return;
    
    // Geri alma (takeback) tetiklendiğinde sonsuz döngü oluşmasını engelleme filtresi
    if (dataService.normalizeFen(newFen) == dataService.normalizeFen(lastCorrectFen)) {
      return;
    }

    final puzzle = puzzleQueue[currentPuzzleIndex];
    if (moveIndex >= puzzle.moves.length) return;

    // Beklenen doğru hamleyi sanal tahtada simüle ediyoruz
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

    // Kullanıcının yaptığı hamle sonucu oluşan yeni FEN, beklenen FEN ile eşleşiyor mu?
    if (valid && dataService.normalizeFen(newFen) == dataService.normalizeFen(tempChess.fen)) {
      // DOĞRU HAMLE!
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
      } else {
        // Bulmaca bitmediyse bilgisayar sonraki yanıtını otomatik oynar
        setState(() { isOpponentThinking = true; });
        Future.delayed(const Duration(milliseconds: 800), () {
          _playOpponentMove();
        });
      }
    } else {
      // YANLIŞ HAMLE! Tahtadaki hatalı taşı fiziksel olarak geri çektiriyoruz
      _boardKey.currentState?.takebackMove();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Hatalı hamle! Doğru çözümü bulmaya çalışın.', style: TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
          backgroundColor: const Color(0xFFC94B4B), // Göz yormayan asil Soft Red / Mat Kırmızı
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
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
      _loadPuzzlesFromSupabase(); // 5'li paket bittiyse buluttan yeni paket indir
    }
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
        body: const Center(child: Text("Seviyenize uygun bulmaca bulunamadı.", style: TextStyle(color: Colors.white))),
      );
    }

    final puzzle = puzzleQueue[currentPuzzleIndex];
    bool isWhiteToMoveInitially = puzzle.fen.split(' ')[1] == 'w';
    bool amIWhite = !isWhiteToMoveInitially; // İlk hamleyi rakip yaptığı için biz tersiyiz

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
                            Text('ZORLUK: ${puzzle.rating}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary(context), fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 24),
                
                ChessboardFixed(
                  key: _boardKey,
                  startingFen: puzzle.fen,
                  isWhiteBottom: amIWhite, 
                  onPositionChanged: _onPositionChanged,
                ),
                
                const SizedBox(height: 18),

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

                const SizedBox(height: 18),
                
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