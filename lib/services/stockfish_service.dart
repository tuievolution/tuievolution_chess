import 'stockfish_unsupported.dart'
    if (dart.library.ffi) 'stockfish_native.dart';
import '../core/constants.dart';

class EngineVariation {
  final int rank;
  final String uciMove;
  final String score;
  final int? depth;
  const EngineVariation({required this.rank, required this.uciMove, required this.score, this.depth});
}

class StockfishService {
  final StockfishPlatformService _platformService = StockfishPlatformService();

  set onBestMoveFound(Function(String)? callback) {
    _platformService.onBestMoveFound = callback;
  }

  set onEngineInfo(Function(List<EngineVariation>)? callback) {
    _platformService.onEngineInfo = callback;
  }

  set onError(Function(String)? callback) {
    _platformService.onError = callback;
  }

  void initEngine() {
    _platformService.initEngine();
  }

  void calculateBestMove(String fen, {int? depth}) {
    _platformService.calculateBestMove(fen, depth: depth ?? AppConstants.engineDepth);
  }

  void stopEngine() {
    _platformService.stopEngine();
  }

  void dispose() {
    _platformService.dispose();
  }
}