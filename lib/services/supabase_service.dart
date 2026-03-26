import 'package:supabase_flutter/supabase_flutter.dart';

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
}