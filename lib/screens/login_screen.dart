import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ubys_service.dart';
import 'home_screen.dart';

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
  bool _obscure = true;
  String? _error;

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final username = _userCtrl.text.trim();
      final password = _passCtrl.text;
      final ok = await _service.login(username, password);
      if (!mounted) return;

      if (ok) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_username', username);
        await prefs.setString('saved_password', password);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(service: _service),
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
      backgroundColor: const Color(0xFF2B4141),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Munzur Öğrenci Asistanı',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'UBYS ile giriş yap',
                    style: TextStyle(
                      color: Colors.white.withAlpha(150),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Öğrenci No
                  TextFormField(
                    controller: _userCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco(
                      label: 'Öğrenci No',
                      icon: Icons.person_outline,
                    ),
                    validator: (v) => v!.isEmpty ? 'Boş bırakılamaz' : null,
                  ),
                  const SizedBox(height: 14),
                  // Şifre
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco(
                      label: 'Şifre',
                      icon: Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white54,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Boş bırakılamaz' : null,
                    onFieldSubmitted: (_) => _onLogin(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(40),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.redAccent.withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3AAFA9),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _loading ? null : _onLogin,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Giriş Yap',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withAlpha(60)),
    );
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withAlpha(160), fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.white54, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withAlpha(18),
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color(0xFF3AAFA9), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
