import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import '../../core/theme.dart';

class ChessboardFixed extends StatefulWidget {
  final String fen;
  final ValueChanged<String>? onPositionChanged; // NEW: The bridge to the UI

  const ChessboardFixed({super.key, required this.fen, this.onPositionChanged});

  @override
  State<ChessboardFixed> createState() => _ChessboardFixedState();
}

class _ChessboardFixedState extends State<ChessboardFixed> {
  late ChessBoardController controller;
  
  List<String> fenHistory = []; 
  List<String> sanHistory = []; 
  int currentIndex = 0;         
  bool isNavigating = false;    
  bool isWhiteBottom = true;    

  @override
  void initState() {
    super.initState();
    controller = ChessBoardController()..loadFen(widget.fen);
    fenHistory.add(widget.fen);
    
    controller.addListener(() {
      if (isNavigating) return; 
      
      String currentFen = controller.getFen();
      if (currentFen == fenHistory[currentIndex]) return; 

      var sans = controller.getSan().whereType<String>().toList();
      if (sans.isNotEmpty) {
        String lastElement = sans.last; 
        List<String> tokens = lastElement.trim().split(RegExp(r'\s+'));
        String pureMove = tokens.last.replaceAll(RegExp(r'^\d+\.+'), '');

        fenHistory.length = currentIndex + 1;
        sanHistory.length = currentIndex;
        
        fenHistory.add(currentFen);
        sanHistory.add(pureMove);
        currentIndex++;
        
        setState(() {}); 

        // NEW: Tell the parent screen that the board position changed!
        widget.onPositionChanged?.call(currentFen);
      }
    });
  }

  void _navigate(int newIndex) {
    if (newIndex == currentIndex) return;
    
    setState(() {
      isNavigating = true; 
      currentIndex = newIndex;
      String newFen = fenHistory[currentIndex];
      controller.loadFen(newFen); 

      // NEW: Tell the parent screen we traveled through time!
      widget.onPositionChanged?.call(newFen);
    });
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) isNavigating = false;
    });
  }

  void _goToStart() => _navigate(0);
  void _stepBackward() => _navigate(currentIndex > 0 ? currentIndex - 1 : 0);
  void _stepForward() => _navigate(currentIndex < fenHistory.length - 1 ? currentIndex + 1 : fenHistory.length - 1);
  void _goToEnd() => _navigate(fenHistory.length - 1);

  List<Widget> _buildNotation() {
    List<Widget> widgets = [];
    for (int i = 0; i < sanHistory.length; i++) {
      if (i % 2 == 0) {
        widgets.add(Text('${(i ~/ 2) + 1}. ', style: const TextStyle(color: AppColors.woodBrown, fontWeight: FontWeight.bold)));
      }
      
      bool isCurrentMove = (i == currentIndex - 1);
      
      widgets.add(
        InkWell(
          onTap: () => _navigate(i + 1), 
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
            child: Text(
              '${sanHistory[i]} ',
              style: TextStyle(
                color: isCurrentMove ? AppColors.activeGreen : AppColors.textDark,
                fontWeight: isCurrentMove ? FontWeight.w900 : FontWeight.w500,
                fontSize: 16,
              )
            ),
          ),
        )
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600), 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 2)),
              child: ChessBoard(
                controller: controller,
                boardColor: BoardColor.brown,
                boardOrientation: isWhiteBottom ? PlayerColor.white : PlayerColor.black,
              ),
            ),
          ),
          Container(
            color: AppColors.woodBrown,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(icon: const Icon(Icons.flip_camera_android, color: Colors.white), tooltip: 'Tahtayı Döndür', onPressed: () => setState(() => isWhiteBottom = !isWhiteBottom)),
                IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white, size: 28), tooltip: 'Başlangıca Dön', onPressed: _goToStart),
                IconButton(icon: const Icon(Icons.navigate_before, color: Colors.white, size: 32), tooltip: 'Önceki Hamle', onPressed: _stepBackward),
                IconButton(icon: const Icon(Icons.navigate_next, color: Colors.white, size: 32), tooltip: 'Sonraki Hamle', onPressed: _stepForward),
                IconButton(icon: const Icon(Icons.skip_next, color: Colors.white, size: 28), tooltip: 'Sona Git', onPressed: _goToEnd),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: 120, 
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.background, 
              border: Border(left: BorderSide(color: AppColors.border, width: 2), right: BorderSide(color: AppColors.border, width: 2), bottom: BorderSide(color: AppColors.border, width: 2)),
            ),
            child: SingleChildScrollView(
              child: sanHistory.isEmpty 
                ? const Text('Henüz hamle yapılmadı...', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                : Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: _buildNotation()),
            ),
          ),
        ],
      ),
    );
  }
}