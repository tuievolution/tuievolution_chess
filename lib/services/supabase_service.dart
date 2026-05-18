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
      debugPrint("Uygulama: Supabase'den $targetRating ELO için bulmaca talep ediyor...");
      
      // 1. Adım: Kullanıcının ELO seviyesinin +- 150 puan aralığını sorgula
      var response = await _client
          .from('puzzles')
          .select()
          .gte('rating', targetRating - 150)
          .lte('rating', targetRating + 150)
          .limit(limit);

      List<dynamic> data = response as List<dynamic>;
      debugPrint("Uygulama: Ana sorgudan gelen bulmaca sayısı: ${data.length}");

      // 2. Adım: Eğer o aralıkta veri bulunamadıysa veritabanındaki en düşük ELO'lu verilere yönlen
      if (data.isEmpty) {
        debugPrint("Uygulama: Hedef aralıkta veri bulunamadı (RLS engeli veya veri yoksa). En düşük ELO'lara yönleniliyor...");
        
        final fallbackResponse = await _client
            .from('puzzles')
            .select()
            .order('rating', ascending: true)
            .limit(limit);
            
        data = fallbackResponse as List<dynamic>;
        debugPrint("Uygulama: Geri çekilme (Fallback) sorgusundan gelen bulmaca sayısı: ${data.length}");
      }
      
      // Supabase tablosundaki verileri modelimizle harmanlıyoruz
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