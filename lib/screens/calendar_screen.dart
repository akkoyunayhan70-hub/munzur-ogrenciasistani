import 'package:flutter/material.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akademik Takvim')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF3AAFA9).withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month,
                size: 64,
                color: Color(0xFF3AAFA9),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Akademik Takvim',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B4141),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yakında eklenecek',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
