import 'package:flutter/material.dart';

// Uygulamamızın her yerinde kullanacağımız profesyonel renk paletimiz
class AppColors {
  static const Color background = Color(0xFFDDEAD1); // Ana arkaplan (Açık krem/yeşil)
  static const Color boxColor = Color(0xFF95BB72);   // Kutular ve AppBar (Açık yeşil)
  static const Color border = Color(0xFF7F4F24);     // Kenarlık (Kahverengi)
  static const Color textDark = Color(0xFF4B6043);   // Koyu yeşil yazılar
  static const Color activeGreen = Color(0xFF4B6043); // Aktif/Yeşeren dallar
  static const Color woodBrown = Color(0xFF582F0E);  // Koyu kahve vurgular
}

// Uygulamanın genel temasını belirleyen fonksiyon
ThemeData growOpeningTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light, // Dark mode iptal edildi, sadece light mode var
    scaffoldBackgroundColor: AppColors.background,
    
    // Üst menü (AppBar) tasarımı
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.boxColor,
      foregroundColor: AppColors.woodBrown,
      elevation: 0, // Gölgeyi kaldırarak daha modern bir düzlük elde ediyoruz
    ),
    
    // Metin (Yazı) tipleri ve renkleri
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: AppColors.woodBrown, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(color: AppColors.textDark),
    ),
    
    // Giriş (Login) input alanlarının genel tasarımı
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white70,
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.border, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.activeGreen, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}