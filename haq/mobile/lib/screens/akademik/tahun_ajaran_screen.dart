import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../santri/santri_ui.dart';
import '../ui_utils.dart';

// =====================================================================
// Kelola Tahun Ajaran: daftar, tambah, dan aktifkan.
// Letak file: lib/screens/akademik/tahun_ajaran_screen.dart
// Butuh ApiUrl.tahunAjaran di api_client.dart (lihat catatan di chat).
// =====================================================================
String _s(dynamic v) => (v ?? '').toString().trim();

class TahunAjaranScreen extends StatefulWidget {
  const TahunAjaranScreen({super.key});

  @override
  State<TahunAjaranScreen> createState() => _TahunAjaranScreenState();
}

class _TahunAjaranScreenState extends State<TahunAjaranScreen> {
  /// Pimpinan/Mudir hanya memantau. Backend tetap membatasi ke Admin.
  bool get _readOnly => AppScope.of(context).user?.isPimpinan == true;

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

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
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Banner inline
  // ---------------------------------------------------------------------
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

  Widget _banner() {
    final title = _bannerTitle;
    final fg = _bannerError ? SC.errorText : Colors.white;
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
                color: _bannerError ? SC.errorBg : SC.primary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _bannerError ? SC.errorText.withOpacity(0.25) : SC.gold.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(_bannerError ? Icons.error_outline : Icons.check_rounded,
                      size: 20, color: _bannerError ? SC.errorText : SC.gold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: sty(13.5, FontWeight.w800, fg)),
                        if (_bannerSub != null) ...[
                          const SizedBox(height: 2),
                          Text(_bannerSub!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: sty(11.5, FontWeight.w500, fg.withOpacity(0.75))),
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

  // ---------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------
  Future<void> _load({bool spinner = true}) async {
    if (spinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.tahunAjaran);
      final List<dynamic> list = res is List
          ? res
          : (res is Map && res['data'] is List ? res['data'] as List : <dynamic>[]);
      final items = [
        for (final e in list)
          if (e is Map) Map<String, dynamic>.from(e),
      ];
      // Yang aktif di paling atas, sisanya dari nama terbaru.
      items.sort((a, b) {
        final aa = a['aktif'] == true ? 0 : 1;
        final bb = b['aktif'] == true ? 0 : 1;
        if (aa != bb) return aa - bb;
        return _s(b['nama']).compareTo(_s(a['nama']));
      });
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
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

  /// Format wajib 2027/2028: tahun kedua = tahun pertama + 1, dan belum ada.
  String? _validasiNama(String v) {
    final m = RegExp(r'^(\d{4})/(\d{4})$').firstMatch(v);
    if (m == null) return 'Format harus seperti 2027/2028';
    if (int.parse(m.group(2)!) != int.parse(m.group(1)!) + 1) {
      return 'Tahun kedua harus satu tahun setelah tahun pertama';
    }
    if (_items.any((e) => _s(e['nama']) == v)) return 'Tahun ajaran ini sudah ada';
    return null;
  }

  Future<void> _tambah() async {
    final nama = await showDialog<String>(
      context: context,
      builder: (ctx) => _TambahDialog(validator: _validasiNama),
    );
    if (nama == null) return;
    // Tahun pertama pondok langsung aktif. Selanjutnya tidak aktif dulu,
    // supaya tahun berjalan tidak berpindah sebelum admin menekan Aktifkan.
    final pertama = _items.isEmpty;
    setState(() => _busy = true);
    try {
      await AppScope.of(context)
          .api
          .post(ApiUrl.tahunAjaran, {'nama': nama, 'aktif': pertama});
      if (!mounted) return;
      _toast('Tahun ajaran ditambah',
          subtitle: pertama
              ? '$nama langsung aktif karena ini tahun ajaran pertama.'
              : '$nama masuk ke daftar. Belum aktif sampai kamu aktifkan.');
      await _load(spinner: false);
    } on ApiException catch (e) {
      if (mounted) _toast(e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _aktifkan(Map<String, dynamic> item) async {
    final nama = _s(item['nama']);
    if (_belumWaktunya(nama)) {
      _toast('Belum waktunya', subtitle: _kapanBisaAktif(nama), error: true);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _KonfirmasiDialog(
        title: 'Aktifkan $nama?',
        message:
            'Nilai yang diinput setelah ini akan tercatat di $nama. Tahun ajaran yang sekarang aktif akan dinonaktifkan, dan layar Riwayat nilai hanya menampilkan $nama. Nilai tahun lain tetap tersimpan.',
        okLabel: 'Ya, aktifkan',
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await AppScope.of(context)
          .api
          .post('${ApiUrl.tahunAjaran}/${item['id']}/aktif', <String, dynamic>{});
      if (!mounted) return;
      _toast('$nama sekarang aktif', subtitle: 'Nilai baru otomatis tercatat di tahun ini');
      await _load(spinner: false);
    } on ApiException catch (e) {
      if (mounted) _toast(e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SC.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              _hero(),
              Expanded(
                child: Stack(
                  children: [
                    RefreshIndicator(
                      color: SC.primary,
                      onRefresh: () => _load(spinner: false),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                        children: [
                          _banner(),
                          _peringatan(),
                          _info(),
                          const SizedBox(height: 14),
                          ..._body(),
                        ],
                      ),
                    ),
                    if (!_readOnly)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton.extended(
                          heroTag: null,
                          onPressed: _busy ? null : _tambah,
                          backgroundColor: SC.primary,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: BorderSide(color: SC.gold.withOpacity(0.6)),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18, color: SC.gold),
                          label: Text('Tahun ajaran baru',
                              style: sty(13, FontWeight.w700, Colors.white)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
            child: const Icon(Icons.event_note_rounded, size: 24, color: SC.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tahun Ajaran', style: sty(22, FontWeight.w800, Colors.white, h: 1.15)),
                const SizedBox(height: 3),
                Text(
                  'Atur tahun ajaran yang sedang berjalan',
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

  /// Bulan dimulainya tahun ajaran (7 = Juli). Ubah di sini kalau berbeda.
  static const int _bulanMulai = 7;
  static const _namaBulan = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  /// Tahun mulai dari tahun ajaran yang seharusnya berjalan sekarang.
  int get _tahunMulaiSeharusnya {
    final now = DateTime.now();
    return now.month >= _bulanMulai ? now.year : now.year - 1;
  }

  String get _namaSeharusnya =>
      '$_tahunMulaiSeharusnya/${_tahunMulaiSeharusnya + 1}';

  /// Tahun ajaran yang tahun mulainya lebih besar dari yang seharusnya
  /// berjalan sekarang dianggap belum waktunya diaktifkan.
  bool _belumWaktunya(String nama) {
    final y = int.tryParse(nama.split('/').first);
    return y != null && y > _tahunMulaiSeharusnya;
  }

  String _kapanBisaAktif(String nama) {
    final y = int.tryParse(nama.split('/').first);
    return 'Bisa diaktifkan mulai ${_namaBulan[_bulanMulai]} ${y ?? ''}'.trim();
  }

  /// Pengingat saja, tidak memblokir apa pun. Tanggal mulai tiap pondok bisa beda.
  Widget _peringatan() {
    if (_loading || _error != null) return const SizedBox.shrink();
    final seharusnya = _namaSeharusnya;
    final aktif = [
      for (final e in _items)
        if (e['aktif'] == true) _s(e['nama']),
    ];
    if (aktif.contains(seharusnya)) return const SizedBox.shrink();

    final ada = _items.any((e) => _s(e['nama']) == seharusnya);
    final kondisi = aktif.isEmpty
        ? 'Belum ada tahun ajaran yang aktif.'
        : 'Tahun ajaran aktif saat ini ${aktif.first}.';
    final saran = _readOnly
        ? 'Admin perlu mengaktifkan $seharusnya.'
        : (ada
            ? 'Tekan Aktifkan pada $seharusnya.'
            : 'Tambahkan $seharusnya lalu aktifkan.');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SC.errorBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SC.errorText.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 22, color: SC.errorText),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sudah waktunya tahun ajaran baru?',
                    style: sty(13, FontWeight.w800, SC.errorText)),
                const SizedBox(height: 3),
                Text(
                  '$kondisi Menurut tanggal hari ini, yang berjalan seharusnya $seharusnya. $saran Selama belum diganti, nilai baru tetap tercatat di tahun lama.',
                  style: sty(12, FontWeight.w500, SC.errorText.withOpacity(0.85), h: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _info() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SC.goldSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SC.gold.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 20, color: SC.goldDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hanya satu tahun ajaran yang aktif. Nilai baru otomatis tercatat di tahun yang aktif, dan layar Riwayat nilai menampilkannya. Ganti tiap awal tahun ajaran (sekitar Juli).',
              style: sty(12, FontWeight.w500, SC.goldDark, h: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _body() {
    if (_loading) return [SizedBox(height: 240, child: loadingView())];
    if (_error != null) {
      return [SizedBox(height: 240, child: errorView(_error!, () => _load()))];
    }
    if (_items.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 30),
          child: Text(
            _readOnly
                ? 'Belum ada tahun ajaran yang dibuat admin.'
                : 'Belum ada tahun ajaran. Tambahkan lewat tombol di bawah.',
            textAlign: TextAlign.center,
            style: sty(13, FontWeight.w500, SC.inkSecondary, h: 1.5),
          ),
        ),
      ];
    }
    return [
      for (final it in _items)
        Padding(padding: const EdgeInsets.only(bottom: 9), child: _tile(it)),
    ];
  }

  Widget _tile(Map<String, dynamic> item) {
    final aktif = item['aktif'] == true;
    final belum = !aktif && _belumWaktunya(_s(item['nama']));
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: aktif ? SC.gold.withOpacity(0.7) : SC.border),
        boxShadow: softShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: aktif ? SC.gold : SC.border),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: aktif ? SC.goldSurface : SC.sage,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(Icons.event_note_rounded,
                          size: 22, color: aktif ? SC.goldDark : SC.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_s(item['nama']), style: sty(15.5, FontWeight.w800, SC.ink)),
                          const SizedBox(height: 4),
                          Text(
                            aktif
                                ? 'Sedang berjalan'
                                : (belum
                                    ? 'Belum waktunya. ${_kapanBisaAktif(_s(item['nama']))}'
                                    : 'Tidak aktif'),
                            style: sty(12, FontWeight.w500, aktif ? SC.goldDark : SC.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    if (aktif)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: SC.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('Aktif', style: sty(11.5, FontWeight.w800, Colors.white)),
                      )
                    else if (!_readOnly)
                      OutlinedButton(
                        onPressed: (_busy || belum) ? null : () => _aktifkan(item),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SC.primary,
                          side: BorderSide(
                              color: belum ? SC.border : SC.primary.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        child: Text('Aktifkan',
                            style: sty(12.5, FontWeight.w700,
                                belum ? SC.inkMuted : SC.primary)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Dialog tambah (validasi format langsung di dalam dialog)
// =====================================================================
class _TambahDialog extends StatefulWidget {
  const _TambahDialog({required this.validator});

  final String? Function(String) validator;

  @override
  State<_TambahDialog> createState() => _TambahDialogState();
}

class _TambahDialogState extends State<_TambahDialog> {
  final _ctrl = TextEditingController();
  String? _err;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _simpan() {
    final v = _ctrl.text.trim();
    final e = widget.validator(v);
    if (e != null) {
      setState(() => _err = e);
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SC.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text('Tahun ajaran baru', style: sty(17, FontWeight.w800, SC.ink)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tulis dengan format 2027/2028. Tahun baru tidak langsung aktif, kecuali ini tahun ajaran pertama.',
              style: sty(12.5, FontWeight.w500, SC.inkSecondary, h: 1.4)),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.datetime,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _simpan(),
            onChanged: (_) {
              if (_err != null) setState(() => _err = null);
            },
            style: sty(14, FontWeight.w600, SC.ink),
            decoration: InputDecoration(
              hintText: 'Contoh: 2027/2028',
              hintStyle: sty(14, FontWeight.w500, SC.inkMuted),
              errorText: _err,
              errorMaxLines: 2,
              filled: true,
              fillColor: SC.background,
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
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal', style: sty(13, FontWeight.w700, SC.inkSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: SC.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          onPressed: _simpan,
          child: Text('Simpan', style: sty(13, FontWeight.w700, Colors.white)),
        ),
      ],
    );
  }
}

// =====================================================================
// Dialog konfirmasi
// =====================================================================
class _KonfirmasiDialog extends StatelessWidget {
  const _KonfirmasiDialog({
    required this.title,
    required this.message,
    required this.okLabel,
  });

  final String title;
  final String message;
  final String okLabel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SC.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(title, style: sty(17, FontWeight.w800, SC.ink)),
      content: Text(message, style: sty(13, FontWeight.w500, SC.inkSecondary, h: 1.45)),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Batal', style: sty(13, FontWeight.w700, SC.inkSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: SC.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(okLabel, style: sty(13, FontWeight.w700, Colors.white)),
        ),
      ],
    );
  }
}