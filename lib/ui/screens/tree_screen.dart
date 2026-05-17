import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme.dart';
import '../../core/constants.dart'; 
import '../components/chessboard_fixed.dart';
import '../../main.dart'; 
import '../widgets/grow_card.dart';
import '../widgets/grow_progress_bar.dart';

class TreeScreen extends StatefulWidget {
  final String openingName;
  const TreeScreen({super.key, required this.openingName});

  @override
  State<TreeScreen> createState() => _TreeScreenState();
}

class _TreeScreenState extends State<TreeScreen> {
  final GlobalKey<ChessboardFixedState> _boardKey = GlobalKey<ChessboardFixedState>();
  
  late String initialFen;
  late String currentFen;
  late String originalOpeningName;
  late List<String> initialHistory; 

  String? engineBestMove;
  bool isEngineThinking = false;
  Timer? _engineTimeout;

  @override
  void initState() {
    super.initState();
    final openingData = dataService.getOpeningDataForUI(widget.openingName);
    initialFen = openingData['fen'];
    currentFen = initialFen;
    originalOpeningName = openingData['name'];
    initialHistory = List<String>.from(openingData['history'] ?? []);

    stockfishService.onBestMoveFound = (uciMove) {
      if (mounted) {
        _engineTimeout?.cancel();
        setState(() {
          engineBestMove = uciMove;
          isEngineThinking = false;
        });
      }
    };

    stockfishService.onError = (errorMsg) {
      if (mounted) {
        _engineTimeout?.cancel();
        setState(() {
          engineBestMove = errorMsg;
          isEngineThinking = false;
        });
      }
    };
  }

  @override
  void dispose() {
    _engineTimeout?.cancel();
    super.dispose();
  }

  void _onBoardPositionChanged(String newFen) {
    setState(() {
      currentFen = newFen;
      engineBestMove = null; 
    });

    final nextMoves = dataService.getNextMovesForUI(newFen);
    
    if (nextMoves.isEmpty) {
      setState(() => isEngineThinking = true);
      stockfishService.calculateBestMove(newFen);

      _engineTimeout?.cancel();
      _engineTimeout = Timer(const Duration(seconds: 3), () {
        if (mounted && isEngineThinking) {
          setState(() {
            isEngineThinking = false;
            engineBestMove = "Engine unavailable";
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> nextMoves = dataService.getNextMovesForUI(currentFen);
    int plyCount = _boardKey.currentState?.currentPlyCount ?? 0;
    String? currentPositionName = dataService.getOpeningNameByFen(currentFen);
    
    String displayTitle = originalOpeningName;
    if (plyCount >= 6 && currentPositionName != null) {
      displayTitle = currentPositionName;
    } else if (plyCount > 0) {
      displayTitle = "$originalOpeningName (Variation)";
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Center(
        child: SingleChildScrollView( 
          padding: const EdgeInsets.all(24.0),
          child: Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              // 1. LEFT SIDE (Chessboard)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDesktop) ...[
                    Text('Dashboard / $originalOpeningName', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                  ],
                  ChessboardFixed(
                    key: _boardKey, 
                    startingFen: AppConstants.startingFen, 
                    initialMoves: initialHistory, 
                    onPositionChanged: _onBoardPositionChanged, 
                  ),
                ],
              ),
              
              SizedBox(width: isDesktop ? 32 : 0, height: isDesktop ? 0 : 32),

              // 2. RIGHT SIDE (Panels)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 400 : 500), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mastery Progress Card
                    GrowCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(displayTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'The most popular and best-scoring response. It creates an asymmetrical position and leads to complex, sharp play.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('MASTERY PROGRESS', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary)),
                              Text('68%', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textPrimary(context))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const GrowProgressBar(progress: 0.68),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.bg(context),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('TOTAL MOVES', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary(context), fontSize: 10)),
                                      const SizedBox(height: 4),
                                      Text('24', style: Theme.of(context).textTheme.titleLarge),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.bg(context),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('VARIATIONS', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary(context), fontSize: 10)),
                                      const SizedBox(height: 4),
                                      Text('12', style: Theme.of(context).textTheme.titleLarge),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Move Tree / Engine Card
                    GrowCard(
                      padding: const EdgeInsets.all(0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Move Tree', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                                Icon(Icons.settings, color: AppColors.textSecondary(context), size: 16),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: AppColors.border(context)),
                          
                          // If we have moves in dataset
                          if (nextMoves.isNotEmpty) ...[
                            ...nextMoves.map((moveData) {
                              return InkWell(
                                onTap: () => _boardKey.currentState?.makeMoveFromExternal(moveData['move'], moveData['fen']),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: moveData["isCompleted"] ? AppColors.primaryDark.withValues(alpha:0.3) : Colors.transparent,
                                    border: Border(bottom: BorderSide(color: AppColors.border(context))),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 24, child: Text('${plyCount ~/ 2 + 1}', style: TextStyle(color: AppColors.textSecondary(context)))),
                                      Expanded(
                                        child: Text(moveData['move'], style: TextStyle(color: moveData["isCompleted"] ? AppColors.primary : AppColors.textPrimary(context), fontWeight: FontWeight.bold)),
                                      ),
                                      Expanded(
                                        child: Text(moveData["name"].split(' ').first, style: TextStyle(color: AppColors.textPrimary(context))),
                                      ),
                                      if (moveData["isCompleted"]) const Icon(Icons.check_circle, color: AppColors.primary, size: 16)
                                      else Icon(Icons.radio_button_unchecked, color: AppColors.textSecondary(context), size: 16),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                          
                          // Stockfish Evaluation
                          if (nextMoves.isEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: AppColors.bg(context).withValues(alpha:0.5),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.memory, color: AppColors.primary, size: 20),
                                      const SizedBox(width: 8),
                                      Text('ENGINE ANALYSIS', style: Theme.of(context).textTheme.labelSmall),
                                    ],
                                  ),
                                  if (isEngineThinking)
                                    const SizedBox(
                                      width: 16, height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                    )
                                  else
                                    Text('+0.4', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary, fontSize: 14)),
                                ],
                              ),
                            ),
                            if (!isEngineThinking && engineBestMove != null)
                              InkWell(
                                onTap: () {
                                  // Just a visual representation for now. Actual implementation would parse UCI and apply.
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: AppColors.border(context))),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text('1', style: TextStyle(color: AppColors.bg(context), fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(engineBestMove ?? '', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                                            Text('Deep preparation recommended', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right, color: AppColors.textSecondary(context)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                          
                          // Bottom Input Note
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    style: TextStyle(color: AppColors.textPrimary(context)),
                                    decoration: InputDecoration(
                                      hintText: 'Add engine note...',
                                      hintStyle: TextStyle(color: AppColors.textSecondary(context)),
                                      filled: true,
                                      fillColor: AppColors.bg(context),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.add, color: AppColors.bg(context)),
                                    onPressed: () {},
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}