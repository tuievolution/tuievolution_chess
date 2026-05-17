import 'dart:async';
import 'package:stockfish/stockfish.dart';
import 'stockfish_service.dart';

class StockfishPlatformService {
  Stockfish? _engine;
  StreamSubscription? _stdoutSub;
  bool _isReady = false;
  
  Function(String)? onBestMoveFound;
  Function(List<EngineVariation>)? onEngineInfo;
  Function(String)? onError;

  final Map<int, EngineVariation> _currentVariations = {};
  String? _pendingFen;
  int? _pendingDepth;

  void initEngine() {
    try {
      _engine = Stockfish();
      
      // Listen to the engine's stdout (what Stockfish "says")
      _stdoutSub = _engine!.stdout.listen((line) {
        if (line.trim() == 'uciok') {
          _engine!.stdin = 'isready';
        } else if (line.trim() == 'readyok') {
          _isReady = true;
          if (_pendingFen != null && _pendingDepth != null) {
            _sendCalculation(_pendingFen!, _pendingDepth!);
            _pendingFen = null;
            _pendingDepth = null;
          }
        } else if (line.startsWith('info') && line.contains('depth')) {
          _parseInfoLine(line);
        } else if (line.startsWith('bestmove')) {
          final parts = line.split(' ');
          if (parts.length > 1 && onBestMoveFound != null) {
            final uciMove = parts[1]; 
            if (uciMove != '(none)') {
              onBestMoveFound!(uciMove);
            }
          }
          if (onEngineInfo != null && _currentVariations.isNotEmpty) {
            final sortedVars = _currentVariations.values.toList()
              ..sort((a, b) => a.rank.compareTo(b.rank));
            onEngineInfo!(sortedVars);
          }
        }
      });
      
      _engine!.stdin = 'uci';
    } catch (e) {
      print("Stockfish Engine Error: $e");
    }
  }

  // Parses the continuous evaluation info Stockfish spits out while thinking
  void _parseInfoLine(String line) {
    final parts = line.split(' ');
    
    int? multipv;
    String score = "";
    String pvMove = "";
    int? currentDepth;

    for (int i = 0; i < parts.length; i++) {
      if (parts[i] == 'depth' && i + 1 < parts.length) {
        currentDepth = int.tryParse(parts[i + 1]);
      } else if (parts[i] == 'multipv' && i + 1 < parts.length) {
        multipv = int.tryParse(parts[i + 1]);
      } else if (parts[i] == 'score' && i + 2 < parts.length) {
        if (parts[i + 1] == 'cp') {
          final cp = int.tryParse(parts[i + 2]) ?? 0;
          score = (cp > 0 ? '+' : '') + (cp / 100.0).toStringAsFixed(2);
        } else if (parts[i + 1] == 'mate') {
          final m = parts[i + 2];
          score = 'M$m';
        }
      } else if (parts[i] == 'pv' && i + 1 < parts.length) {
        pvMove = parts[i + 1];
        break;
      }
    }

    final rank = multipv ?? 1;

    if (pvMove.isNotEmpty && score.isNotEmpty) {
      _currentVariations[rank] = EngineVariation(
        rank: rank, 
        uciMove: pvMove, 
        score: score,
        depth: currentDepth,
      );
      if (onEngineInfo != null) {
        final sortedVars = _currentVariations.values.toList()
          ..sort((a, b) => a.rank.compareTo(b.rank));
        onEngineInfo!(sortedVars);
      }
    }
  }

  void _sendCalculation(String fen, int depth) {
    _engine!.stdin = 'stop';
    _engine!.stdin = 'setoption name MultiPV value 3';
    _engine!.stdin = 'position fen $fen';
    _engine!.stdin = 'go depth $depth';
  }

  void calculateBestMove(String fen, {int depth = 8}) {
    if (_engine == null) {
      onError?.call("Engine binary missing.");
      return;
    }
    _currentVariations.clear();
    try {
      if (_isReady) {
        _sendCalculation(fen, depth);
      } else {
        _pendingFen = fen;
        _pendingDepth = depth;
      }
    } catch (e) {
      onError?.call("Engine crashed.");
    }
  }

  void stopEngine() {
    _engine?.stdin = 'stop';
  }

  void dispose() {
    _stdoutSub?.cancel();
    _engine?.dispose();
  }
}