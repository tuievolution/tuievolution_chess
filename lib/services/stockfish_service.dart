// CONDITIONAL IMPORT MAGIC:
// If the device supports 'dart:ffi' (Windows, Android, iOS), use the native file.
// If it does not (Web), use the unsupported stub.
import 'stockfish_unsupported.dart'
    if (dart.library.ffi) 'stockfish_native.dart';

class StockfishService {
  // Instantiate the class from whichever file was conditionally imported above
  final StockfishPlatformService _platformService = StockfishPlatformService();

  // Route the callbacks to the underlying platform service
  set onBestMoveFound(Function(String)? callback) {
    _platformService.onBestMoveFound = callback;
  }

  set onError(Function(String)? callback) {
    _platformService.onError = callback;
  }

  void initEngine() {
    _platformService.initEngine();
  }

  void calculateBestMove(String fen, {int depth = 12}) {
    _platformService.calculateBestMove(fen, depth: depth);
  }

  void dispose() {
    _platformService.dispose();
  }
}