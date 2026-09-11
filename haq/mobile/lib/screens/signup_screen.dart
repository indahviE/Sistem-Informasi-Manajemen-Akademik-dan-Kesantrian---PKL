import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/app_scope.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nama = TextEditingController();
  final _kode = TextEditingController();
  final _logo = TextEditingController();
  final _adminNama = TextEditingController();
  final _adminEmail = TextEditingController();
  final _adminPassword = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  Future<void> _submit() async {
    if (_nama.text.isEmpty ||
        _kode.text.isEmpty ||
        _adminNama.text.isEmpty ||
        _adminEmail.text.isEmpty ||
        _adminPassword.text.length < 6) {
      setState(() => _error = 'Lengkapi semua kolom. Password minimal 6 karakter.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      await api.postPublic(ApiUrl.tenantSignup, {
        'namaPondok': _nama.text.trim(),
        'kodeTenant': _kode.text.trim(),
        'logoUrl': _logo.text.trim().isEmpty ? null : _logo.text.trim(),
        'adminNama': _adminNama.text.trim(),
        'adminEmail': _adminEmail.text.trim(),
        'adminPassword': _adminPassword.text,
      });
      setState(() {
        _success = 'Pendaftaran berhasil. Menunggu persetujuan Super Admin.';
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Gagal mendaftar. Coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftarkan Pondok Baru')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(controller: _nama, decoration: const InputDecoration(labelText: 'Nama Pondok', prefixIcon: Icon(Icons.school))),
                const SizedBox(height: 12),
                TextField(controller: _kode, decoration: const InputDecoration(labelText: 'Kode Tenant', hintText: 'contoh: mahad-alquran', prefixIcon: Icon(Icons.tag))),
                const SizedBox(height: 12),
                TextField(controller: _logo, decoration: const InputDecoration(labelText: 'URL Logo (opsional)', prefixIcon: Icon(Icons.image))),
                const Divider(height: 28),
                TextField(controller: _adminNama, decoration: const InputDecoration(labelText: 'Nama Admin Awal', prefixIcon: Icon(Icons.person))),
                const SizedBox(height: 12),
                TextField(controller: _adminEmail, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email Admin', prefixIcon: Icon(Icons.email))),
                const SizedBox(height: 12),
                TextField(controller: _adminPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Password Admin', prefixIcon: Icon(Icons.lock))),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                if (_success != null) ...[
                  const SizedBox(height: 12),
                  Text(_success!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Daftar Pondok'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}