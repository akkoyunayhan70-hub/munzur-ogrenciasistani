import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MunzurAsistanApp());
}

class MunzurAsistanApp extends StatelessWidget {
  const MunzurAsistanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Munzur Öğrenci Asistanı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B4F72)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
