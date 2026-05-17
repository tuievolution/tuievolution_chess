import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'dart:async';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../main.dart';
import '../components/chessboard_fixed.dart';
import '../../services/stockfish_service.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final GlobalKey<ChessboardFixedState> _boardKey = GlobalKey<ChessboardFixedState>();

  bool isBuilderMode = true; 
  String selectedPiece = 'P'; 
  bool isWhiteTurn = true; // YENİ: Hamle sırasını tutar (w/b)

  late List<String> builderBoard;

  String currentFen = AppConstants.startingFen;
  String? openingName;
  bool isEngineThinking = false;
  List<EngineVariation> engineVariations = [];
  Timer? _engineTimeout;
  bool isEngineEnabled = true;

  @override
  void initState() {
    super.initState();
    _initBuilderBoard();

    stockfishService.onEngineInfo = (variations) {
      if (mounted) {
        _engineTimeout?.cancel();
        setState(() {
          engineVariations = variations;
          isEngineThinking = false;
        });
      }
    };

    stockfishService.onError = (err) {
      if (mounted) {
        _engineTimeout?.cancel();
        setState(() => isEngineThinking = false);
      }
    };
  }

  void _initBuilderBoard() {
    builderBoard = List.filled(64, '');
  }

  void _clearBoard() {
    setState(() {
      builderBoard = List.filled(64, '');
    });
  }

  void _startAnalysis() {
    String fen = _generateFen();
    setState(() {
      currentFen = fen;
      isBuilderMode = false;
    });
    if (isEngineEnabled) {
      _requestEngineMove(fen);
    }
  }

  // YENİDEN YAZILDI: Production Ready FEN Üretici
  String _generateFen() {
    String fen = '';
    for (int rank = 0; rank < 8; rank++) {
      int emptyCount = 0;
      for (int file = 0; file < 8; file++) {
        String piece = builderBoard[rank * 8 + file];
        if (piece.isEmpty) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            fen += emptyCount.toString();
            emptyCount = 0;
          }
          fen += piece;
        }
      }
      if (emptyCount > 0) fen += emptyCount.toString();
      if (rank < 7) fen += '/';
    }
    
    // w/b durumunu dinamik olarak atıyoruz
    String turn = isWhiteTurn ? 'w' : 'b';
    return '$fen $turn - - 0 1';
  }

  @override
  void dispose() {
    _engineTimeout?.cancel();
    super.dispose();
  }

  void _requestEngineMove(String fen) {
    if (!isEngineEnabled) {
      setState(() {
        isEngineThinking = false;
        engineVariations = [];
      });
      stockfishService.stopEngine();
      return;
    }
    setState(() {
      isEngineThinking = true;
      engineVariations = [];
    });
    stockfishService.calculateBestMove(fen);
    
    _engineTimeout?.cancel();
    _engineTimeout = Timer(const Duration(seconds: 10), () {
      if (mounted && isEngineThinking) {
        setState(() => isEngineThinking = false);
      }
    });
  }

  void _onBoardPositionChanged(String newFen) {
    setState(() {
      currentFen = newFen;
      openingName = dataService.getOpeningNameByFen(newFen);
      engineVariations = [];
    });
    _requestEngineMove(newFen);
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.primary, duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppColors.bg(context);
    final surfaceColor = AppColors.surface(context);
    final borderColor = AppColors.border(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isBuilderMode)
              _buildBoardEditor(surfaceColor, borderColor, textSecondary, isDark)
            else
              ...[
                ChessboardFixed(
                  key: _boardKey,
                  startingFen: currentFen,
                  initialEngineState: isEngineEnabled,
                  onEngineToggled: (enabled) {
                    setState(() => isEngineEnabled = enabled);
                    _requestEngineMove(currentFen);
                  },
                  onPositionChanged: _onBoardPositionChanged,
                ),
                const SizedBox(height: 16),
                _buildEngineAnalysisCard(surfaceColor, borderColor, textPrimary, textSecondary, isDark),
                const SizedBox(height: 16),
                _buildActionButtons(textPrimary, borderColor, isDark),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => setState(() => isBuilderMode = true),
                  icon: const Icon(Icons.edit_note, color: AppColors.primary),
                  label: const Text('Edit Position', style: TextStyle(color: AppColors.primary)),
                ),
                const SizedBox(height: 16),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildEngineAnalysisCard(Color surfaceColor, Color borderColor, Color textPrimary, Color textSecondary, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Engine Analysis', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Text('Stockfish (Depth ${AppConstants.engineDepth})', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          if (!isEngineEnabled)
            _buildInfoText('Engine is turned off. Toggle the icon on the board to analyze.', textSecondary)
          else if (isEngineThinking && engineVariations.isEmpty)
            _buildLoadingIndicator(textSecondary)
          else if (engineVariations.isEmpty)
            _buildInfoText('Make a move to start engine analysis', textSecondary)
          else
            ...engineVariations.map((v) => _VariationRow(rank: v.rank, move: v.uciMove, score: v.score, borderColor: borderColor, textPrimary: textPrimary, textSecondary: textSecondary, isDark: isDark)),
        ],
      ),
    );
  }

  Widget _buildInfoText(String text, Color color) {
    return Padding(padding: const EdgeInsets.all(20), child: Text(text, style: TextStyle(color: color)));
  }

  Widget _buildLoadingIndicator(Color color) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
          const SizedBox(width: 12),
          Text('Stockfish analyzing...', style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Color textPrimary, Color borderColor, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _copyToClipboard(_generateFen(), "FEN copied to clipboard!"),
            icon: const Icon(Icons.share, size: 16),
            label: const Text('Share PGN'),
            style: OutlinedButton.styleFrom(foregroundColor: textPrimary, side: BorderSide(color: borderColor), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _copyToClipboard(currentFen, "Position added to repertoire!"),
            icon: const Icon(Icons.library_add, size: 16),
            label: const Text('Add Repertoire'),
            style: ElevatedButton.styleFrom(backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightHeader, foregroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ),
      ],
    );
  }

  Widget _buildBoardEditor(Color surfaceColor, Color borderColor, Color textSecondary, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Board Editor (Tahta Yapıcı)', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
            IconButton(icon: const Icon(Icons.refresh, color: AppColors.primary), onPressed: _initBuilderBoard, tooltip: "Reset Board"),
          ],
        ),
        
        // YENİ EKLENDİ: FEN 'w' veya 'b' seçici toggle
        SwitchListTile(
          title: const Text("White to move (Beyazın Sırası)"),
          value: isWhiteTurn,
          activeColor: AppColors.primary,
          onChanged: (val) {
            setState(() => isWhiteTurn = val);
          },
          contentPadding: EdgeInsets.zero,
        ),

        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: AppColors.boardDark, width: 2), borderRadius: BorderRadius.circular(4)),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, childAspectRatio: 1.0),
              itemCount: 64,
              itemBuilder: (context, index) {
                int rank = index ~/ 8;
                int file = index % 8;
                bool isLightSquare = (rank + file) % 2 == 0;
                Color squareColor = isLightSquare ? AppColors.boardLight : AppColors.boardDark;
                String piece = builderBoard[index];
                return GestureDetector(
                  onTap: () => setState(() => builderBoard[index] = selectedPiece),
                  child: Container(
                    color: squareColor,
                    child: Center(
                      child: piece.isNotEmpty ? Text(_getPieceSymbol(piece), style: TextStyle(fontSize: 32, color: _isWhitePiece(piece) ? Colors.white : Colors.black)) : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
          child: Column(
            children: [
              Text("Select piece to place (Tap square to place/erase)", style: TextStyle(color: textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ['P', 'N', 'B', 'R', 'Q', 'K'].map((p) => _buildPaletteItem(p, true)).toList()),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ['p', 'n', 'b', 'r', 'q', 'k'].map((p) => _buildPaletteItem(p, false)).toList()),
              const SizedBox(height: 12),
              Divider(color: borderColor, height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPaletteItem('', false, icon: Icons.delete_outline, tooltip: "Eraser"),
                  ElevatedButton.icon(
                    onPressed: _clearBoard,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear Board'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withValues(alpha: 0.1), foregroundColor: Colors.red, elevation: 0),
                  ),
                  ElevatedButton.icon(
                    onPressed: _startAnalysis,
                    icon: const Icon(Icons.analytics, size: 16),
                    label: const Text('Analyze', style: TextStyle(color: Color(0xFF2A2118))),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0),
                  ),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildPaletteItem(String piece, bool isWhite, {IconData? icon, String? tooltip}) {
    bool isSelected = selectedPiece == piece;
    return GestureDetector(
      onTap: () => setState(() => selectedPiece = piece),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
        ),
        child: Center(
          child: icon != null 
            ? Icon(icon, color: AppColors.textPrimary(context))
            : Text(_getPieceSymbol(piece), style: TextStyle(fontSize: 24, color: isWhite ? Colors.white : Colors.black)),
        ),
      ),
    );
  }

  bool _isWhitePiece(String p) => p.isNotEmpty && p == p.toUpperCase();

  String _getPieceSymbol(String p) {
    switch (p) {
      case 'K': return '♔'; case 'Q': return '♕'; case 'R': return '♖'; case 'B': return '♗'; case 'N': return '♘'; case 'P': return '♙';
      case 'k': return '♚'; case 'q': return '♛'; case 'r': return '♜'; case 'b': return '♝'; case 'n': return '♞'; case 'p': return '♟';
      default: return '';
    }
  }
}

class _VariationRow extends StatelessWidget {
  final int rank;
  final String move;
  final String score;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _VariationRow({required this.rank, required this.move, required this.score, required this.borderColor, required this.textPrimary, required this.textSecondary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderColor))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: rank == 1 ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(6), border: rank != 1 ? Border.all(color: borderColor) : null),
              child: Text('$rank.', style: TextStyle(color: rank == 1 ? const Color(0xFF2A2118) : textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(move, style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Best continuation', style: TextStyle(color: textSecondary, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(score, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}