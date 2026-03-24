// lib/services/data_service.dart

import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../models/opening_node.dart';

class DataService {
  // The root node is the starting position of a standard chess game
  final OpeningNode root = OpeningNode(
    move: "start",
    fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
  );

  // We keep a list of all unique opening names to build the "Study Roadmap" UI later
  final List<String> allAvailableOpenings = [];

  Future<void> loadOpenings() async {
    print("Initializing Data Pipeline... Reading CSV.");
    
    // 1. Load the raw string from the assets folder
    final rawData = await rootBundle.loadString('assets/openings.csv');
    
    // 2. Parse the CSV into a 2D List (Array of Arrays)
    List<List<dynamic>> rows = const CsvToListConverter().convert(rawData);
    
    // 3. Iterate through rows (Starting at index 1 to skip the header row)
    for (var i = 1; i < rows.length; i++) {
      // In your specific CSV schema:
      // Index 1 = Opening Name (e.g., "Alekhine Defense")
      // Index 12 = moves_list (e.g., "['1.e4', 'Nf6', '2.e5']")
      String openingName = rows[i][1].toString();
      String rawMovesList = rows[i][12].toString();

      // Collect the unique name for the UI Roadmap
      if (!allAvailableOpenings.contains(openingName)) {
        allAvailableOpenings.add(openingName);
      }

      List<String> cleanMoves = _cleanMoves(rawMovesList);
      _insertIntoTree(cleanMoves, openingName);
    }
    
    print("Data Pipeline Complete! Memory Tree built.");
  }

  // --- HELPER LOGIC ---

  List<String> _cleanMoves(String rawList) {
    // 1. Strip brackets and quotes: "['1.e4', 'Nf6']" -> "1.e4, Nf6"
    String noBrackets = rawList.replaceAll(RegExp(r"[\[\]']"), "");
    
    // 2. Split into a List by the comma and space
    List<String> movesArray = noBrackets.split(', ');
    
    // 3. Remove the turn numbers (e.g., "1.e4" becomes "e4") because the 
    // chess simulation engine only understands raw algebraic notation.
    return movesArray.map((move) {
      return move.replaceAll(RegExp(r"^\d+\."), "").trim();
    }).toList();
  }

  void _insertIntoTree(List<String> moves, String openingName) {
    OpeningNode currentNode = root;
    final game = chess_lib.Chess(); // Initialize a fresh virtual chessboard

    for (int i = 0; i < moves.length; i++) {
      String move = moves[i];
      
      // Play the move on the virtual board to calculate the new FEN state
      game.move(move);

      // If this branch does not exist in our tree yet, create it
      if (!currentNode.children.containsKey(move)) {
        // Only attach the Opening Name to the very last node in the sequence
        String? nameToTag = (i == moves.length - 1) ? openingName : null;

        currentNode.children[move] = OpeningNode(
          move: move,
          fen: game.fen,
          openingName: nameToTag,
        );
      }
      
      // Move the pointer down the tree
      currentNode = currentNode.children[move]!;
    }
  }

  // --- FRONTEND COMMUNICATION LOGIC ---

  // Evrim will pass an array of moves the user played on screen. 
  // This checks the tree and returns the name if it matches a known opening.
  String? identifyOpening(List<String> playedMoves) {
    OpeningNode current = root;
    
    for (String move in playedMoves) {
      if (current.children.containsKey(move)) {
        current = current.children[move]!;
      } else {
        return null; // The user played a move outside of our dataset
      }
    }
    
    return current.openingName; 
  }
}