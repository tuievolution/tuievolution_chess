// This file is compiled ONLY when running on the Web.
// It contains NO references to dart:ffi or the native stockfish package.

class StockfishPlatformService {
  Function(String)? onBestMoveFound;
  Function(String)? onError;

  void initEngine() {
    print("Stockfish Web Fallback initialized. Native engine bypassed.");
  }

  void calculateBestMove(String fen, {int depth = 12}) {
    // Immediately return a graceful error to the UI because Web can't run the C++ engine.
    onError?.call("Web platform does not support the native Stockfish engine. Only the Opening Database is active.");
  }

  void dispose() {}
}