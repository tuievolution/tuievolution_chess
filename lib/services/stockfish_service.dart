import 'dart:async';
import 'package:stockfish/stockfish.dart';

class StockfishService {
  Stockfish? _engine;
  StreamSubscription? _stdoutSub;
  
  // Bu callback, Stockfish bir hamle bulduğunda UI'a haber vermek için kullanılır
  Function(String)? onBestMoveFound;

  void initEngine() {
    print("Stockfish Engine Initialize Ediliyor...");
    _engine = Stockfish();
    
    // Motorun çıktılarını dinliyoruz
    _stdoutSub = _engine!.stdout.listen((line) {
      // Stockfish analizi bitirdiğinde 'bestmove e2e4 ponder e7e5' gibi bir çıktı verir
      if (line.startsWith('bestmove')) {
        final parts = line.split(' ');
        if (parts.length > 1 && onBestMoveFound != null) {
          final uciMove = parts[1]; // Örn: 'e2e4'
          if (uciMove != '(none)') {
            onBestMoveFound!(uciMove);
          }
        }
      }
    });
  }

  // Motora mevcut konumu verip düşünmesini emrediyoruz
  void calculateBestMove(String fen, {int depth = 12}) {
    if (_engine == null) return;
    
    // Önceki aramayı durdur ve yeni FEN'i yükle
    _engine!.stdin = 'stop';
    _engine!.stdin = 'position fen $fen';
    // Belirlenen derinliğe (depth) kadar en iyi hamleyi ara
    _engine!.stdin = 'go depth $depth';
  }

  void dispose() {
    _stdoutSub?.cancel();
    _engine?.dispose();
  }
}