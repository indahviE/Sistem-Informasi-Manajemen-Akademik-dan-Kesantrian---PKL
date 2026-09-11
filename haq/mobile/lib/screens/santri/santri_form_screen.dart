import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';

class SantriFormScreen extends StatefulWidget {
  const SantriFormScreen({super.key});

  @override
  State<SantriFormScreen> createState() => _SantriFormScreenState();
}

class _SantriFormScreenState extends State<SantriFormScreen> {
  final _nis = TextEditingController();
  final _nama = TextEditingController();
  final _tahun = TextEditingController(text: '2026');
  final _asrama = TextEditingController();
  String _jk = 'L';
  String? _kelasId;
  String? _waliId;
  List<Map<String, dynamic>> _kelas = [];
  List<Map<String, dynamic>> _wali = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final api = AppScope.of(context).api;
      final k = await api.get(ApiUrl.kelas);
      final w = await api.get(ApiUrl.wali);
      if (!mounted) return;
      setState(() {
        _kelas = (k as List).cast<Map<String, dynamic>>();
        _wali = (w as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_nis.text.isEmpty || _nama.text.isEmpty) {
      setState(() => _error = 'NIS dan nama wajib diisi.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      await api.post(ApiUrl.santri, {
        'nis': _nis.text.trim(),
        'nama': _nama.text.trim(),
        'jenisKelamin': _jk,
        'kelasId': _kelasId,
        'waliId': _waliId,
        'asrama': _asrama.text.trim().isEmpty ? null : _asrama.text.trim(),
        'tahunMasuk': int.tryParse(_tahun.text) ?? 2026,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _submitting = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _error = 'Gagal menyimpan.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Santri')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(controller: _nis, decoration: const InputDecoration(labelText: 'NIS')),
                  const SizedBox(height: 12),
                  TextField(controller: _nama, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
                  const SizedBox(height: 12),
                  TwSelect(
                    value: _jk,
                    label: 'Jenis Kelamin',
                    options: const [
                      DropdownOption('L', 'Laki-laki'),
                      DropdownOption('P', 'Perempuan'),
                    ],
                    onChanged: (v) => setState(() => _jk = v!),
                  ),
                  const SizedBox(height: 12),
                  TwSelect(
                    value: _kelasId ?? '',
                    label: 'Kelas',
                    options: [
                      const DropdownOption('', '— pilih kelas —'),
                      for (final k in _kelas) DropdownOption(k['id'] as String, k['namaKelas'] as String),
                    ],
                    onChanged: (v) => setState(() => _kelasId = v == '' ? null : v),
                  ),
                  const SizedBox(height: 12),
                  TwSelect(
                    value: _waliId ?? '',
                    label: 'Wali Santri',
                    options: [
                      const DropdownOption('', '— pilih wali —'),
                      for (final w in _wali) DropdownOption(w['id'] as String, w['nama'] as String),
                    ],
                    onChanged: (v) => setState(() => _waliId = v == '' ? null : v),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _asrama, decoration: const InputDecoration(labelText: 'Asrama (opsional)')),
                  const SizedBox(height: 12),
                  TextField(controller: _tahun, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tahun Masuk')),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Simpan'),
                  ),
                ],
              ),
            ),
    );
  }
}