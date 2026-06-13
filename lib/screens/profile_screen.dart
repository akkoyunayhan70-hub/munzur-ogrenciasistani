import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ubys_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final UbysService service;

  const ProfileScreen({super.key, required this.service});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Çıkış'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_username');
    await prefs.remove('saved_password');
    service.dispose();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = service.studentInfo;
    final name = info['Ad Soyad'] ?? '';
    final initials = _initials(name);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3AAFA9), Color(0xFF2B4141)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Text(
                initials.isNotEmpty ? initials : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (name.isNotEmpty) ...[
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B4141),
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (info['Öğrenci No'] != null)
              Text(
                info['Öğrenci No']!,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            const SizedBox(height: 28),
            // Bilgi kartı
            if (info.isNotEmpty) _InfoCard(info: info),
            const SizedBox(height: 32),
            // Çıkış butonu
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Çıkış Yap',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _InfoCard extends StatelessWidget {
  final Map<String, String> info;

  const _InfoCard({required this.info});

  static const _skipInHeader = {'Ad Soyad', 'Öğrenci No'};
  static const _order = [
    'Program',
    'Bölüm',
    'Fakülte',
    'Sınıf',
    'GANO',
    'Akademik Yıl',
  ];

  @override
  Widget build(BuildContext context) {
    final keys = [
      ..._order.where((k) => info.containsKey(k) && !_skipInHeader.contains(k)),
      ...info.keys.where((k) => !_order.contains(k) && !_skipInHeader.contains(k)),
    ];

    if (keys.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: keys.map((k) {
            final isLast = k == keys.last;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(
                          k,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          info[k]!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2B4141),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Colors.grey.shade100,
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
