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
  
  late String currentFen;
  late String originalOpeningName;
  late List<String> initialHistory; 

  String? engineBestMove;
  bool isEngineThinking = false;
  Timer? _engineTimeout;

  // ÖĞRENME MODU DEĞİŞKENLERİ
  bool isPracticeMode = false;
  int practiceIndex = 0;
  bool isAppPlaying = false;
  String practiceColor = 'w'; 

  @override
  void initState() {
    super.initState();
    final openingData = dataService.getOpeningDataForUI(widget.openingName);
    currentFen = openingData['fen'];
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

  // ANTRENMAN MODUNU BAŞLAT
  void _startPractice(String color) {
    setState(() {
      isPracticeMode = true;
      practiceIndex = 0;
      practiceColor = color;
      engineBestMove = null;
    });
    _boardKey.currentState?.resetBoard();

    // Siyah seçildiyse beyazın (yapay zeka) ilk hamlesini yapmasını sağla
    if (color == 'b' && initialHistory.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), _playExpectedMove);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlk hamleyi sen yap!'), backgroundColor: AppColors.primaryDark),
      );
    }
  }

  // UYGULAMANIN RAKİP HAMLEYİ OYNAMASI
  void _playExpectedMove() {
    if (practiceIndex >= initialHistory.length) return;
    setState(() => isAppPlaying = true);
    String expectedSan = initialHistory[practiceIndex];
    _boardKey.currentState?.makeMoveWithSan(expectedSan);
    // Hamle yapıldığında _onBoardPositionChanged tetiklenecek ve indexi artıracak.
  }

  // AÇILIŞ ÖĞRENİLDİĞİNDE ÇALIŞIR
  void _showSuccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('Tebrikler!', style: TextStyle(color: AppColors.primary)),
          ],
        ),
        content: Text('Açılışı başarıyla tamamladınız. İlerlemeniz kaydedildi.', style: TextStyle(color: AppColors.textPrimary(context))),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                isPracticeMode = false;
              });
            },
            child: const Text('Kapat', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // OYUN DÖNGÜSÜ: Hem normal motor analizi, hem de antrenman modu doğrulaması
  void _onBoardPositionChanged(String newFen) {
    if (isPracticeMode) {
      final sanList = _boardKey.currentState?.sanHistory ?? [];
      if (sanList.isEmpty) return;

      String lastSan = sanList.last;
      String expectedSan = initialHistory[practiceIndex];

      // Uygulama (Rakip) oynadıysa sadece indexi artır
      if (isAppPlaying) {
        setState(() {
          isAppPlaying = false;
          practiceIndex++;
        });
        if (practiceIndex >= initialHistory.length) _showSuccess();
        return;
      }

      // Kullanıcı Oynadıysa Doğrula
      if (lastSan == expectedSan) {
        // DOĞRU HAMLE!
        setState(() { practiceIndex++; });
        if (practiceIndex >= initialHistory.length) {
          _showSuccess();
        } else {
          // Rakip (Uygulama) sıradaki hamleyi oynar
          Future.delayed(const Duration(milliseconds: 600), _playExpectedMove);
        }
      } else {
        // YANLIŞ HAMLE! Geri al ve uyar.
        _boardKey.currentState?.undoMove();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hatalı hamle! Beklenen: $expectedSan'), backgroundColor: Colors.red),
        );
      }
      return; // Öğrenme modundaysak aşağıya inip motoru yorma
    }

    // NORMAL İNCELEME MODU (Öğrenme modu kapalıysa)
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
      appBar: AppBar(
        title: Text(originalOpeningName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView( 
          padding: const EdgeInsets.all(24.0),
          child: Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                    // Öğrenme modu aktif değilse tüm açılış adımlarını anında yükle
                    initialMoves: isPracticeMode ? [] : initialHistory, 
                    isWhiteBottom: practiceColor == 'w', 
                    onPositionChanged: _onBoardPositionChanged, 
                  ),
                ],
              ),
              
              SizedBox(width: isDesktop ? 32 : 0, height: isDesktop ? 32 : 32),

              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 400 : 500), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // ÖĞRENME MODU KONTROLLERİ (YENİ)
                    if (!isPracticeMode)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Bu Açılışı Çalış (Practice Mode)', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('Açılış teorisini ezberlemek için etkileşimli eğitime başlayın.', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.surface(context), foregroundColor: AppColors.textPrimary(context)),
                                    onPressed: () => _startPractice('w'),
                                    child: const Text('Beyaz ile Oyna'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white),
                                    onPressed: () => _startPractice('b'),
                                    child: const Text('Siyah ile Oyna'),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      
                    if (isPracticeMode)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Eğitim Modu Aktif', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('İlerleme: ${practiceIndex} / ${initialHistory.length}', style: TextStyle(color: AppColors.textPrimary(context))),
                              ],
                            ),
                            TextButton(
                              onPressed: () => setState(() => isPracticeMode = false),
                              child: const Text('Bitir', style: TextStyle(color: Colors.red)),
                            )
                          ],
                        ),
                      ),

                    GrowCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(displayTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bu açılışın ${initialHistory.length} hamlelik temel teorisini tamamlayarak ustalık kazan.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('MASTERY PROGRESS', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary)),
                              Text('0%', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textPrimary(context))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const GrowProgressBar(progress: 0.0),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    if (!isPracticeMode)
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
                                        Expanded(child: Text(moveData['move'], style: TextStyle(color: moveData["isCompleted"] ? AppColors.primary : AppColors.textPrimary(context), fontWeight: FontWeight.bold))),
                                        Expanded(child: Text(moveData["name"].split(' ').first, style: TextStyle(color: AppColors.textPrimary(context)))),
                                        if (moveData["isCompleted"]) const Icon(Icons.check_circle, color: AppColors.primary, size: 16)
                                        else Icon(Icons.radio_button_unchecked, color: AppColors.textSecondary(context), size: 16),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                            
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
                                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                                    else
                                      Text('Analysis Mode', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              if (!isEngineThinking && engineBestMove != null)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border(context)))),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
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
                            ],
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