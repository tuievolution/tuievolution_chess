class OpeningNode {
  final String move;
  final String fen;
  final String? openingName;
  final Map<String, OpeningNode> children;

  OpeningNode({
    required this.move,
    required this.fen,
    this.openingName,
    required this.children,
  });

  // This factory recursively builds the entire tree instantly from the JSON
  factory OpeningNode.fromJson(Map<String, dynamic> json) {
    Map<String, OpeningNode> parsedChildren = {};
    
    if (json['children'] != null) {
      final Map<String, dynamic> childrenJson = json['children'];
      childrenJson.forEach((key, value) {
        parsedChildren[key] = OpeningNode.fromJson(value);
      });
    }

    return OpeningNode(
      move: json['move'] as String,
      fen: json['fen'] as String,
      openingName: json['openingName'] as String?,
      children: parsedChildren,
    );
  }
}