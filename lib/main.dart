import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Fixes the dotenv error

// Make sure these files exist exactly at lib/services/...
import 'services/supabase_service.dart';
import 'services/data_service.dart';

// Global instances so Evrim's UI can access your backend functions easily
final supabaseService = SupabaseService();
final dataService = DataService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load the environment variables (Make sure you have a .env file at the root)
  await dotenv.load(fileName: ".env");

  // 2. Initialize Supabase safely using hidden keys
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 3. Load the pre-computed tree.json from your Supabase public bucket
  const String treeJsonUrl = 'https://rkbnrvljltstnomsinjf.supabase.co/storage/v1/object/public/public-assets/tree.json';
  
  await dataService.loadOpenings(treeJsonUrl);

  // 4. Run the app
  runApp(const MyApp());
}

// Fixes the "Undefined class 'MyApp'" error.
// This is a temporary placeholder UI. Evrim will delete this and connect his frontend here.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TuiEvolution Chess',
      theme: ThemeData.dark(),
      home: const Scaffold(
        body: Center(
          child: Text(
            "Backend Pipeline Active! \nWaiting for Evrim's UI...",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}