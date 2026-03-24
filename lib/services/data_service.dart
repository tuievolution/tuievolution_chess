import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../models/opening_node.dart';

class DataService {
  // The root node (standard starting position of a chess game)
  final OpeningNode root = OpeningNode(
    move: "start",
    fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
  );

  // This function reads the CSV and builds the tree in memory
  Future<void> loadOpenings() async {
    print("Loading CSV Data...");
    
    // 1. Read the raw file
    final rawData = await rootBundle.loadString('assets/openings.csv');
    
    // 2. Convert CSV string to a 2D List (Array of Arrays)
    List<List<dynamic>> rows = const CsvToListConverter().convert(rawData);
    
    // 3. Loop through rows (start at index 1 to skip the header row)
    for (var i = 1; i < rows.length; i++) {
      // Based on your CSV structure:
      // Index 1 = Opening Name (e.g., "Alekhine Defense")
      // Index 11 = moves_list (e.g., "['1.e4', 'Nf6']")
      String openingName = rows[i][1].toString();
      String rawMovesList = rows[i][11].toString();

      List<String> cleanMoves = _cleanMoves(rawMovesList);
      _insertIntoTree(cleanMoves, openingName);
    }
    
    print("Data processing complete! Tree is ready.");
  }

  // The String Cleaner Logic
  List<String> _cleanMoves(String rawList) {
    // 1. Remove brackets and single quotes: ['1.e4', 'Nf6'] -> 1.e4, Nf6
    String noBrackets = rawList.replaceAll(RegExp(r"[\[\]']"), "");
    
    // 2. Split into a list by comma and space
    List<String> movesArray = noBrackets.split(', ');
    
    // 3. Map over the array to remove the "Number." prefix (e.g., "1.e4" -> "e4")
    return movesArray.map((move) {
      return move.replaceAll(RegExp(r"^\d+\."), "").trim();
    }).toList();
  }

  // The Tree Builder Logic
  void _insertIntoTree(List<String> moves, String openingName) {
    OpeningNode currentNode = root;
    final game = chess_lib.Chess(); // Create a virtual chessboard

    for (int i = 0; i < moves.length; i++) {
      String move = moves[i];
      
      // Play the move on the virtual board to calculate the new FEN state
      game.move(move);

      // If this branch doesn't exist yet, create it
      if (!currentNode.children.containsKey(move)) {
        // Tag the very last node with the Opening Name, otherwise null
        String? nameToTag = (i == moves.length - 1) ? openingName : null;

        currentNode.children[move] = OpeningNode(
          move: move,
          fen: game.fen,
          openingName: nameToTag,
        );
      }
      
      // Move the pointer down the tree to the next child
      currentNode = currentNode.children[move]!;
    }
  }
}