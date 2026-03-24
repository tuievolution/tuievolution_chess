import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/opening_node.dart';

class DataService {
  OpeningNode? root; 
  final List<String> allAvailableOpenings = [];

  Future<void> loadOpenings(String jsonUrl) async {
    try {
      final response = await http.get(Uri.parse(jsonUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        root = OpeningNode.fromJson(jsonData);
        _extractOpeningNames(root!);
      }
    } catch (e) { print("Error: $e"); }
  }

  void _extractOpeningNames(OpeningNode node) {
    if (node.openingName != null && !allAvailableOpenings.contains(node.openingName)) {
      allAvailableOpenings.add(node.openingName!);
    }
    for (var childNode in node.children.values) { _extractOpeningNames(childNode); }
  }

  // --- NEW: PATHFINDER LOGIC ---
  
  // Finds the list of moves (e.g., ["e4", "e5", "Nf3"...]) to get to a specific opening
  List<String>? findPathToOpening(OpeningNode current, String targetName, List<String> currentPath) {
    if (current.openingName == targetName) return currentPath;
    
    for (var entry in current.children.entries) {
      var result = findPathToOpening(entry.value, targetName, [...currentPath, entry.key]);
      if (result != null) return result;
    }
    return null;
  }

  Map<String, dynamic> getOpeningDataForUI(String openingName) {
    if (root == null) return {'name': openingName, 'fen': '', 'history': <String>[]};
    
    // Get the sequence of moves leading to this opening
    final history = findPathToOpening(root!, openingName, []) ?? [];
    
    // Find the actual node to get the final FEN
    OpeningNode? targetNode = _findNodeByName(root!, openingName);
    
    return {
      'name': openingName,
      'fen': targetNode?.fen ?? '',
      'history': history,
    };
  }

  OpeningNode? _findNodeByName(OpeningNode node, String name) {
    if (node.openingName == name) return node;
    for (var child in node.children.values) {
      var found = _findNodeByName(child, name);
      if (found != null) return found;
    }
    return null;
  }

  OpeningNode? _findNodeByFen(OpeningNode node, String fen) {
    if (node.fen == fen) return node;
    for (var child in node.children.values) {
      var found = _findNodeByFen(child, fen);
      if (found != null) return found;
    }
    return null;
  }

  List<Map<String, dynamic>> getNextMovesForUI(String currentFen) {
    if (root == null) return [];
    OpeningNode? currentNode = _findNodeByFen(root!, currentFen);
    if (currentNode == null) return []; 

    return currentNode.children.entries.map((e) => {
      'move': e.key,
      'name': e.value.openingName ?? 'Varyant: ${e.key}', 
      'fen': e.value.fen,
      'isCompleted': false, 
    }).toList();
  }

  String? getOpeningNameByFen(String fen) => _findNodeByFen(root!, fen)?.openingName;
}