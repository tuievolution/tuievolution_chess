import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import '../../core/theme.dart';

class ChessboardFixed extends StatefulWidget {
  final String fen;
  const ChessboardFixed({super.key, required this.fen});

  @override
  State<ChessboardFixed> createState() => _ChessboardFixedState();
}

class _ChessboardFixedState extends State<ChessboardFixed> {
  late ChessBoardController controller;
  
  // AKILLI HAFIZA (ZAMAN MAKİNESİ) SİSTEMİ
  List<String> fenHistory = []; // Hamlelerin tahta konumları (FEN)
  List<String> sanHistory = []; // Oynanan saf hamle metinleri (Örn: e4, Nf3)
  int currentIndex = 0;         // Şu an hafızanın neresinde olduğumuzu tutar
  bool isNavigating = false;    // Butonlarla gezinirken sahte hamle algılanmasını önler
  
  bool isWhiteBottom = true;    // Tahtanın yönü

  @override
  void initState() {
    super.initState();
    controller = ChessBoardController()..loadFen(widget.fen);
    
    // Başlangıç konumunu hafızaya al
    fenHistory.add(widget.fen);
    
    // Tahtadaki hareketleri dinle
    controller.addListener(() {
      if (isNavigating) return; // Eğer biz butonla ileri/geri yapıyorsak kaydetme
      
      String currentFen = controller.getFen();
      if (currentFen == fenHistory[currentIndex]) return; // Konum değişmediyse çık

      // Kullanıcı tahtada YENİ bir hamle yaptı!
      var sans = controller.getSan().whereType<String>().toList();
      if (sans.isNotEmpty) {
        // Gelen karmaşık metinden sadece son hamleyi (Örn: "1. d4 d5" içinden "d5"i) süzüyoruz
        String lastElement = sans.last; 
        List<String> tokens = lastElement.trim().split(RegExp(r'\s+'));
        // Eğer başında "1." veya "1..." gibi sayılar varsa temizle
        String pureMove = tokens.last.replaceAll(RegExp(r'^\d+\.+'), '');

        // Eğer kullanıcı geçmişe gidip YENİ bir hamle (Varyant) yaparsa, o andan sonraki geleceği sil
        fenHistory.length = currentIndex + 1;
        sanHistory.length = currentIndex;
        
        // Tertemiz yeni hamleyi hafızaya ekle
        fenHistory.add(currentFen);
        sanHistory.add(pureMove);
        currentIndex++;
        
        setState(() {}); // Arayüzü güncelle
      }
    });
  }

  // --- YÖNLENDİRME (NAVİGASYON) BUTONLARI İÇİN FONKSİYONLAR ---
  void _navigate(int newIndex) {
    if (newIndex == currentIndex) return;
    
    setState(() {
      isNavigating = true; // Dinleyiciyi geçici olarak sustur (Yeni hamle sanmasın)
      currentIndex = newIndex;
      controller.loadFen(fenHistory[currentIndex]); // Hafızadaki konumu yükle
    });
    
    // Tahta yüklendikten sonra dinleyiciyi tekrar aç
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) isNavigating = false;
    });
  }

  void _goToStart() => _navigate(0);
  void _stepBackward() => _navigate(currentIndex > 0 ? currentIndex - 1 : 0);
  void _stepForward() => _navigate(currentIndex < fenHistory.length - 1 ? currentIndex + 1 : fenHistory.length - 1);
  void _goToEnd() => _navigate(fenHistory.length - 1);

  // --- NOTASYON PANELİ ÇİZİMİ ---
  List<Widget> _buildNotation() {
    List<Widget> widgets = [];
    for (int i = 0; i < sanHistory.length; i++) {
      
      // Her beyaz hamlesinde sayı ekle (1. , 2. vb.)
      if (i % 2 == 0) {
        widgets.add(
          Text('${(i ~/ 2) + 1}. ', style: const TextStyle(color: AppColors.woodBrown, fontWeight: FontWeight.bold))
        );
      }
      
      // Bu hamle şu an ekranda gösterilen aktif hamle mi?
      bool isCurrentMove = (i == currentIndex - 1);
      
      widgets.add(
        InkWell(
          // BONUS UX: Kullanıcı notasyondaki hamleye tıklayarak o ana zıplayabilir!
          onTap: () => _navigate(i + 1), 
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
            child: Text(
              '${sanHistory[i]} ',
              style: TextStyle(
                // Aktif hamleyi Koyu Yeşil ve Kalın yap
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
      constraints: const BoxConstraints(maxWidth: 600), // Tahta Genişliği
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Satranç Tahtası
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
          
          // 2. Kontrol Butonları (Hafızada Gezinir)
          Container(
            color: AppColors.woodBrown,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton( // Döndür
                  icon: const Icon(Icons.flip_camera_android, color: Colors.white),
                  tooltip: 'Tahtayı Döndür',
                  onPressed: () => setState(() => isWhiteBottom = !isWhiteBottom),
                ),
                IconButton( // Başa Dön
                  icon: const Icon(Icons.skip_previous, color: Colors.white, size: 28),
                  tooltip: 'Başlangıca Dön',
                  onPressed: _goToStart,
                ),
                IconButton( // Bir Geri
                  icon: const Icon(Icons.navigate_before, color: Colors.white, size: 32),
                  tooltip: 'Önceki Hamle',
                  onPressed: _stepBackward,
                ),
                IconButton( // Bir İleri
                  icon: const Icon(Icons.navigate_next, color: Colors.white, size: 32),
                  tooltip: 'Sonraki Hamle',
                  onPressed: _stepForward,
                ),
                IconButton( // Sona Git
                  icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
                  tooltip: 'Sona Git',
                  onPressed: _goToEnd,
                ),
              ],
            ),
          ),

          // 3. Notasyon Paneli
          Container(
            width: double.infinity,
            height: 120, 
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.background, 
              border: Border(
                left: BorderSide(color: AppColors.border, width: 2),
                right: BorderSide(color: AppColors.border, width: 2),
                bottom: BorderSide(color: AppColors.border, width: 2),
              ),
            ),
            child: SingleChildScrollView(
              child: sanHistory.isEmpty 
                ? const Text('Henüz hamle yapılmadı...', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                : Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: _buildNotation(),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}