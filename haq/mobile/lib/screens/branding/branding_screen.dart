import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../santri/santri_ui.dart';
import '../ui_utils.dart';

class BrandingScreen extends StatefulWidget {
  const BrandingScreen({super.key});

  @override
  State<BrandingScreen> createState() => _BrandingScreenState();
}

class _BrandingScreenState extends State<BrandingScreen> {
  /// Batas ukuran logo. Logo dikirim sebagai base64 lewat JSON, jadi kalau
  /// backend punya limit body yang berbeda, sesuaikan angka ini.
  static const _maxLogoMb = 1;
  static const _maxLogoBytes = _maxLogoMb * 1024 * 1024;

  static const _palette = [
    Color(0xFF059669),
    Color(0xFF0EA5E9),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFFDC2626),
    Color(0xFF0D9488),
    Color(0xFFDB2777),
  ];

  final _nama = TextEditingController();
  final _warna = TextEditingController();
  String _logo = '';

  // Nilai terakhir yang tersimpan di server: dipakai untuk mendeteksi
  // perubahan (tombol simpan muncul) dan untuk tombol Batalkan.
  String _initNama = '';
  String _initLogo = '';
  String _initWarna = '';

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _namaError;
  String? _warnaError;

  // Banner notifikasi inline (gaya sama dengan layar lain)
  String? _bannerTitle;
  String? _bannerSub;
  bool _bannerError = false;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _nama.dispose();
    _warna.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Helper warna
  // ---------------------------------------------------------------------
  /// Terima "059669" atau "#059669", kembalikan "#059669". Null kalau tidak valid.
  static String? _normalizeHex(String raw) {
    final h = raw.trim().replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(h)) return null;
    return '#${h.toUpperCase()}';
  }

  static Color? _toColor(String? raw) {
    final hex = raw == null ? null : _normalizeHex(raw);
    if (hex == null) return null;
    return Color(int.parse('FF${hex.substring(1)}', radix: 16));
  }

  static String _hexOf(Color c) => '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  /// Warna teks yang terbaca di atas warna [c].
  Color _onColor(Color c) =>
      ThemeData.estimateBrightnessForColor(c) == Brightness.dark ? Colors.white : SC.ink;

  Color get _brand => _toColor(_warna.text) ?? SC.defaultPrimary;

  bool get _dirty =>
      _nama.text.trim() != _initNama ||
      _logo != _initLogo ||
      _warna.text.trim().toUpperCase() != _initWarna.toUpperCase();

  // ---------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.brandingMe) as Map<String, dynamic>;
      if (!mounted) return;
      final nama = (res['namaPondok'] as String? ?? '').trim();
      final logo = res['logoUrl'] as String? ?? '';
      final rawWarna = (res['warnaTema'] as String? ?? '').trim();
      final warna = _normalizeHex(rawWarna) ?? rawWarna;
      setState(() {
        _nama.text = nama;
        _logo = logo;
        _warna.text = warna;
        _initNama = nama;
        _initLogo = logo;
        _initWarna = warna;
        _namaError = null;
        _warnaError = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    }
  }

  Future<void> _pilihLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return;
    if (bytes.length > _maxLogoBytes) {
      _toast(
        'Logo terlalu besar',
        subtitle: 'Maksimal $_maxLogoMb MB. Kecilkan ukurannya, lalu pilih lagi.',
        error: true,
      );
      return;
    }
    final ext = (file.extension ?? 'png').toLowerCase();
    final mime = ext == 'jpg' || ext == 'jpeg' ? 'image/jpeg' : 'image/$ext';
    setState(() => _logo = 'data:$mime;base64,${base64Encode(bytes)}');
  }

  void _pickSwatch(Color c) {
    setState(() {
      _warna.text = _hexOf(c);
      _warnaError = null;
    });
  }

  void _revert() {
    FocusScope.of(context).unfocus();
    setState(() {
      _nama.text = _initNama;
      _logo = _initLogo;
      _warna.text = _initWarna;
      _namaError = null;
      _warnaError = null;
    });
  }

  Future<void> _simpan() async {
    FocusScope.of(context).unfocus();
    final nama = _nama.text.trim();
    final warnaRaw = _warna.text.trim();
    final warna = warnaRaw.isEmpty ? null : _normalizeHex(warnaRaw);

    setState(() {
      _namaError = nama.isEmpty ? 'Nama pondok wajib diisi' : null;
      _warnaError = (warnaRaw.isNotEmpty && warna == null)
          ? 'Kode warna tidak valid. Contoh: #059669'
          : null;
    });
    if (_namaError != null || _warnaError != null) return;

    final app = AppScope.of(context);
    setState(() => _saving = true);
    try {
      await app.api.patch(ApiUrl.branding, {
        'namaPondok': nama,
        'logoUrl': _logo.isEmpty ? null : _logo,
        'warnaTema': warna,
      });
      await app.refreshBranding();
      if (!mounted) return;
      setState(() {
        _saving = false;
        _initNama = nama;
        _initLogo = _logo;
        _initWarna = warna ?? '';
        _warna.text = warna ?? '';
      });
      _toast('Perubahan disimpan', subtitle: 'Identitas pondok sudah diperbarui');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(e.message, error: true);
    }
  }

  void _toast(String title, {String? subtitle, bool error = false}) {
    if (!mounted) return;
    _bannerTimer?.cancel();
    setState(() {
      _bannerTitle = title;
      _bannerSub = subtitle;
      _bannerError = error;
    });
    _bannerTimer = Timer(Duration(seconds: error ? 5 : 3), _closeBanner);
  }

  void _closeBanner() {
    _bannerTimer?.cancel();
    if (mounted) setState(() => _bannerTitle = null);
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final showBar = !_loading && _error == null && _dirty;
    return Scaffold(
      backgroundColor: SC.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              _hero(),
              Expanded(child: _content()),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: Alignment.bottomCenter,
                child: showBar ? _saveBar() : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content() {
    if (_loading) return loadingView();
    if (_error != null) return errorView(_error!, _load);
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _banner(),
        _previewCard(),
        const SizedBox(height: 14),
        _identitasCard(),
        const SizedBox(height: 14),
        _warnaCard(),
      ],
    );
  }

  Widget _hero() {
    return HeroShell(
      top: 20,
      bottom: 18,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SC.gold.withOpacity(0.55)),
            ),
            child: const Icon(Icons.palette_rounded, size: 24, color: SC.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Identitas Pondok', style: sty(22, FontWeight.w800, Colors.white, h: 1.15)),
                const SizedBox(height: 3),
                Text(
                  'Nama, logo, dan warna tema pondok',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sty(12.5, FontWeight.w500, Colors.white.withOpacity(0.78)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Pratinjau langsung: bagian paling menonjol di layar ini
  // ---------------------------------------------------------------------
  Widget _previewCard() {
    final brand = SC.readable(_brand); // sama persis dengan warna hero di layar lain
    const on = Colors.white;
    final nama = _nama.text.trim().isEmpty ? 'Nama Pondok Anda' : _nama.text.trim();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SC.border),
        boxShadow: softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [brand, Color.lerp(brand, Colors.black, 0.22)!],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.6)),
                  ),
                  child: _logo.isEmpty
                      ? Icon(Icons.mosque_rounded, size: 28, color: brand)
                      : brandLogo(_logo, width: 56, height: 56, radius: 16),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: sty(16.5, FontWeight.w800, on, h: 1.2),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Pratinjau identitas',
                        style: sty(12, FontWeight.w500, on.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _sampleChip('Tombol utama', brand, on),
                _sampleChip('Tombol sekunder', Colors.transparent, brand, border: brand),
                _sampleChip('Label', brand.withOpacity(0.12), brand),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sampleChip(String text, Color bg, Color fg, {Color? border}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.all(color: border, width: 1.4),
      ),
      child: Text(text, style: sty(12, FontWeight.w700, fg)),
    );
  }

  // ---------------------------------------------------------------------
  // Kartu: Identitas (nama + logo)
  // ---------------------------------------------------------------------
  Widget _identitasCard() {
    final has = _logo.isNotEmpty;
    return _Card(
      icon: Icons.badge_outlined,
      title: 'Identitas',
      subtitle: 'Nama dan logo pondok',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Nama Pondok'),
          TextField(
            controller: _nama,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            style: sty(14, FontWeight.w600, SC.ink),
            onChanged: (_) => setState(() => _namaError = null),
            decoration: _deco(
              hint: "Contoh: Ma'had Al-Qur'an Wal Lughah",
              icon: Icons.mosque_outlined,
              error: _namaError,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1, color: SC.border),
          ),
          _label('Logo'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Material(
                color: has ? Colors.white : SC.sage,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: BorderSide(
                    color: has ? SC.border : SC.gold.withOpacity(0.55),
                    width: 1.5,
                  ),
                ),
                child: InkWell(
                  onTap: _saving ? null : _pilihLogo,
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: has
                        ? brandLogo(_logo, width: 92, height: 92)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 28, color: SC.primary),
                              const SizedBox(height: 4),
                              Text('Unggah', style: sty(11.5, FontWeight.w700, SC.primary)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      has ? 'Logo terpasang' : 'Belum ada logo',
                      style: sty(13.5, FontWeight.w800, SC.ink),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'PNG atau JPG, maksimal $_maxLogoMb MB. Rasio persegi paling pas.',
                      style: sty(11.5, FontWeight.w500, SC.inkSecondary, h: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _saving ? null : _pilihLogo,
                          style: FilledButton.styleFrom(
                            backgroundColor: SC.primary,
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.upload_rounded, size: 18, color: Colors.white),
                          label: Text(
                            has ? 'Ganti logo' : 'Pilih logo',
                            style: sty(12.5, FontWeight.w700, Colors.white),
                          ),
                        ),
                        if (has)
                          OutlinedButton.icon(
                            onPressed: _saving ? null : () => setState(() => _logo = ''),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: SC.errorText,
                              side: BorderSide(color: SC.errorText.withOpacity(0.35)),
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              shape: const StadiumBorder(),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            label: Text('Hapus', style: sty(12.5, FontWeight.w700, SC.errorText)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Kartu: Warna tema
  // ---------------------------------------------------------------------
  Widget _warnaCard() {
    final current = _toColor(_warna.text);
    return _Card(
      icon: Icons.palette_outlined,
      title: 'Warna Tema',
      subtitle: 'Pilih warna cepat atau ketik kode hex',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in _palette) _swatch(c, selected: current == c),
            ],
          ),
          const SizedBox(height: 18),
          _label('Kode warna (hex)'),
          TextField(
            controller: _warna,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F#]')),
              LengthLimitingTextInputFormatter(7),
            ],
            style: sty(14, FontWeight.w600, SC.ink),
            onChanged: (_) => setState(() => _warnaError = null),
            decoration: _deco(
              hint: '#059669',
              error: _warnaError,
              helper: 'Kosongkan untuk memakai warna bawaan.',
              leading: Center(
                widthFactor: 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: _brand,
                    shape: BoxShape.circle,
                    border: Border.all(color: SC.border),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _swatch(Color c, {required bool selected}) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Warna ${_hexOf(c)}',
      child: GestureDetector(
        onTap: () => _pickSwatch(c),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: selected ? c : Colors.transparent, width: 2),
          ),
          child: Container(
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            child: selected ? Icon(Icons.check_rounded, size: 20, color: _onColor(c)) : null,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Komponen kecil
  // ---------------------------------------------------------------------
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(text, style: sty(12.5, FontWeight.w800, SC.ink)),
    );
  }

  InputDecoration _deco({
    required String hint,
    IconData? icon,
    Widget? leading,
    String? error,
    String? helper,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: sty(14, FontWeight.w500, SC.inkMuted),
      errorText: error,
      errorStyle: sty(11.5, FontWeight.w600, SC.errorText),
      helperText: helper,
      helperStyle: sty(11.5, FontWeight.w500, SC.inkSecondary),
      prefixIcon: leading ?? (icon == null ? null : Icon(icon, size: 20, color: SC.primary)),
      filled: true,
      fillColor: SC.background,
      hoverColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SC.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: SC.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SC.errorText),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SC.errorText, width: 1.5),
      ),
    );
  }

  Widget _saveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: SC.surface,
        border: Border(top: BorderSide(color: SC.border)),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: _saving ? null : _revert,
            style: OutlinedButton.styleFrom(
              foregroundColor: SC.inkSecondary,
              side: const BorderSide(color: SC.border),
              minimumSize: const Size(0, 50),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: Text('Batalkan', style: sty(13, FontWeight.w700, SC.inkSecondary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _saving ? null : _simpan,
                style: FilledButton.styleFrom(
                  backgroundColor: SC.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.verified_outlined, size: 18, color: Colors.white),
                label: Text(
                  _saving ? 'Menyimpan...' : 'Simpan Perubahan',
                  style: sty(14, FontWeight.w700, Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _banner() {
    final title = _bannerTitle;
    final error = _bannerError;
    final fg = error ? SC.errorText : Colors.white;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: title == null
          ? const SizedBox(width: double.infinity)
          : Container(
              margin: const EdgeInsets.only(top: 6, bottom: 8),
              padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
              decoration: BoxDecoration(
                color: error ? SC.errorBg : SC.primary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: error ? SC.errorText.withOpacity(0.25) : SC.gold.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: error ? Colors.white : SC.gold.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      error ? Icons.error_outline : Icons.check_rounded,
                      size: 18,
                      color: error ? SC.errorText : SC.gold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: sty(13.5, FontWeight.w800, fg)),
                        if (_bannerSub != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _bannerSub!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: sty(11.5, FontWeight.w500, fg.withOpacity(0.75)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _closeBanner,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Tutup',
                    icon: Icon(Icons.close_rounded, size: 18, color: fg.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
    );
  }
}

// =====================================================================
// Kartu bagian (judul + ikon + isi)
// =====================================================================
class _Card extends StatelessWidget {
  const _Card({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: SC.sage,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: SC.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: sty(14, FontWeight.w800, SC.ink)),
                    const SizedBox(height: 1),
                    Text(subtitle, style: sty(11.5, FontWeight.w500, SC.inkSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}