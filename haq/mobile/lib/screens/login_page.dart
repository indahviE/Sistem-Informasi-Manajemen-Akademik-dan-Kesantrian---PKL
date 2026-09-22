import 'package:flutter/material.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.successMessage});

  /// Pesan sukses opsional yang ditampilkan sekali (mis. setelah signup
  /// pondok berhasil) lewat SnackBar begitu halaman ini terbuka.
  final String? successMessage;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final msg = widget.successMessage;
    if (msg != null && msg.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Tw.teal,
            duration: const Duration(seconds: 4),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    // Simple validation
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Harap isi username dan password'),
          backgroundColor: Tw.red,
        ),
      );
      return;
    }
    // TODO: Implement actual login logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Login berhasil!'),
        backgroundColor: Tw.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seed = AppScope.maybeOf(context)?.brandingColor ?? Tw.primary;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [seed, Tw.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Tw.gray100, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    const Text(
                      'SISTEM AKADEMIK\nPONDOK',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Tw.primary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manajemen akademik pondok lebih mudah dan terintegrasi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Username / NIS
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username / NIS',
                        prefixIcon: const Icon(Icons.person_outline),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Kata sandi
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Kata sandi',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Lupa kata sandi?
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Navigate to forgot password
                        },
                        child: const Text('Lupa kata sandi?'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Masuk button
                    FilledButton(
                      onPressed: _handleLogin,
                      style: FilledButton.styleFrom(
                        backgroundColor: Tw.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('Masuk'),
                    ),
                    const SizedBox(height: 20),

                    // Divider with "atau masuk dengan"
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Tw.gray400,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'atau masuk dengan',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Tw.gray400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Akun Wali Santri / Orang Tua button
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to wali santri login
                      },
                      icon: const Icon(Icons.supervisor_account_outlined),
                      label: const Text('Akun Wali Santri / Orang Tua'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Belum punya akun? Daftar di sini
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Belum punya akun?',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Navigate to registration
                          },
                          child: const Text('Daftar di sini'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}