import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import 'santri_ui.dart';

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
  bool _tried = false; // sudah pernah menekan Simpan
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pratinjau di hero ikut berubah saat mengetik.
    _nis.addListener(_refresh);
    _nama.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _init();
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
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
      List<Map<String, dynamic>> toList(dynamic res) {
        final raw = res is List ? res : (res is Map ? (res['items'] ?? res['data']) : null);
        return (raw is List ? raw : const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      setState(() {
        _kelas = toList(k);
        _wali = toList(w);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Gagal muat kelas/wali: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Daftar kelas & wali gagal dimuat. Kamu tetap bisa menyimpan tanpa keduanya.';
        });
      }
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_nis.text.trim().isEmpty || _nama.text.trim().isEmpty) {
      setState(() {
        _tried = true;
        _error = 'NIS dan nama wajib diisi.';
      });
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

  String get _kelasNama {
    for (final k in _kelas) {
      if (k['id'] == _kelasId) return k['namaKelas']?.toString() ?? '';
    }
    return '';
  }

  // ---------------------------------------------------------------------
  // Building blocks
  // ---------------------------------------------------------------------
  InputDecoration _dec({String? hint, IconData? icon, String? errorText}) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: sty(13.5, FontWeight.w500, SC.inkMuted),
      errorText: errorText,
      errorStyle: sty(11.5, FontWeight.w600, SC.errorText),
      prefixIcon: icon == null ? null : Icon(icon, size: 19, color: SC.primary),
      filled: true,
      fillColor: SC.background,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: b(SC.border),
      enabledBorder: b(SC.border),
      focusedBorder: b(SC.primary, 1.6),
      errorBorder: b(SC.errorText.withOpacity(0.6)),
      focusedErrorBorder: b(SC.errorText, 1.6),
    );
  }

  Widget _labeled(String label, Widget child, {bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: RichText(
            text: TextSpan(
              style: sty(12.5, FontWeight.w700, SC.ink),
              children: [
                TextSpan(text: label),
                if (required) TextSpan(text: ' *', style: sty(12.5, FontWeight.w800, SC.errorText)),
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
    String? errorText,
    TextCapitalization caps = TextCapitalization.none,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      inputFormatters: formatters,
      textCapitalization: caps,
      style: sty(14, FontWeight.w600, SC.ink),
      decoration: _dec(hint: hint, icon: icon, errorText: errorText),
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
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: SC.inkSecondary),
      dropdownColor: SC.surface,
      borderRadius: BorderRadius.circular(14),
      style: sty(14, FontWeight.w600, SC.ink),
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

  Widget _genderCard(String value, String label, IconData icon) {
    final selected = _jk == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _jk = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 52,
          decoration: BoxDecoration(
            color: selected ? SC.primary : SC.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? SC.primary : SC.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: selected ? SC.gold : SC.inkMuted),
              const SizedBox(width: 7),
              Text(label,
                  style: sty(13, FontWeight.w700, selected ? Colors.white : SC.inkSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required String title, required String subtitle, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SC.border),
        boxShadow: softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: SC.sage,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: SC.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: sty(15, FontWeight.w800, SC.ink)),
                    Text(subtitle, style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _notice(String msg, {required bool error}) {
    final fg = error ? SC.errorText : SC.pendingText;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error ? SC.errorBg : SC.pendingBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(error ? Icons.error_outline : Icons.info_outline, size: 17, color: fg),
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(msg, style: sty(12.5, FontWeight.w600, fg, h: 1.4))),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------
  Widget _hero() {
    final nama = _nama.text.trim();
    final nis = _nis.text.trim();
    final kelas = _kelasNama;
    final top = MediaQuery.of(context).padding.top + 12;

    return HeroShell(
      top: top,
      bottom: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HeroBackButton(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Santri Baru', style: sty(21, FontWeight.w800, Colors.white, h: 1.15)),
                    const SizedBox(height: 2),
                    Text('Isi data, pratinjau kartu tampil langsung',
                        style: sty(12, FontWeight.w500, Colors.white.withOpacity(0.75))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Pratinjau kartu santri
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                SantriAvatar(name: nama, gender: _jk, size: 56, onDark: true, badge: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama.isEmpty ? 'Nama santri' : nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: sty(17, FontWeight.w800,
                            nama.isEmpty ? Colors.white.withOpacity(0.5) : Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          SPill(nis.isEmpty ? 'NIS belum diisi' : 'NIS $nis',
                              icon: Icons.tag_rounded,
                              bg: Colors.white.withOpacity(0.14),
                              fg: Colors.white),
                          if (kelas.isNotEmpty)
                            SPill(kelas, icon: Icons.class_outlined, bg: SC.mint, fg: SC.primary),
                        ],
                      ),
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

  Widget _formCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(
          title: 'Data diri',
          subtitle: 'Identitas dasar santri',
          icon: Icons.person_rounded,
          children: [
            _labeled(
              'NIS',
              required: true,
              _textField(
                _nis,
                hint: 'Nomor induk santri',
                icon: Icons.badge_outlined,
                errorText: _tried && _nis.text.trim().isEmpty ? 'NIS wajib diisi' : null,
              ),
            ),
            const SizedBox(height: 14),
            _labeled(
              'Nama lengkap',
              required: true,
              _textField(
                _nama,
                hint: 'Nama lengkap santri',
                icon: Icons.person_outline,
                caps: TextCapitalization.words,
                errorText: _tried && _nama.text.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
            ),
            const SizedBox(height: 14),
            _labeled(
              'Jenis kelamin',
              Row(
                children: [
                  _genderCard('L', 'Laki-laki', Icons.male_rounded),
                  const SizedBox(width: 10),
                  _genderCard('P', 'Perempuan', Icons.female_rounded),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _card(
          title: 'Penempatan',
          subtitle: 'Kelas, asrama, dan wali',
          icon: Icons.meeting_room_rounded,
          children: [
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
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _labeled(
                    'Asrama (opsional)',
                    _textField(_asrama, hint: 'Nama asrama', icon: Icons.bed_outlined),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _labeled(
                    'Tahun masuk',
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
            const SizedBox(height: 14),
            _labeled(
              'Wali santri',
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
      ],
    );
  }

  Widget _bottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: SC.surface,
        border: Border(top: BorderSide(color: SC.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: (_submitting || _loading) ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: SC.primary,
                disabledBackgroundColor: SC.primary.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(color: SC.gold.withOpacity(0.6)),
                ),
              ),
              icon: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, size: 19, color: SC.gold),
              label: Text(
                _submitting ? 'Menyimpan...' : 'Simpan santri',
                style: sty(14.5, FontWeight.w700, Colors.white),
              ),
            ),
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
    // Kalau error berasal dari gagal-muat kelas/wali, tampil sebagai peringatan.
    final loadWarning = _error != null && _error!.startsWith('Daftar kelas');

    return Scaffold(
      backgroundColor: SC.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _hero(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_error != null) ...[
                              _notice(_error!, error: !loadWarning),
                              const SizedBox(height: 14),
                            ],
                            if (_loading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 48),
                                child: Center(child: CircularProgressIndicator(color: SC.primary)),
                              )
                            else
                              _formCards(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _bottomBar(),
            ],
          ),
        ),
      ),
    );
  }
}