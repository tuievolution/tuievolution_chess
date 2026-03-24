import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv

// Import your services
import 'services/supabase_service.dart';
import 'services/data_service.dart';

final supabaseService = SupabaseService();
final dataService = DataService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load the environment variables
  await dotenv.load(fileName: ".env");

  // 2. Initialize Supabase using the hidden variables
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 3. Initialize your CSV data pipeline
  await dataService.loadOpenings();

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