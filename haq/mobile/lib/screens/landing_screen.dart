import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';
import 'signup_screen.dart';
import 'ppdb/ppdb_form_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tw.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Tw.primary, Tw.purple],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 34),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'HAQ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Tw.gray900, letterSpacing: 2),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Halaqoh, Akademik dan Quran',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Tw.gray500),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Masuk',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Tw.gray900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Lanjutkan dengan akun Anda',
                    style: TextStyle(fontSize: 13, color: Tw.gray400),
                  ),
                  const SizedBox(height: 20),
                  const LoginForm(),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Belum terdaftar?',
                            style: TextStyle(fontSize: 12, color: Tw.gray400)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SignupScreen()));
                    },
                    child: const Text('Pondok baru? Daftarkan pondok Anda'),
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const PpdbFormScreen()));
                    },
                    icon: const Icon(Icons.app_registration, size: 18),
                    label: const Text('PPDB Online — Daftar Santri Baru'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _kode = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _submit() async {
    if (_email.text.isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Email dan password wajib diisi.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = AppScope.of(context);
      await auth.login(_kode.text.trim(), _email.text.trim(), _password.text);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Gagal login. Coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _kode,
          decoration: const InputDecoration(
            labelText: 'Kode Tenant',
            hintText: 'contoh: mahad-alquran',
            prefixIcon: Icon(Icons.apartment),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: _obscure,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Tw.redSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Tw.red, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Masuk', style: TextStyle(fontSize: 15)),
          ),
        ),
        if (AppScope.maybeOf(context)?.isWeb == true) ...[
          const SizedBox(height: 12),
          const Text(
            'Untuk Super Admin, biarkan Kode Tenant kosong.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Tw.gray400),
          ),
        ],
      ],
    );
  }
}