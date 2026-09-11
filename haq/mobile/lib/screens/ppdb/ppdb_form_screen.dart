import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';
import '../ui_utils.dart';

class PpdbFormScreen extends StatefulWidget {
  const PpdbFormScreen({super.key});

  @override
  State<PpdbFormScreen> createState() => _PpdbFormScreenState();
}

class _PpdbFormScreenState extends State<PpdbFormScreen> {
  final _kode = TextEditingController();
  final _nama = TextEditingController();
  String _jenisKelamin = 'L';
  final _tglLahir = TextEditingController();
  final _asalSekolah = TextEditingController();
  final _noHp = TextEditingController();
  final _email = TextEditingController();
  final _alamat = TextEditingController();
  final _jalur = TextEditingController();
  bool _loading = false;
  bool _submitted = false;
  String? _error;
  String? _sukses;

  Future<void> _submit() async {
    if (_kode.text.trim().isEmpty || _nama.text.trim().isEmpty) {
      setState(() => _error = 'Kode pondok dan nama lengkap wajib diisi.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AppScope.of(context)
          .api
          .postPublic(ApiUrl.ppdbDaftar, {
        'kodeTenant': _kode.text.trim(),
        'nama': _nama.text.trim(),
        'jenisKelamin': _jenisKelamin,
        'tanggalLahir': _tglLahir.text.trim().isEmpty ? null : _tglLahir.text.trim(),
        'asalSekolah': _asalSekolah.text.trim().isEmpty ? null : _asalSekolah.text.trim(),
        'noHp': _noHp.text.trim().isEmpty ? null : _noHp.text.trim(),
        'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
        'alamat': _alamat.text.trim().isEmpty ? null : _alamat.text.trim(),
        'jalur': _jalur.text.trim().isEmpty ? null : _jalur.text.trim(),
      });
      if (!mounted) return;
      final m = res as Map<String, dynamic>;
      setState(() {
        _submitted = true;
        _sukses = '${m['message']} ${m['noPendaftaran'] ?? ''}';
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PPDB Online')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _submitted
                ? _suksesView()
                : _formView(),
          ),
        ),
      ),
    );
  }

  Widget _suksesView() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Tw.primary, size: 56),
            const SizedBox(height: 12),
            Text(_sukses ?? 'Pendaftaran terkirim.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, color: Tw.gray900)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => setState(() {
                _submitted = false;
                _sukses = null;
                _nama.clear();
                _tglLahir.clear();
                _asalSekolah.clear();
                _noHp.clear();
                _email.clear();
                _alamat.clear();
                _jalur.clear();
              }),
              child: const Text('Daftarkan Santri Lain'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Formulir Pendaftaran Santri Baru',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Tw.gray900),
        ),
        const SizedBox(height: 4),
        const Text(
          'Isi data berikut untuk mendaftarkan calon santri.',
          style: TextStyle(fontSize: 13, color: Tw.gray500),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _kode,
          decoration: const InputDecoration(
            labelText: 'Kode Pondok (dari panitia)',
            hintText: 'mis. mahad-alquran',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nama,
          decoration: const InputDecoration(labelText: 'Nama Lengkap *'),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'L', label: Text('Laki-laki')),
            ButtonSegment(value: 'P', label: Text('Perempuan')),
          ],
          selected: {_jenisKelamin},
          onSelectionChanged: (s) => setState(() => _jenisKelamin = s.first),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tglLahir,
          decoration: const InputDecoration(
            labelText: 'Tanggal Lahir (opsional)',
            hintText: 'YYYY-MM-DD',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _asalSekolah,
          decoration: const InputDecoration(labelText: 'Asal Sekolah (opsional)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noHp,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'No. HP / WA (opsional)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email (opsional)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _alamat,
          decoration: const InputDecoration(labelText: 'Alamat (opsional)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _jalur,
          decoration: const InputDecoration(labelText: 'Jalur Pendaftaran (opsional)'),
        ),
        const SizedBox(height: 12),
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Tw.redSoft, borderRadius: BorderRadius.circular(10)),
            child: Text(_error!, style: const TextStyle(color: Tw.red, fontSize: 13)),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Kirim Pendaftaran'),
        ),
      ],
    );
  }
}
