import 'dart:async';

import 'package:flutter/material.dart';
import '../../../services/api_client.dart';
import '../../../services/app_scope.dart';
import '../../santri/santri_ui.dart';
import '../../ui_utils.dart';

// ---------------------------------------------------------------------------
// Komponen kecil untuk dialog (sama dengan layar daftar ustadz)
// ---------------------------------------------------------------------------

InputDecoration _dec(String hint) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: sty(13.5, FontWeight.w500, SC.inkMuted),
    filled: true,
    fillColor: SC.surfaceDim,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: b(Colors.transparent),
    enabledBorder: b(Colors.transparent),
    focusedBorder: b(SC.primary, 1.4),
  );
}

Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(text, style: sty(12, FontWeight.w700, SC.inkSecondary)),
    );

Widget _errText(String text) => Padding(
      padding: const EdgeInsets.only(top: 6, left: 2),
      child: Text(text, style: sty(11.5, FontWeight.w600, SC.errorText)),
    );

Widget _btnBatal(VoidCallback onTap) => OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: SC.border),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      onPressed: onTap,
      child: Text('Batal', style: sty(13, FontWeight.w700, SC.inkSecondary)),
    );

Widget _btnUtama(String label, VoidCallback onTap, {Color? warna}) => FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: warna ?? SC.primary,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      onPressed: onTap,
      child: Text(label, style: sty(13, FontWeight.w700, Colors.white)),
    );

Widget _dialogIcon(IconData icon, Color bg, Color fg) => Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: SC.gold.withOpacity(0.45)),
      ),
      child: Icon(icon, size: 18, color: fg),
    );

RoundedRectangleBorder get _dialogShape =>
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(22));

const _dialogTitlePad = EdgeInsets.fromLTRB(20, 20, 20, 0);
const _dialogContentPad = EdgeInsets.fromLTRB(20, 16, 20, 4);
const _dialogActionsPad = EdgeInsets.fromLTRB(16, 8, 16, 16);

// ---------------------------------------------------------------------------
// Layar utama
// ---------------------------------------------------------------------------

/// Layar Admin: mengatur "ustadz ini mengajar mapel apa di kelas mana".
class PenugasanMengajarScreen extends StatefulWidget {
  final String ustadzId;
  final String ustadzNama;
  const PenugasanMengajarScreen({
    super.key,
    required this.ustadzId,
    required this.ustadzNama,
  });

  @override
  State<PenugasanMengajarScreen> createState() => _PenugasanMengajarScreenState();
}

class _PenugasanMengajarScreenState extends State<PenugasanMengajarScreen> {
  /// Pimpinan/Mudir hanya memantau: tombol tambah/hapus disembunyikan.
  bool get _readOnly => AppScope.of(context).user?.isPimpinan == true;

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _kelas = [];
  List<Map<String, dynamic>> _mapel = [];
  bool _loading = true;
  bool _busy = false; // true selama simpan/hapus berjalan
  String? _error;

  /// Banner notifikasi inline (di bawah hero), hilang otomatis.
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
  // Data
  // ---------------------------------------------------------------------
  List<Map<String, dynamic>> _list(dynamic res) {
    final raw = res is List
        ? res
        : (res is Map && res['data'] is List ? res['data'] as List : const []);
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _load({bool spinner = true}) async {
    if (spinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final api = AppScope.of(context).api;
      final hasil = await Future.wait([
        api.get('${ApiUrl.ustadz}/${widget.ustadzId}/mengajar'),
        api.get(ApiUrl.kelas),
        api.get(ApiUrl.mapel),
      ]);
      if (!mounted) return;
      setState(() {
        _items = _list(hasil[0]);
        _kelas = _list(hasil[1]);
        _mapel = _list(hasil[2]);
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (spinner) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      } else {
        _toast(e.message, error: true);
      }
    } catch (_) {
      if (!mounted) return;
      if (spinner) {
        setState(() {
          _error = 'Gagal memuat data penugasan.';
          _loading = false;
        });
      } else {
        _toast('Gagal memuat ulang data penugasan.', error: true);
      }
    }
  }

  /// Aksi tulis ke server dengan satu pola: kunci tombol, tangkap error,
  /// tampilkan banner, lalu muat ulang tanpa spinner penuh.
  Future<void> _jalankan(Future<void> Function() aksi, String sukses, {String? sub}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await aksi();
      _toast(sukses, subtitle: sub);
      await _load(spinner: false);
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Terjadi kesalahan. Coba lagi.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _namaKelas(Map<String, dynamic> r) =>
      '${(r['kelas'] as Map?)?['namaKelas'] ?? '-'}';
  String _namaMapel(Map<String, dynamic> r) =>
      '${(r['mapel'] as Map?)?['namaMapel'] ?? '-'}';

  /// Kelompokkan per kelas: { "7A": [baris, baris], ... }
  Map<String, List<Map<String, dynamic>>> get _perKelas {
    final out = <String, List<Map<String, dynamic>>>{};
    for (final r in _items) {
      out.putIfAbsent(_namaKelas(r), () => []).add(r);
    }
    final keys = out.keys.toList()..sort();
    return {for (final k in keys) k: out[k]!};
  }

  int get _mapelUnikCount => _items.map(_namaMapel).toSet().length;

  // ---------------------------------------------------------------------
  // Aksi
  // ---------------------------------------------------------------------
  Future<void> _tambah() async {
    if (_busy) return;
    final res = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _TambahDialog(kelas: _kelas, mapel: _mapel),
    );
    if (res == null || !mounted) return;
    final api = AppScope.of(context).api;
    await _jalankan(() async {
      await api.post('${ApiUrl.ustadz}/${widget.ustadzId}/mengajar', {
        'kelasId': res['kelasId'],
        'mapelId': res['mapelId'],
      });
    }, 'Penugasan ditambahkan', sub: widget.ustadzNama);
  }

  Future<void> _hapus(Map<String, dynamic> row) async {
    if (_busy) return;
    final kelas = _namaKelas(row);
    final mapel = _namaMapel(row);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SC.surface,
        surfaceTintColor: Colors.transparent,
        shape: _dialogShape,
        icon: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(color: SC.errorBg, shape: BoxShape.circle),
          child: const Icon(Icons.delete_outline_rounded, color: SC.errorText, size: 26),
        ),
        title: Text('Hapus penugasan?',
            textAlign: TextAlign.center, style: sty(17, FontWeight.w800, SC.ink)),
        content: Text(
          '${widget.ustadzNama} tidak lagi mengajar $mapel di kelas $kelas.',
          textAlign: TextAlign.center,
          style: sty(13, FontWeight.w500, SC.inkSecondary, h: 1.45),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          _btnBatal(() => Navigator.pop(ctx, false)),
          _btnUtama('Ya, hapus', () => Navigator.pop(ctx, true), warna: SC.errorText),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final api = AppScope.of(context).api;
    await _jalankan(() async {
      await api.delete('/mengajar/${row['id']}');
    }, 'Penugasan dihapus', sub: '$mapel • kelas $kelas');
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
    final error = _bannerError;
    final fg = error ? SC.errorText : Colors.white;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: title == null
          ? const SizedBox(width: double.infinity)
          : Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
                        if (_bannerSub != null && _bannerSub!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(_bannerSub!,
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
          child: Stack(
            children: [
              RefreshIndicator(
                color: SC.primary,
                onRefresh: () => _load(spinner: false),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _hero()),
                    SliverToBoxAdapter(child: _banner()),
                    ..._bodySlivers(),
                  ],
                ),
              ),
              if (_busy)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: SC.gold,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              if (!_readOnly && !_loading && _error == null)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.extended(
                    heroTag: null,
                    onPressed: _busy ? null : _tambah,
                    tooltip: 'Tambah penugasan',
                    backgroundColor: SC.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(color: SC.gold.withOpacity(0.6)),
                    ),
                    icon: Icon(Icons.add_rounded, size: 18, color: SC.gold),
                    label: Text('Tambah penugasan',
                        style: sty(13, FontWeight.w700, Colors.white)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    final loaded = !_loading && _error == null;
    String ringkasan;
    if (_error != null) {
      ringkasan = 'Data tidak dapat dimuat';
    } else if (!loaded) {
      ringkasan = 'Memuat data...';
    } else {
      ringkasan = widget.ustadzNama;
    }
    String v(int n) => loaded ? '$n' : '–';

    Widget stat(String value, String label) => Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: sty(21, FontWeight.w800, Colors.white, h: 1.1)),
              const SizedBox(height: 2),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sty(10.5, FontWeight.w600, Colors.white.withOpacity(0.72))),
            ],
          ),
        );

    Widget garis() => Container(width: 1, height: 30, color: Colors.white.withOpacity(0.18));

    return HeroShell(
      top: 22,
      bottom: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: SC.gold.withOpacity(0.55)),
                ),
                child: Icon(Icons.menu_book_rounded, size: 24, color: SC.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Penugasan Mengajar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: sty(22, FontWeight.w800, Colors.white, h: 1.15)),
                    const SizedBox(height: 3),
                    Text(
                      ringkasan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sty(12.5, FontWeight.w500, Colors.white.withOpacity(0.78)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Row(
              children: [
                stat(v(_items.length), 'Penugasan'),
                garis(),
                stat(v(_perKelas.length), 'Kelas'),
                garis(),
                stat(v(_mapelUnikCount), 'Mapel'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _bodySlivers() {
    if (_loading) {
      return [SliverToBoxAdapter(child: SizedBox(height: 320, child: loadingView()))];
    }
    if (_error != null) {
      return [
        SliverToBoxAdapter(child: SizedBox(height: 320, child: errorView(_error!, () => _load())))
      ];
    }
    if (_items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _kosong(
            icon: Icons.menu_book_outlined,
            judul: 'Belum ada penugasan',
            pesan: _readOnly
                ? 'Ustadz ini belum punya penugasan mengajar.'
                : 'Tambahkan kelas dan mapel yang diajar lewat tombol "Tambah penugasan" di bawah.',
          ),
        ),
      ];
    }

    final grup = _perKelas.entries.toList();
    return [
      SliverToBoxAdapter(child: _info()),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 96),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _kelasCard(grup[i].key, grup[i].value),
            ),
            childCount: grup.length,
          ),
        ),
      ),
    ];
  }

  /// Keterangan singkat di atas daftar (gaya sama dengan notice di daftar ustadz).
  Widget _info() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Material(
        color: SC.goldSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: SC.gold.withOpacity(0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: SC.goldDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kelas tempat ustadz menjadi wali kelas tetap tampil otomatis.',
                  style: sty(12, FontWeight.w700, SC.goldDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kosong({required IconData icon, required String judul, required String pesan}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 96),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: SC.sage,
              shape: BoxShape.circle,
              border: Border.all(color: SC.gold.withOpacity(0.5), width: 1.5),
            ),
            child: Icon(icon, size: 36, color: SC.primary),
          ),
          const SizedBox(height: 18),
          Text(judul, textAlign: TextAlign.center, style: sty(16, FontWeight.w800, SC.ink)),
          const SizedBox(height: 6),
          Text(pesan,
              textAlign: TextAlign.center,
              style: sty(12.5, FontWeight.w500, SC.inkSecondary, h: 1.5)),
        ],
      ),
    );
  }

  Widget _kelasCard(String nama, List<Map<String, dynamic>> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SC.border),
        boxShadow: softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SC.sage,
                  shape: BoxShape.circle,
                  border: Border.all(color: SC.primary.withOpacity(0.18)),
                ),
                child: Icon(Icons.class_outlined, size: 20, color: SC.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Kelas $nama',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sty(14.5, FontWeight.w800, SC.ink)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: SC.mint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${rows.length} mapel',
                    style: sty(10.5, FontWeight.w800, SC.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final r in rows)
                Chip(
                  backgroundColor: SC.sage,
                  side: BorderSide(color: SC.primary.withOpacity(0.18)),
                  shape: const StadiumBorder(),
                  visualDensity: VisualDensity.compact,
                  label: Text(_namaMapel(r), style: sty(12, FontWeight.w700, SC.primary)),
                  onDeleted: (_busy || _readOnly) ? null : () => _hapus(r),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  deleteIconColor: SC.primary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog tambah penugasan
// ---------------------------------------------------------------------------

class _TambahDialog extends StatefulWidget {
  final List<Map<String, dynamic>> kelas;
  final List<Map<String, dynamic>> mapel;
  const _TambahDialog({required this.kelas, required this.mapel});

  @override
  State<_TambahDialog> createState() => _TambahDialogState();
}

class _TambahDialogState extends State<_TambahDialog> {
  String? _kelasId;
  String? _mapelId;
  String? _err;

  void _submit() {
    if (_kelasId == null || _mapelId == null) {
      setState(() => _err = 'Pilih kelas dan mata pelajaran.');
      return;
    }
    Navigator.pop<Map<String, String>>(context, {
      'kelasId': _kelasId!,
      'mapelId': _mapelId!,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SC.surface,
      surfaceTintColor: Colors.transparent,
      shape: _dialogShape,
      titlePadding: _dialogTitlePad,
      contentPadding: _dialogContentPad,
      actionsPadding: _dialogActionsPad,
      title: Row(
        children: [
          _dialogIcon(Icons.menu_book_rounded, SC.sage, SC.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Tambah penugasan', style: sty(16, FontWeight.w800, SC.ink)),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Kelas'),
              DropdownButtonFormField<String>(
                value: _kelasId,
                isExpanded: true,
                dropdownColor: SC.surface,
                borderRadius: BorderRadius.circular(14),
                style: sty(14, FontWeight.w600, SC.ink),
                decoration: _dec('Pilih kelas'),
                items: [
                  for (final k in widget.kelas)
                    DropdownMenuItem(
                      value: k['id'] as String,
                      child: Text('${k['namaKelas']}'),
                    ),
                ],
                onChanged: (v) => setState(() {
                  _kelasId = v;
                  _err = null;
                }),
              ),
              const SizedBox(height: 12),
              _label('Mata pelajaran'),
              DropdownButtonFormField<String>(
                value: _mapelId,
                isExpanded: true,
                dropdownColor: SC.surface,
                borderRadius: BorderRadius.circular(14),
                style: sty(14, FontWeight.w600, SC.ink),
                decoration: _dec('Pilih mata pelajaran'),
                items: [
                  for (final m in widget.mapel)
                    DropdownMenuItem(
                      value: m['id'] as String,
                      child: Text('${m['namaMapel']}'),
                    ),
                ],
                onChanged: (v) => setState(() {
                  _mapelId = v;
                  _err = null;
                }),
              ),
              if (_err != null) _errText(_err!),
            ],
          ),
        ),
      ),
      actions: [
        _btnBatal(() => Navigator.pop(context)),
        _btnUtama('Simpan', _submit),
      ],
    );
  }
}