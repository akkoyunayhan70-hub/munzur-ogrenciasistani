import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MunzurAsistanApp());
}

class MunzurAsistanApp extends StatelessWidget {
  const MunzurAsistanApp({super.key});

  // Logo renklerinden alınan palet
  static const Color primaryTeal = Color(0xFF3AAFA9);
  static const Color accentGold = Color(0xFFC9A84C);
  static const Color darkTeal = Color(0xFF2B4141);
  static const Color bgLight = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Munzur Öğrenci Asistanı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryTeal,
          primary: primaryTeal,
          secondary: accentGold,
          surface: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: bgLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
