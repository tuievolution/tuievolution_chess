import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Create a singleton instance of the client
  final SupabaseClient _client = Supabase.instance.client;

  // --- AUTHENTICATION LOGIC ---

  // 1. Sign Up (Creates the user in auth.users, which triggers our SQL script)
  Future<AuthResponse> signUp(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      print("Sign Up Error: $e");
      rethrow;
    }
  }

  // 2. Log In
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      print("Sign In Error: $e");
      rethrow;
    }
  }

  // 3. Log Out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Check if someone is currently logged in
  User? get currentUser => _client.auth.currentUser;

  // --- DATABASE LOGIC (PROGRESS TRACKING) ---

  // 4. Save progress when a user completes an opening
  Future<void> markOpeningCompleted(String openingName) async {
    final user = currentUser;
    if (user == null) {
      print("Cannot save progress: No user logged in.");
      return; 
    }

    try {
      // Upsert: Insert the row, but if it already exists, update it instead.
      await _client.from('user_progress').upsert({
        'user_id': user.id,
        'opening_name': openingName,
        'is_completed': true,
        'last_practiced': DateTime.now().toIso8601String(),
      });
      print("Progress saved successfully!");
    } catch (e) {
      print("Database Error: $e");
    }
  }

  // 5. Fetch all completed openings to display in the UI Roadmap
  Future<List<String>> getCompletedOpenings() async {
    final user = currentUser;
    if (user == null) return [];

    try {
      // Equivalent to SELECT opening_name FROM user_progress WHERE user_id = id
      final List<dynamic> response = await _client
          .from('user_progress')
          .select('opening_name')
          .eq('user_id', user.id)
          .eq('is_completed', true);

      // Extract just the string names from the JSON response
      return response.map((row) => row['opening_name'] as String).toList();
    } catch (e) {
      print("Fetch Error: $e");
      return [];
    }
  }
}