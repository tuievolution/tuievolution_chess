import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/opening_node.dart';

class DataService {
  OpeningNode? root; 
  final List<String> allAvailableOpenings = [];

  // EXPLANATION: This method is called in main.dart. It fetches the JSON from the cloud.
  // We keep this asynchronous because network requests take time and we don't want to freeze the UI.
  Future<void> loadOpenings(String jsonUrl) async {
    try {
      final response = await http.get(Uri.parse(jsonUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        
        // This is where it usually fails if the JSON is formatted incorrectly.
        root = OpeningNode.fromJson(jsonData); 
        _extractOpeningNames(root!);
        
        print("✅ Openings loaded successfully. Total found: ${allAvailableOpenings.length}");
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
      }
    } catch (e, stacktrace) { 
      // NEW: Added stacktrace so you can see exactly which line of the JSON parsing failed.
      print("❌ Openings Parsing Error: $e"); 
      print(stacktrace);
    }
  }

  // EXPLANATION: Recursively walks through the node tree to find all named openings 
  // so they can be displayed in the search bar on the HomeScreen.
  void _extractOpeningNames(OpeningNode node) {
    if (node.openingName != null && !allAvailableOpenings.contains(node.openingName)) {
      allAvailableOpenings.add(node.openingName!);
    }
    for (var childNode in node.children.values) { 
      _extractOpeningNames(childNode); 
    }
  }

  // --- SMART FEN NORMALIZATION ---
  // WHY WE KEPT THIS: FEN strings contain half-move clocks and en-passant targets.
  // If a user reaches the same board position via a different move order, standard FENs won't match.
  // By stripping everything after the 3rd space, we only compare piece placement, turn, and castling rights.
  String _normalizeFen(String fen) {
    final parts = fen.split(' ');
    if (parts.length >= 3) {
      return "${parts[0]} ${parts[1]} ${parts[2]}"; 
    }
    return fen;
  }

  OpeningNode? _findNodeByFen(OpeningNode node, String fen) {
    if (_normalizeFen(node.fen) == _normalizeFen(fen)) return node;
    for (var child in node.children.values) {
      var found = _findNodeByFen(child, fen);
      if (found != null) return found;
    }
    return null;
  }

  // Fetch next possible moves based on the current board state.
  List<Map<String, dynamic>> getNextMovesForUI(String currentFen) {
    if (root == null) return [];
    OpeningNode? currentNode = _findNodeByFen(root!, currentFen);
    if (currentNode == null) return []; 

    return currentNode.children.entries.map((e) => {
      'move': e.key,
      'name': e.value.openingName ?? 'Variant: ${e.key}', 
      'fen': e.value.fen,
      'isCompleted': false, 
    }).toList();
  }
  String? getOpeningNameByFen(String fen) => _findNodeByFen(root!, fen)?.openingName;

  Map<String, dynamic> getOpeningDataForUI(String openingName) {
    if (root == null) return {'name': openingName, 'fen': '', 'history': <String>[]};
    final history = findPathToOpening(root!, openingName, []) ?? [];
    OpeningNode? targetNode = _findNodeByName(root!, openingName);
    return {
      'name': openingName,
      'fen': targetNode?.fen ?? '',
      'history': history,
    };
  }

  List<String>? findPathToOpening(OpeningNode current, String targetName, List<String> currentPath) {
    if (current.openingName == targetName) return currentPath;
    for (var entry in current.children.entries) {
      var result = findPathToOpening(entry.value, targetName, [...currentPath, entry.key]);
      if (result != null) return result;
    }
    return null;
  }

  OpeningNode? _findNodeByName(OpeningNode node, String name) {
    if (node.openingName == name) return node;
    for (var child in node.children.values) {
      var found = _findNodeByName(child, name);
      if (found != null) return found;
    }
    return null;
  }
}
