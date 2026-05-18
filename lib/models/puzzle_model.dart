class PuzzleModel {
  final String id;
  final String fen;
  final List<String> moves;
  final int rating;
  final List<String> themes;

  PuzzleModel({
    required this.id,
    required this.fen,
    required this.moves,
    required this.rating,
    required this.themes,
  });

  factory PuzzleModel.fromJson(Map<String, dynamic> json) {
    // Supabase'den gelen moves metnini boşluklara göre ayırıp listeye çeviriyoruz
    List<String> movesList = [];
    if (json['Moves'] != null && json['Moves'] is String) {
      movesList = (json['Moves'] as String).trim().split(RegExp(r'\s+'));
    }

    // Temaları virgülle ayrılmış metinden listeye çeviriyoruz
    List<String> themesList = [];
    if (json['Themes'] != null && json['Themes'] is String) {
      themesList = (json['Themes'] as String)
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return PuzzleModel(
      id: json['PuzzleId']?.toString() ?? '',
      fen: json['FEN']?.toString() ?? '',
      moves: movesList,
      rating: json['Rating'] is int ? json['Rating'] : (int.tryParse(json['Rating']?.toString() ?? '') ?? 1000),
      themes: themesList,
    );
  }
}