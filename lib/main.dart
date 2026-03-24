import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Your Dart Future (similar to a JS async Promise) starts the app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the Supabase connection
  // Replace these strings with the URL and Anon Key you copied from Step 1
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TuiEvolution Chess',
      theme: ThemeData.dark(), // Evrim will customize this later
      home: const Scaffold(
        body: Center(child: Text("Backend Initialized!")),
      ),
    );
  }
}