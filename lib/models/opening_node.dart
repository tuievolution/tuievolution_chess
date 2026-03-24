class OpeningNode {
  final String move;
  final String fen;
  final String? openingName; // Nullable string (notice the '?')
  final Map<String, OpeningNode> children = {};

  OpeningNode({
    required this.move,
    required this.fen,
    this.openingName,
  });
}