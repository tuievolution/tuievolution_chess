import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/opening_node.dart';

class DataService {
  OpeningNode? root; // Null until the network request finishes
  final List<String> allAvailableOpenings = [];

  // Pass the Supabase Storage URL here
  Future<void> loadOpenings(String jsonUrl) async {
    print("Fetching pre-computed tree from the cloud...");
    
    try {
      final response = await http.get(Uri.parse(jsonUrl));
      
      if (response.statusCode == 200) {
        // 1. Decode the JSON string
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        
        // 2. Build the Dart Tree
        root = OpeningNode.fromJson(jsonData);
        
        // 3. Extract unique names for the UI Roadmap
        _extractOpeningNames(root!);
        
        print("Success! Tree loaded into memory instantly.");
      } else {
        print("Failed to fetch tree: ${response.statusCode}");
      }
    } catch (e) {
      print("Network/Parsing Error: $e");
    }
  }

  // A recursive helper to scan the tree and collect all unique opening names
  void _extractOpeningNames(OpeningNode node) {
    if (node.openingName != null && !allAvailableOpenings.contains(node.openingName)) {
      allAvailableOpenings.add(node.openingName!);
    }
    
    for (var childNode in node.children.values) {
      _extractOpeningNames(childNode);
    }
  }

  // UI Helper: Evrim passes an array of played moves, you return the Opening Name
  String? identifyOpening(List<String> playedMoves) {
    if (root == null) return null;
    
    OpeningNode current = root!;
    
    for (String move in playedMoves) {
      if (current.children.containsKey(move)) {
        current = current.children[move]!;
      } else {
        return null; // Move deviated from the known dataset
      }
    }
    
    return current.openingName; 
  }
}