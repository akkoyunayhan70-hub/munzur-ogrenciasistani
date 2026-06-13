import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ubys_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAndLogin();
  }

  Future<void> _checkAndLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('saved_username');
    final password = prefs.getString('saved_password');

    if (username == null || password == null) {
      _goLogin();
      return;
    }

    final service = UbysService();
    try {
      final ok = await service.login(username, password);
      if (!mounted) return;
      if (ok) {
        _goHome(service);
      } else {
        await prefs.remove('saved_username');
        await prefs.remove('saved_password');
        _goLogin();
      }
    } catch (_) {
      if (!mounted) return;
      _goLogin();
    }
  }

  void _goLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _goHome(UbysService service) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(service: service)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B4141),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/logo.png',
                width: 110,
                height: 110,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Munzur Öğrenci Asistanı',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Munzur Üniversitesi',
              style: TextStyle(
                color: Colors.white.withAlpha(160),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Color(0xFF3AAFA9),
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
