import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/opening_node.dart';

class DataService {
  OpeningNode? root; 
  final List<String> allAvailableOpenings = [];

  Future<void> loadOpenings(String jsonUrl) async {
    print("Fetching pre-computed tree from the cloud...");
    try {
      final response = await http.get(Uri.parse(jsonUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        root = OpeningNode.fromJson(jsonData);
        _extractOpeningNames(root!);
        print("Success! Tree loaded into memory instantly.");
      } else {
        print("Failed to fetch tree: ${response.statusCode}");
      }
    } catch (e) {
      print("Network/Parsing Error: $e");
    }
  }

  void _extractOpeningNames(OpeningNode node) {
    if (node.openingName != null && !allAvailableOpenings.contains(node.openingName)) {
      allAvailableOpenings.add(node.openingName!);
    }
    for (var childNode in node.children.values) {
      _extractOpeningNames(childNode);
    }
  }

  String? identifyOpening(List<String> playedMoves) {
    if (root == null) return null;
    OpeningNode current = root!;
    for (String move in playedMoves) {
      if (current.children.containsKey(move)) {
        current = current.children[move]!;
      } else {
        return null; 
      }
    }
    return current.openingName; 
  }

  // --- UI BRIDGE METHODS ---

  OpeningNode? _findNodeByName(OpeningNode node, String name) {
    if (node.openingName == name) return node;
    for (var child in node.children.values) {
      var found = _findNodeByName(child, name);
      if (found != null) return found;
    }
    return null;
  }

  // Recursive search to find exactly where we are on the board
  OpeningNode? _findNodeByFen(OpeningNode node, String fen) {
    if (node.fen == fen) return node;
    for (var child in node.children.values) {
      var found = _findNodeByFen(child, fen);
      if (found != null) return found;
    }
    return null;
  }

  Map<String, dynamic> getOpeningDataForUI(String openingName) {
    if (root == null) return {'name': openingName, 'fen': '', 'variants': []};
    OpeningNode? targetNode = _findNodeByName(root!, openingName);
    if (targetNode == null) return {'name': openingName, 'fen': root!.fen, 'variants': []};

    return {
      'name': openingName,
      'fen': targetNode.fen,
      // We no longer need to map variants here, the dynamic function below handles it!
    };
  }

  // NEW: Gets ONLY the next possible moves based on the current board FEN
  List<Map<String, dynamic>> getNextMovesForUI(String currentFen) {
    if (root == null) return [];
    
    OpeningNode? currentNode = _findNodeByFen(root!, currentFen);
    if (currentNode == null) return []; // Reached the end of the tree or made an invalid move

    List<Map<String, dynamic>> nextMoves = [];
    currentNode.children.forEach((moveStr, childNode) {
      nextMoves.add({
        'move': moveStr, // e.g. 'e4'
        'name': childNode.openingName ?? moveStr, // Show opening name if it exists, otherwise show move
        'fen': childNode.fen,
        'isCompleted': false, 
      });
    });

    return nextMoves;
  }
}