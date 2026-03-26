import 'dart:async';
import 'package:stockfish/stockfish.dart'; // Safe to import here!

class StockfishPlatformService {
  Stockfish? _engine;
  StreamSubscription? _stdoutSub;
  
  Function(String)? onBestMoveFound;
  Function(String)? onError;

  void initEngine() {
    try {
      _engine = Stockfish();
      _stdoutSub = _engine!.stdout.listen((line) {
        if (line.startsWith('bestmove')) {
          final parts = line.split(' ');
          if (parts.length > 1 && onBestMoveFound != null) {
            final uciMove = parts[1]; 
            if (uciMove != '(none)') {
              onBestMoveFound!(uciMove);
            }
          }
        }
      });
    } catch (e) {
      print("Stockfish Engine Error: $e");
    }
  }

  void calculateBestMove(String fen, {int depth = 12}) {
    if (_engine == null) {
      onError?.call("Engine binary missing. Only the Opening Database is active.");
      return;
    }
    try {
      _engine!.stdin = 'stop';
      _engine!.stdin = 'position fen $fen';
      _engine!.stdin = 'go depth $depth';
    } catch (e) {
      onError?.call("Engine crashed during calculation.");
    }
  }

  void dispose() {
    _stdoutSub?.cancel();
    _engine?.dispose();
  }
}