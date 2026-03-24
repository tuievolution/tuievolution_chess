import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

import 'core/theme.dart';
import 'ui/screens/splash_screen.dart';

import 'services/supabase_service.dart';
import 'services/data_service.dart';
import 'services/stockfish_service.dart'; // NEW IMPORT

// GLOBAL SERVICES
final supabaseService = SupabaseService();
final dataService = DataService();
final stockfishService = StockfishService(); // NEW SERVICE

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize Data Pipeline
  const String treeJsonUrl = 'https://rkbnrvljltstnomsinjf.supabase.co/storage/v1/object/public/public-assets/tree.json';
  await dataService.loadOpenings(treeJsonUrl);

  // Initialize Stockfish Engine
  stockfishService.initEngine();

  runApp(const GrowOpeningsApp());
}

class GrowOpeningsApp extends StatelessWidget {
  const GrowOpeningsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GROW OPENINGS',
      debugShowCheckedModeBanner: false,
      theme: growOpeningTheme(),
      home: const SplashScreen(),
    );
  }
}