import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:stockfish/stockfish.dart';

class EngineVariation {
  final int rank;
  final String uciMove;
  final String score;

  EngineVariation({
    required this.rank,
    required this.uciMove,
    required this.score,
  });
}

class StockfishService {
  // Singleton yapısı (Uygulamanın her yerinden tek bir motor örneğine erişmek için)
  static final StockfishService _instance = StockfishService._internal();
  factory StockfishService() => _instance;
  StockfishService._internal();

  Stockfish? _stockfish;
  StreamSubscription<String>? _stdoutSubscription;
  
  bool _isReady = false;
  bool _isCalculating = false;

  // UI (Arayüz) ile haberleşecek Callback'ler
  Function(String)? onBestMoveFound;
  Function(List<EngineVariation>)? onEngineInfo;
  Function(String)? onError;

  List<EngineVariation> _currentVariations = [];

  // Motoru Başlat
  void initEngine() {
    if (_stockfish != null) return; // Zaten çalışıyorsa tekrar başlatma
    
    _stockfish = Stockfish();
    
    _stdoutSubscription = _stockfish!.stdout.listen((line) {
      _parseEngineOutput(line);
    }, onError: (error) {
      debugPrint('Stockfish Hatası: $error');
      onError?.call(error.toString());
    });

    // Motoru UCI moduna geçir ve hazır olup olmadığını sor
    _sendCommand('uci');
    _sendCommand('isready');
  }

  // Motor Çıktılarını (Terminal loglarını) Ayrıştıran Akıllı Fonksiyon
  void _parseEngineOutput(String line) {
    if (line == 'readyok') {
      _isReady = true;
      debugPrint("Stockfish: READY");
    } 
    else if (line.startsWith('bestmove')) {
      _isCalculating = false;
      final parts = line.split(' ');
      if (parts.length > 1) {
        String move = parts[1];
        onBestMoveFound?.call(move);
      }
    } 
    else if (line.startsWith('info') && line.contains('pv')) {
      _parseInfoLine(line);
    }
  }

  // Info satırından değerlendirme puanını (Score) ve en iyi hamleleri çeker
  void _parseInfoLine(String line) {
    try {
      final parts = line.split(' ');
      
      int multipv = 1;
      String score = "0.00";
      String uciMove = "";

      for (int i = 0; i < parts.length; i++) {
        if (parts[i] == 'multipv' && i + 1 < parts.length) {
          multipv = int.tryParse(parts[i + 1]) ?? 1;
        } else if (parts[i] == 'score' && i + 2 < parts.length) {
          if (parts[i + 1] == 'cp') {
            int cp = int.tryParse(parts[i + 2]) ?? 0;
            score = (cp / 100.0).toStringAsFixed(2);
          } else if (parts[i + 1] == 'mate') {
            score = "M${parts[i + 2]}"; // Mat hamlesi
          }
        } else if (parts[i] == 'pv' && i + 1 < parts.length) {
          uciMove = parts[i + 1]; // İlk pv (Principal Variation) hamlesi bizim en iyi hamlemizdir
          break; 
        }
      }

      if (uciMove.isNotEmpty) {
        final variation = EngineVariation(rank: multipv, uciMove: uciMove, score: score);
        
        // Listeyi güncelle (Örn: Sadece ilk 3 varyantı tutuyoruz)
        if (_currentVariations.length >= multipv) {
          _currentVariations[multipv - 1] = variation;
        } else {
          _currentVariations.add(variation);
        }
        
        onEngineInfo?.call(List.from(_currentVariations));
      }
    } catch (e) {
      debugPrint("Stockfish Parse Hatası: $e");
    }
  }

  // Güvenli Komut Gönderme
  void _sendCommand(String command) {
    if (_stockfish != null) {
      _stockfish!.stdin = command;
    }
  }

  // Yeni bir arama başlatır
  void calculateBestMove(String fen, {int depth = 12}) {
    if (!_isReady) {
      debugPrint("Stockfish henüz hazır değil, bekleniyor...");
      return;
    }

    // Eğer zaten düşünüyorsa, önce durdur ki motor kilitlenmesin
    if (_isCalculating) {
      stopEngine();
    }

    _isCalculating = true;
    _currentVariations = [];
    
    // Uygulamanın takılmaması için küçük bir gecikme ekliyoruz
    Future.delayed(const Duration(milliseconds: 100), () {
      _sendCommand('position fen $fen');
      _sendCommand('go depth $depth'); // Çok derin arama cihazı kitler, depth 12 idealdir
    });
  }

  // Aramayı anında durdurur
  void stopEngine() {
    _sendCommand('stop');
    _isCalculating = false;
  }

  // Sayfa kapanırken motoru tamamen öldürür ve RAM'i temizler
  void disposeEngine() {
    stopEngine();
    _sendCommand('quit');
    _stdoutSubscription?.cancel();
    _stockfish = null;
    _isReady = false;
  }
}

// Projenin her yerinde `stockfishService` değişkeni ile bu sınıfa ulaşabilirsin
final stockfishService = StockfishService();