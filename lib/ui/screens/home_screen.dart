import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../main.dart';
import '../components/chessboard_fixed.dart';
import 'tree_screen.dart';
import 'openings_list_screen.dart';
import '../../services/stockfish_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ChessboardFixedState> _boardKey = GlobalKey<ChessboardFixedState>();

  String searchQuery = '';
  String currentFen = AppConstants.startingFen;
  bool isEngineEnabled = true;
  bool isPlayingVsEngine = false; 
  String userColor = 'w'; // 'w' (Beyaz) veya 'b' (Siyah)
  
  List<EngineVariation> engineVariations = [];
  bool isEngineThinking = false;
  String? currentOpeningName;
  Timer? _engineTimeout;

  @override
  void initState() {
    super.initState();

    stockfishService.onEngineInfo = (variations) {
      if (mounted) {
        _engineTimeout?.cancel();
        setState(() {
          engineVariations = variations;
          isEngineThinking = false;
        });
      }
    };
    
    // KUSURSUZ OYUN DÖNGÜSÜ: Motor hamleyi bulduğunda sıranın gerçekten kendisinde olduğunu teyit eder ve oynar.
    stockfishService.onBestMoveFound = (uciMove) {
      if (mounted && isPlayingVsEngine) {
         String currentTurn = currentFen.split(' ')[1];
         bool isEngineTurn = (currentTurn == 'w' && userColor == 'b') || (currentTurn == 'b' && userColor == 'w');
         
         if (isEngineTurn) {
            _boardKey.currentState?.makeEngineMove(uciMove);
         }
      }
    };

    stockfishService.onError = (err) {
      if (mounted) {
        _engineTimeout?.cancel();
        setState(() => isEngineThinking = false);
      }
    };

    if (isEngineEnabled) _requestEngineMove(AppConstants.startingFen);
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
    _engineTimeout = Timer(const Duration(seconds: 5), () {
      if (mounted && isEngineThinking) {
        setState(() => isEngineThinking = false);
      }
    });
  }

  void _onBoardPositionChanged(String newFen) {
    setState(() {
      currentFen = newFen;
      currentOpeningName = dataService.getOpeningNameByFen(newFen);
      engineVariations = [];
    });
    
    String currentTurn = newFen.split(' ')[1]; // 'w' veya 'b'
    bool isEngineTurn = (currentTurn == 'w' && userColor == 'b') || (currentTurn == 'b' && userColor == 'w');

    if (isPlayingVsEngine) {
      if (isEngineTurn) {
        _requestEngineMove(newFen); 
      }
    } else {
      _requestEngineMove(newFen); 
    }
  }

  void _resetGame() {
    _boardKey.currentState?.resetBoard();
    setState(() {
      currentFen = AppConstants.startingFen;
      currentOpeningName = null;
      engineVariations = [];
    });
    
    // Kullanıcı Siyah seçtiyse Stockfish oyunu Beyaz olarak başlatır
    if (isPlayingVsEngine && userColor == 'b') {
      _requestEngineMove(AppConstants.startingFen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = AppColors.surface(context);
    final borderColor = AppColors.border(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);

    final generalsOpenings = dataService.allAvailableOpenings;
    final filteredOpenings = generalsOpenings
        .where((o) => o.toLowerCase().contains(searchQuery.toLowerCase()))
        .take(5)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (currentOpeningName != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.eco, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentOpeningName!,
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

            // OYUN MODU VE RENK SEÇİCİ
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Play vs Stockfish', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(isPlayingVsEngine ? 'Game Match Active' : 'Analysis Mode Only', style: const TextStyle(fontSize: 12)),
                    value: isPlayingVsEngine,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        isPlayingVsEngine = val;
                      });
                      _resetGame();
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (isPlayingVsEngine) ...[
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Your Color (Renginiz):', style: TextStyle(fontWeight: FontWeight.w600)),
                        DropdownButton<String>(
                          value: userColor,
                          dropdownColor: surfaceColor,
                          items: const [
                            DropdownMenuItem(value: 'w', child: Text('White (Beyaz)')),
                            DropdownMenuItem(value: 'b', child: Text('Black (Siyah)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                userColor = val;
                              });
                              _resetGame();
                            }
                          },
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),

            ChessboardFixed(
              key: _boardKey,
              startingFen: AppConstants.startingFen,
              initialEngineState: isEngineEnabled,
              isWhiteBottom: userColor == 'w', 
              onEngineToggled: (enabled) {
                setState(() => isEngineEnabled = enabled);
                _requestEngineMove(currentFen);
              },
              onPositionChanged: _onBoardPositionChanged,
            ),

            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.memory, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text('Best Move', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                        ),
                        child: const Text('Stockfish 8', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isEngineThinking)
                    Row(
                      children: [
                        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                        const SizedBox(width: 10),
                        Text('Calculating...', style: TextStyle(color: textSecondary, fontSize: 13)),
                      ],
                    )
                  else if (!isEngineEnabled)
                    Text('Engine is turned off.', style: TextStyle(color: textSecondary, fontSize: 13))
                  else if (engineVariations.isNotEmpty)
                    Column(
                      children: engineVariations.map((v) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: v.rank == 1 ? AppColors.primary : AppColors.bg(context),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary.withValues(alpha: v.rank == 1 ? 1 : 0.3)),
                              ),
                              child: Text(
                                v.uciMove,
                                style: TextStyle(
                                  color: v.rank == 1 ? const Color(0xFF2A2118) : AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: v.rank == 1 ? 18 : 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('Eval: ${v.score}', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      )).toList(),
                    )
                  else
                    Text('Make a move to see suggestions', style: TextStyle(color: textSecondary, fontSize: 13)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Search openings...',
                hintStyle: TextStyle(color: textSecondary),
                prefixIcon: Icon(Icons.search, color: textSecondary),
              ),
            ),
            const SizedBox(height: 12),

            if (filteredOpenings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No openings found', style: TextStyle(color: textSecondary)),
              ),

            ...filteredOpenings.map((name) => _OpeningTile(
              name: name,
              isCompleted: false,
              borderColor: borderColor,
              surfaceColor: surfaceColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TreeScreen(openingName: name)),
              ),
            )),

            const SizedBox(height: 8),

            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OpeningsListScreen()),
              ),
              child: const Text('View All Openings →', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpeningTile extends StatelessWidget {
  final String name;
  final bool isCompleted;
  final Color borderColor;
  final Color surfaceColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  const _OpeningTile({
    required this.name,
    required this.isCompleted,
    required this.borderColor,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isCompleted ? AppColors.primary.withValues(alpha: 0.4) : borderColor),
        ),
        child: Row(
          children: [
            Icon(isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, color: isCompleted ? AppColors.primary : textSecondary, size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14))),
            Icon(Icons.chevron_right, color: textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}