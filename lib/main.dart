import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

// --- Frontend UI İçe Aktarmaları ---
import 'core/theme.dart';
import 'ui/screens/splash_screen.dart';

// --- Backend Service İçe Aktarmaları ---
import 'services/supabase_service.dart';
import 'services/data_service.dart';

// UI'ın backend fonksiyonlarına erişebilmesi için global nesneler
final supabaseService = SupabaseService();
final dataService = DataService();

Future<void> main() async {
  // Asenkron işlemlerden (dotenv, supabase vb.) önce Flutter binding'ini başlatmak zorundayız.
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Ortam değişkenlerini yükle (.env dosyası ana dizinde olmalı)
  await dotenv.load(fileName: ".env");

  // 2. Gizli anahtarlar ile Supabase'i güvenle başlat
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 3. Önceden hesaplanmış tree.json dosyasını Supabase public bucket'ından yükle
  const String treeJsonUrl = 'https://rkbnrvljltstnomsinjf.supabase.co/storage/v1/object/public/public-assets/tree.json';
  await dataService.loadOpenings(treeJsonUrl);

  // 4. Uygulamayı gerçek arayüz (GrowOpeningsApp) ile başlat
  runApp(const GrowOpeningsApp());
}

// Frontend ekibinin hazırladığı asıl uygulama sınıfı
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