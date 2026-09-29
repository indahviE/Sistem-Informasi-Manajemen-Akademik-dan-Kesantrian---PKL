import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';

/// Palet sama persis dengan `_WC` di dashboard_screen.dart.
class _FC {
  _FC._();

  static const primary = Color(0xFF0F3A2E);
  static const primaryGradientEnd = Color(0xFF164E3D);
  static const gold = Color(0xFFC5A059);
  static const sage = Color(0xFFE2ECE9);

  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);

  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const border = Color(0xFFEAE6DC);

  static const errorBg = Color(0xFFFEE2E2);
  static const errorText = Color(0xFF991B1B);
}

class _Opt {
  final String value;
  final String label;
  const _Opt(this.value, this.label);
}

class SantriFormScreen extends StatefulWidget {
  const SantriFormScreen({super.key});

  @override
  State<SantriFormScreen> createState() => _SantriFormScreenState();
}

class _SantriFormScreenState extends State<SantriFormScreen> {
  final _nis = TextEditingController();
  final _nama = TextEditingController();
  final _tahun = TextEditingController(text: DateTime.now().year.toString());
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

  @override
  void dispose() {
    _nis.dispose();
    _nama.dispose();
    _tahun.dispose();
    _asrama.dispose();
    super.dispose();
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
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Daftar kelas & wali gagal dimuat. Kamu tetap bisa menyimpan tanpa keduanya.';
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_nis.text.trim().isEmpty || _nama.text.trim().isEmpty) {
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
        'tahunMasuk': int.tryParse(_tahun.text) ?? DateTime.now().year,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _submitting = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Gagal menyimpan.';
          _submitting = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------
  // Building blocks
  // ---------------------------------------------------------------------
  InputDecoration _dec({String? hint, IconData? icon}) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13.5, color: _FC.inkSecondary),
      prefixIcon: icon == null ? null : Icon(icon, size: 18, color: _FC.inkSecondary),
      filled: true,
      fillColor: _FC.surfaceDim,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: b(Colors.transparent),
      enabledBorder: b(Colors.transparent),
      focusedBorder: b(_FC.primary, 1.4),
    );
  }

  Widget _labeled(String label, Widget child, {bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _FC.inkSecondary),
              children: [
                TextSpan(text: label),
                if (required)
                  const TextSpan(text: ' *', style: TextStyle(color: _FC.errorText)),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _textField(
    TextEditingController c, {
    String? hint,
    IconData? icon,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      inputFormatters: formatters,
      style: const TextStyle(fontSize: 14, color: _FC.ink),
      decoration: _dec(hint: hint, icon: icon),
    );
  }

  Widget _dropdown({
    required String value,
    required List<_Opt> options,
    required ValueChanged<String> onChanged,
    IconData? icon,
  }) {
    return DropdownButtonFormField<String>(
      value: options.any((o) => o.value == value) ? value : options.first.value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _FC.inkSecondary),
      dropdownColor: _FC.surface,
      borderRadius: BorderRadius.circular(12),
      style: const TextStyle(fontSize: 14, color: _FC.ink),
      decoration: _dec(icon: icon),
      items: [
        for (final o in options)
          DropdownMenuItem(value: o.value, child: Text(o.label, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _genderChip(String value, String label) {
    final selected = _jk == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _jk = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _FC.primary : _FC.surfaceDim,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : _FC.inkSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(color: _FC.sage, shape: BoxShape.circle),
          child: Icon(icon, size: 15, color: _FC.primary),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _FC.ink)),
      ],
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Divider(height: 1, color: _FC.border),
      );

  Widget _errorBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _FC.errorBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline, size: 16, color: _FC.errorText),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg, style: const TextStyle(fontSize: 12.5, color: _FC.errorText, height: 1.35)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------
  Widget _hero() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_FC.primary, _FC.primaryGradientEnd],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _FC.primary.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(color: _FC.gold.withOpacity(0.10), shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 20, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _FC.gold.withOpacity(0.5)),
                        ),
                        child: const Text(
                          'PENDAFTARAN SANTRI',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: _FC.gold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Tambah Santri',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text('Lengkapi data untuk mendaftarkan santri baru',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _FC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _FC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Data Diri', Icons.person),
          const SizedBox(height: 14),
          _labeled('NIS',
              required: true,
              _textField(_nis, hint: 'Nomor induk santri', icon: Icons.badge_outlined)),
          const SizedBox(height: 12),
          _labeled('Nama Lengkap',
              required: true,
              _textField(_nama, hint: 'Nama lengkap santri', icon: Icons.person_outline)),
          const SizedBox(height: 12),
          _labeled(
            'Jenis Kelamin',
            Row(
              children: [
                _genderChip('L', 'Laki-laki'),
                const SizedBox(width: 10),
                _genderChip('P', 'Perempuan'),
              ],
            ),
          ),
          _divider(),
          _sectionTitle('Penempatan', Icons.meeting_room),
          const SizedBox(height: 14),
          _labeled(
            'Kelas',
            _dropdown(
              value: _kelasId ?? '',
              icon: Icons.class_outlined,
              options: [
                const _Opt('', 'Pilih kelas'),
                for (final k in _kelas) _Opt(k['id'] as String, k['namaKelas'] as String),
              ],
              onChanged: (v) => setState(() => _kelasId = v.isEmpty ? null : v),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _labeled('Asrama (opsional)', _textField(_asrama, hint: 'Nama asrama')),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _labeled(
                  'Tahun Masuk',
                  _textField(
                    _tahun,
                    keyboard: TextInputType.number,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _labeled(
            'Wali Santri',
            _dropdown(
              value: _waliId ?? '',
              icon: Icons.people_outline,
              options: [
                const _Opt('', 'Pilih wali'),
                for (final w in _wali) _Opt(w['id'] as String, w['nama'] as String),
              ],
              onChanged: (v) => setState(() => _waliId = v.isEmpty ? null : v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: _FC.surface,
        border: Border(top: BorderSide(color: _FC.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          onPressed: (_submitting || _loading) ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: _FC.primary,
            disabledBackgroundColor: _FC.primary.withOpacity(0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          icon: _submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_rounded, size: 18, color: Colors.white),
          label: Text(
            _submitting ? 'Menyimpan...' : 'Simpan Santri',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _FC.background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _hero(),
                        const SizedBox(height: 16),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(child: CircularProgressIndicator(color: _FC.primary)),
                          )
                        else
                          _formCard(),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          _errorBox(_error!),
                        ],
                      ],
                    ),
                  ),
                ),
                _bottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}