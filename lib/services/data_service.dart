import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/opening_node.dart';
import '../core/constants.dart';

class DataService {
  OpeningNode? root; 
  final Set<String> _uniqueOpenings = {}; 

  List<String> get allAvailableOpenings => _uniqueOpenings.toList()..sort();

  Future<void> loadOpenings(String jsonUrl) async {
    try {
      final response = await http.get(Uri.parse(jsonUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        root = OpeningNode.fromJson(jsonData);
        _extractOpeningNames(root!);
      }
    } catch (e) { print("Error loading openings: $e"); }
  }

  void _extractOpeningNames(OpeningNode node) {
    if (node.openingName != null) {
      _uniqueOpenings.add(node.openingName!);
      _uniqueOpenings.add(node.openingName!.split(',').first.trim());
    }
    for (var childNode in node.children.values) { _extractOpeningNames(childNode); }
  }

  List<String>? findPathToOpening(OpeningNode current, String targetName, List<String> currentPath) {
    if (current.openingName == targetName) return currentPath;
    for (var entry in current.children.entries) {
      var result = findPathToOpening(entry.value, targetName, [...currentPath, entry.key]);
      if (result != null) return result;
    }
    return null;
  }

  Map<String, dynamic> getOpeningDataForUI(String searchName) {
    if (root == null) return {'name': searchName, 'fen': AppConstants.startingFen, 'history': <String>[]};
    
    OpeningNode? targetNode = _findNodeByName(root!, searchName);
    if (targetNode != null) {
      final history = findPathToOpening(root!, searchName, []) ?? [];
      return {
        'name': searchName,
        'fen': targetNode.fen,
        'history': history,
      };
    }

    return {
      'name': searchName,
      'fen': AppConstants.startingFen,
      'history': <String>[],
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

  // GÜNCELLENDİ: Diğer sınıfların hamleleri doğrulayabilmesi için Public yapıldı
  String normalizeFen(String fen) {
    final parts = fen.split(' ');
    if (parts.length >= 3) {
      return "${parts[0]} ${parts[1]} ${parts[2]}"; 
    }
    return fen;
  }

  OpeningNode? _findNodeByFen(OpeningNode node, String fen) {
    if (normalizeFen(node.fen) == normalizeFen(fen)) return node;
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
      'name': e.value.openingName ?? 'Variant: ${e.key}', 
      'fen': e.value.fen,
      'isCompleted': false, 
    }).toList();
  }

  String? getOpeningNameByFen(String fen) => _findNodeByFen(root!, fen)?.openingName;
}