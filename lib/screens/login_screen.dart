import 'package:flutter/material.dart';
import '../services/ubys_service.dart';
import 'grades_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _service = UbysService();
  bool _loading = false;
  String? _error;

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ok = await _service.login(_userCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      if (ok) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GradesScreen(service: _service),
          ),
        );
      } else {
        setState(() => _error = 'Kullanıcı adı veya şifre hatalı.');
      }
    } catch (e) {
      setState(() => _error = 'Bağlantı hatası: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Munzur UBYS Girişi')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FlutterLogo(size: 64),
              const SizedBox(height: 32),
              TextFormField(
                controller: _userCtrl,
                decoration: const InputDecoration(
                  labelText: 'Öğrenci No / E-posta',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Boş bırakılamaz' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Boş bırakılamaz' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _onLogin,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Giriş Yap'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
