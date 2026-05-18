import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/puzzle_model.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  // Real Email/Password Sign Up
  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  // Real Email/Password Login
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  // Guest Mode Logic
  bool isGuest() {
    return _client.auth.currentUser == null;
  }

  // Save Progress (The Green Leaf)
  Future<void> saveMoveProgress(String openingName, String fen) async {
    if (isGuest()) return; // Don't save for guests

    final userId = _client.auth.currentUser!.id;
    await _client.from('user_progress').upsert({
      'user_id': userId,
      'opening_name': openingName,
      'move_fen': fen,
      'is_completed': true,
    });
  }

  Future<List<PuzzleModel>> fetchPuzzlesByRating(int targetRating, {int limit = 5}) async {
    try {
      // Hedef rating değerinin +- 150 puan aralığındaki bulmacaları filtreler ve getirir
      final response = await _client
          .from('puzzles')
          .select()
          .gte('rating', targetRating - 150)
          .lte('rating', targetRating + 150)
          .limit(limit);

      final List<dynamic> data = response as List<dynamic>;
      
      // Supabase tablosundaki küçük harfli sütun isimlerini modelimizle eşleştiriyoruz
      return data.map((json) => PuzzleModel.fromJson({
        "PuzzleId": json['puzzle_id'],
        "FEN": json['fen'],
        "Moves": json['moves'],
        "Rating": json['rating'],
        "Themes": json['themes']
      })).toList();

    } catch (e) {
      debugPrint("Supabase Bulmaca Çekme Hatası: $e");
      return [];
    }
  }
}