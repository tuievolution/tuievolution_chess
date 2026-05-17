// This file is compiled ONLY when running on the Web.
// It contains NO references to dart:ffi or the native stockfish package.

import 'stockfish_service.dart';

class StockfishPlatformService {
  Function(String)? onBestMoveFound;
  Function(List<EngineVariation>)? onEngineInfo;
  Function(String)? onError;

  void initEngine() {
    print("Stockfish Web Fallback initialized. Native engine bypassed.");
  }

  void calculateBestMove(String fen, {int depth = 8}) {
    onError?.call("Web platform does not support the native Stockfish engine. Only the Opening Database is active.");
  }

  void stopEngine() {}

  void dispose() {}
}