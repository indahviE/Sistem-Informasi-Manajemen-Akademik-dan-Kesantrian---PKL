import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart';

const predikatOptions = ['MEMUASKAN', 'HONOUR', 'CUM_LAUDE', 'SUMMA_CUM_LAUDE'];

/// Palet sama persis dengan `_AC` di absensi_screen.dart.
class _KC {
  _KC._();

  static Color get primary => SC.primary;
  static Color get primaryGradientEnd => SC.primaryEnd;
  static const gold = Color(0xFFC5A059);
  static const goldSurface = Color(0xFFFAF5EC);
  static const goldDark = Color(0xFF7A5B10);
  static Color get mint => SC.mint;
  static Color get sage => SC.sage;

  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);

  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const border = Color(0xFFEAE6DC);

  static const errorBg = Color(0xFFFEE2E2);
  static const errorText = Color(0xFF991B1B);
}

/// Gaya tiap predikat: label, warna latar, warna teks, ikon.
class _Pred {
  final String label;
  final String shortLabel;
  final Color bg;
  final Color fg;
  final IconData icon;
  const _Pred(this.label, this.shortLabel, this.bg, this.fg, this.icon);
}

_Pred _predOf(String? v) {
  switch (v) {
    case 'MEMUASKAN':
      return const _Pred('Memuaskan', 'Memuaskan', Color(0xFFD2E4DC), Color(0xFF0F3A2E),
          Icons.thumb_up_alt_outlined);
    case 'HONOUR':
      return const _Pred('Honour', 'Honour', Color(0xFFF3E2B8), Color(0xFF7A5B10),
          Icons.workspace_premium_outlined);
    case 'CUM_LAUDE':
      return const _Pred('Cum Laude', 'Cum Laude', Color(0xFFE6E4DB), Color(0xFF0F172A),
          Icons.military_tech_outlined);
    case 'SUMMA_CUM_LAUDE':
      return _Pred('Summa Cum Laude', 'Summa', SC.primary, const Color(0xFFC5A059),
          Icons.emoji_events_outlined);
  }
  return const _Pred('Tanpa Predikat', 'Lainnya', Color(0xFFF5F4EE), Color(0xFF475569),
      Icons.remove_circle_outline);
}

const int _kMaxJuz = 30;
const int _kMaxCatatan = 150;

class KelulusanScreen extends StatefulWidget {
  const KelulusanScreen({super.key});

  @override
  State<KelulusanScreen> createState() => _KelulusanScreenState();
}

class _KelulusanScreenState extends State<KelulusanScreen> {
  List<Map<String, dynamic>> _kelulusan = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  String? _filter; // null = semua predikat

  /// Pimpinan/Mudir hanya memantau: tidak bisa mencatat atau menghapus kelulusan.
  bool get _readOnly => AppScope.of(context).user?.isPimpinan == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  // ---------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------
  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.kelulusan);
      final raw = res is List ? res : ((res as Map<String, dynamic>)['data'] as List? ?? []);
      final items =
          raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      if (!mounted) return;
      setState(() {
        _kelulusan = items;
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
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat data kelulusan.';
          _loading = false;
        });
      }
    }
  }

  String? _santriIdOf(Map<String, dynamic> k) {
    final id = k['santriId'] ?? (k['santri'] is Map ? (k['santri'] as Map)['id'] : null);
    return id?.toString();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    return _kelulusan.where((k) {
      if (_filter != null && k['predikat'] != _filter) return false;
      if (q.isEmpty) return true;
      final s = (k['santri'] as Map?) ?? const {};
      final nama = (s['nama'] ?? '').toString().toLowerCase();
      final nis = (s['nis'] ?? '').toString().toLowerCase();
      return nama.contains(q) || nis.contains(q);
    }).toList();
  }

  int _countPred(String p) => _kelulusan.where((k) => k['predikat'] == p).length;

  int get _totalJuz =>
      _kelulusan.fold<int>(0, (sum, k) => sum + ((k['juzYangDiHafal'] as num?)?.toInt() ?? 0));

  // ---------------------------------------------------------------------
  // Aksi
  // ---------------------------------------------------------------------
  Future<void> _add() async {
    if (_readOnly) return;

    final sudahLulus = _kelulusan.map(_santriIdOf).whereType<String>().toSet();

    final santri = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _KC.surface,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PilihSantriSheet(sudahLulus: sudahLulus),
    );
    if (santri == null || !mounted) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _KC.surface,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FormKelulusanSheet(santri: santri),
    );
    if (result == null || !mounted) return;

    try {
      await AppScope.of(context).api.post(ApiUrl.kelulusan, {
        ...result,
        'santriId': santri['id'],
      });
      if (!mounted) return;
      _toast('Kelulusan tercatat', subtitle: '${santri['nama']}');
      _load(silent: true);
    } on ApiException catch (e) {
      if (mounted) _toast(e.message, error: true);
    } catch (_) {
      if (mounted) _toast('Gagal mencatat kelulusan.', error: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> k) async {
    if (_readOnly) return;
    final nama = (k['santri'] as Map?)?['nama']?.toString() ?? 'santri ini';

    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) => AlertDialog(
        backgroundColor: _KC.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(color: _KC.errorBg, shape: BoxShape.circle),
          child: const Icon(Icons.delete_outline_rounded, color: _KC.errorText, size: 26),
        ),
        title: const Text('Hapus data kelulusan?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _KC.ink)),
        content: Text(
          'Data kelulusan $nama akan dihapus dan tidak bisa dikembalikan.',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 13, color: _KC.inkSecondary, height: 1.45, fontWeight: FontWeight.w500),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _KC.border),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _KC.inkSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _KC.errorText,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, hapus',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await AppScope.of(context).api.delete('${ApiUrl.kelulusan}/${k['id']}');
      if (!mounted) return;
      _toast('Data kelulusan dihapus', subtitle: nama);
      _load(silent: true);
    } on ApiException catch (e) {
      if (mounted) _toast(e.message, error: true);
    } catch (_) {
      if (mounted) _toast('Gagal menghapus data.', error: true);
    }
  }

  // ---------------------------------------------------------------------
  // Notifikasi
  // ---------------------------------------------------------------------
  void _toast(String title, {String? subtitle, bool error = false}) {
    if (!mounted) return;
    final w = MediaQuery.of(context).size.width;
    final side = w > 472 ? (w - 440) / 2 : 16.0;
    final fg = error ? _KC.errorText : Colors.white;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? _KC.errorBg : _KC.primary,
          elevation: 6,
          // angka 88 = jarak dari bawah supaya tidak menutupi bar bawah
          margin: EdgeInsets.fromLTRB(side, 0, side, _readOnly ? 16 : 88),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          duration: Duration(seconds: error ? 4 : 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: error ? _KC.errorText.withOpacity(0.25) : _KC.gold.withOpacity(0.5),
            ),
          ),
          content: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: error ? Colors.white : _KC.gold.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  error ? Icons.error_outline : Icons.check_rounded,
                  size: 18,
                  color: error ? _KC.errorText : _KC.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: fg)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(fontSize: 11.5, color: fg.withOpacity(0.75))),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ---------------------------------------------------------------------
  // Building blocks
  // ---------------------------------------------------------------------
  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(14)}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _KC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _KC.border),
      ),
      child: child,
    );
  }

  Widget _header() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kelulusan & Wisuda Tahfidz',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _KC.ink)),
        SizedBox(height: 2),
        Text('Pencatatan santri yang telah menyelesaikan hafalan',
            style: TextStyle(fontSize: 12, color: _KC.inkSecondary)),
      ],
    );
  }

  Widget _counter(IconData icon, String label, int value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: Colors.white.withOpacity(0.8)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.8))),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('$value',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    final total = _kelulusan.length;
    final berPredikat = _kelulusan.where((k) => k['predikat'] != null).length;
    final pct = total > 0 ? berPredikat / total : 0.0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_KC.primary, _KC.primaryGradientEnd],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _KC.primary.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4)),
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
              decoration:
                  BoxDecoration(color: _KC.gold.withOpacity(0.10), shape: BoxShape.circle),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 8,
            child: Icon(Icons.workspace_premium_rounded,
                size: 64, color: _KC.gold.withOpacity(0.14)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('REKAP KELULUSAN',
                        style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.7))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _KC.gold.withOpacity(0.5)),
                      ),
                      child: Text('$_totalJuz Juz Terhafal',
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700, color: _KC.gold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('$total Santri Wisuda',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _counter(Icons.thumb_up_alt_outlined, 'Memuaskan', _countPred('MEMUASKAN')),
                    const SizedBox(width: 8),
                    _counter(Icons.workspace_premium_outlined, 'Honour', _countPred('HONOUR')),
                    const SizedBox(width: 8),
                    _counter(Icons.military_tech_outlined, 'Cum Laude', _countPred('CUM_LAUDE')),
                    const SizedBox(width: 8),
                    _counter(Icons.emoji_events_outlined, 'Summa', _countPred('SUMMA_CUM_LAUDE')),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sudah Berpredikat',
                        style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.8))),
                    Text('$berPredikat dari $total',
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(_KC.mint),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _KC.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _KC.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 20, color: _KC.inkSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(fontSize: 13.5, color: _KC.ink),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Cari nama atau NIS santri...',
                hintStyle: TextStyle(fontSize: 13, color: _KC.inkSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, int count, bool selected, VoidCallback onTap) {
    final bg = selected ? _KC.primary : _KC.surfaceDim;
    final fg = selected ? Colors.white : _KC.inkSecondary;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: fg)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withOpacity(0.2) : _KC.surface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$count',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: fg)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChips() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip('Semua', _kelulusan.length, _filter == null,
              () => setState(() => _filter = null)),
          for (final p in predikatOptions) ...[
            const SizedBox(width: 8),
            _chip(_predOf(p).label, _countPred(p), _filter == p,
                () => setState(() => _filter = p)),
          ],
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }

  String? _fmtTanggal(dynamic raw) {
    if (raw == null) return null;
    final d = DateTime.tryParse(raw.toString())?.toLocal();
    if (d == null) return null;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  Widget _kelulusanCard(int index, Map<String, dynamic> k) {
    final s = (k['santri'] as Map?) ?? const {};
    final nama = (s['nama'] ?? '-').toString().trim();
    final nis = (s['nis'] ?? '-').toString();
    final kelas = ((s['kelas'] as Map?)?['namaKelas'] ?? '-').toString();
    final juz = (k['juzYangDiHafal'] as num?)?.toInt();
    final predikat = k['predikat'] as String?;
    final catatan = (k['catatan'] ?? '').toString().trim();
    final tanggal = _fmtTanggal(k['tanggalLulus'] ?? k['tanggal'] ?? k['createdAt']);
    final p = _predOf(predikat);
    final even = index.isEven;
    final inisial = nama.isNotEmpty && nama != '-' ? nama.substring(0, 1).toUpperCase() : '?';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: even ? _KC.sage : _KC.goldSurface,
                  shape: BoxShape.circle,
                ),
                child: Text(inisial,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: even ? _KC.primary : _KC.gold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800, color: _KC.ink)),
                    const SizedBox(height: 2),
                    Text('NIS $nis • $kelas',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: _KC.inkSecondary)),
                  ],
                ),
              ),
              if (!_readOnly) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _delete(k),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _KC.errorBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: _KC.errorText),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(p.icon, p.label, p.bg, p.fg),
              if (juz != null)
                _pill(Icons.menu_book_outlined, '$juz Juz', _KC.surfaceDim, _KC.ink),
              if (tanggal != null)
                _pill(Icons.event_outlined, tanggal, _KC.surfaceDim, _KC.inkSecondary),
            ],
          ),
          if (catatan.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: _KC.surfaceDim,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(Icons.notes_rounded, size: 15, color: _KC.inkSecondary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(catatan,
                        style: const TextStyle(fontSize: 11.5, height: 1.35, color: _KC.ink)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bottomBar() {
    if (_readOnly) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: _KC.surface,
        border: Border(top: BorderSide(color: _KC.border)),
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Wisuda',
                  style: TextStyle(fontSize: 11, color: _KC.inkSecondary)),
              const SizedBox(height: 2),
              Text('${_kelulusan.length} Santri',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: _KC.ink)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _add,
                style: FilledButton.styleFrom(
                  backgroundColor: _KC.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(color: _KC.gold.withOpacity(0.6)),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 20, color: _KC.gold),
                label: const Text('Catat Kelulusan',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(backgroundColor: _KC.background, body: loadingView());
    }
    if (_error != null) {
      return Scaffold(backgroundColor: _KC.background, body: errorView(_error!, _load));
    }

    final list = _filtered;

    return Scaffold(
      backgroundColor: _KC.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: _KC.primary,
                  onRefresh: () => _load(silent: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                    children: [
                      _header(),
                      const SizedBox(height: 14),
                      _summaryCard(),
                      const SizedBox(height: 14),
                      if (_kelulusan.isNotEmpty) ...[
                        _searchField(),
                        const SizedBox(height: 10),
                        _filterChips(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Daftar Wisudawan',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700, color: _KC.ink)),
                            Text('${list.length} santri',
                                style: const TextStyle(
                                    fontSize: 11, color: _KC.inkSecondary)),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (_kelulusan.isEmpty)
                        emptyView(_readOnly
                            ? 'Belum ada santri yang dicatat lulus/wisuda tahfidz.'
                            : 'Belum ada santri yang dicatat lulus/wisuda tahfidz.\nKetuk "Catat Kelulusan" untuk menambah.')
                      else if (list.isEmpty)
                        emptyView('Tidak ada santri yang cocok dengan pencarian/filter.')
                      else
                        for (int i = 0; i < list.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _kelulusanCard(i, list[i]),
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

// ===========================================================================
// Bottom sheet: pilih santri
// ===========================================================================
class _PilihSantriSheet extends StatefulWidget {
  final Set<String> sudahLulus;
  const _PilihSantriSheet({required this.sudahLulus});

  @override
  State<_PilihSantriSheet> createState() => _PilihSantriSheetState();
}

class _PilihSantriSheetState extends State<_PilihSantriSheet> {
  List<Map<String, dynamic>> _santri = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res =
          await AppScope.of(context).api.get(ApiUrl.santri, query: {'perPage': '100'});
      final raw = (res as Map<String, dynamic>)['items'] as List? ?? [];
      if (!mounted) return;
      setState(() {
        _santri = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat daftar santri.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final list = q.isEmpty
        ? _santri
        : _santri.where((m) {
            final nama = (m['nama'] as String? ?? '').toLowerCase();
            final nis = (m['nis'] as String? ?? '').toLowerCase();
            return nama.contains(q) || nis.contains(q);
          }).toList();

    final height = MediaQuery.of(context).size.height * 0.78;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _KC.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text('Pilih Santri',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _KC.ink)),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Text('Pilih santri yang akan dicatat lulus/wisuda tahfidz',
                    style: TextStyle(fontSize: 12, color: _KC.inkSecondary)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _KC.surfaceDim,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 20, color: _KC.inkSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _query = v),
                          style: const TextStyle(fontSize: 13.5, color: _KC.ink),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Cari nama / NIS...',
                            hintStyle: TextStyle(fontSize: 13, color: _KC.inkSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: _KC.border),
              Expanded(
                child: _loading
                    ? loadingView()
                    : _error != null
                        ? errorView(_error!, _load)
                        : list.isEmpty
                            ? emptyView('Santri tidak ditemukan.')
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                                itemCount: list.length,
                                itemBuilder: (ctx, i) {
                                  final s = list[i];
                                  final id = s['id']?.toString();
                                  final done = id != null && widget.sudahLulus.contains(id);
                                  final nama = (s['nama'] as String? ?? '-').trim();
                                  final kelas =
                                      ((s['kelas'] as Map?)?['namaKelas'] ?? '-').toString();
                                  final inisial = nama.isNotEmpty
                                      ? nama.substring(0, 1).toUpperCase()
                                      : '?';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Opacity(
                                      opacity: done ? 0.55 : 1,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(14),
                                        onTap: done ? null : () => Navigator.of(context).pop(s),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 10),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color:
                                                      i.isEven ? _KC.sage : _KC.goldSurface,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(inisial,
                                                    style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w800,
                                                        color: i.isEven
                                                            ? _KC.primary
                                                            : _KC.gold)),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(nama,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w800,
                                                            color: _KC.ink)),
                                                    const SizedBox(height: 2),
                                                    Text('NIS ${s['nis'] ?? '-'} • $kelas',
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                            fontSize: 11.5,
                                                            color: _KC.inkSecondary)),
                                                  ],
                                                ),
                                              ),
                                              if (done)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 9, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _KC.surfaceDim,
                                                    borderRadius:
                                                        BorderRadius.circular(999),
                                                  ),
                                                  child: const Text('Sudah tercatat',
                                                      style: TextStyle(
                                                          fontSize: 10.5,
                                                          fontWeight: FontWeight.w700,
                                                          color: _KC.inkSecondary)),
                                                )
                                              else
                                                const Icon(Icons.chevron_right_rounded,
                                                    color: _KC.inkSecondary),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Bottom sheet: form kelulusan
// ===========================================================================
class _FormKelulusanSheet extends StatefulWidget {
  final Map<String, dynamic> santri;
  const _FormKelulusanSheet({required this.santri});

  @override
  State<_FormKelulusanSheet> createState() => _FormKelulusanSheetState();
}

class _FormKelulusanSheetState extends State<_FormKelulusanSheet> {
  final _juz = TextEditingController();
  final _catatan = TextEditingController();
  String? _predikat;
  String? _juzError;

  @override
  void dispose() {
    _juz.dispose();
    _catatan.dispose();
    super.dispose();
  }

  void _submit() {
    final juzText = _juz.text.trim();
    int? juz;
    if (juzText.isNotEmpty) {
      juz = int.tryParse(juzText);
      if (juz == null || juz < 1 || juz > _kMaxJuz) {
        setState(() => _juzError = 'Juz harus antara 1 sampai $_kMaxJuz');
        return;
      }
    }
    final cat = _catatan.text.trim();
    Navigator.of(context).pop({
      'predikat': _predikat,
      'juzYangDiHafal': juz,
      'catatan': cat.isEmpty ? null : cat,
    });
  }

  InputDecoration _dec({String? hint, String? errorText, IconData? icon}) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13.5, color: _KC.inkSecondary),
      errorText: errorText,
      errorStyle: const TextStyle(
          fontSize: 11.5, fontWeight: FontWeight.w600, color: _KC.errorText),
      prefixIcon: icon == null ? null : Icon(icon, size: 19, color: _KC.inkSecondary),
      filled: true,
      fillColor: _KC.background,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: b(_KC.border),
      enabledBorder: b(_KC.border),
      focusedBorder: b(_KC.primary, 1.6),
      errorBorder: b(_KC.errorText.withOpacity(0.6)),
      focusedErrorBorder: b(_KC.errorText, 1.6),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 7),
        child: Text(text,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _KC.ink)),
      );

  Widget _predChip(String value) {
    final p = _predOf(value);
    final selected = _predikat == value;
    return Material(
      color: selected ? p.bg : _KC.surfaceDim,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => setState(() => _predikat = selected ? null : value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? p.fg.withOpacity(0.35) : Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? Icons.check_rounded : p.icon,
                  size: 15, color: selected ? p.fg : _KC.inkSecondary),
              const SizedBox(width: 6),
              Text(p.label,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? p.fg : _KC.inkSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nama = (widget.santri['nama'] ?? '-').toString();
    final nis = (widget.santri['nis'] ?? '-').toString();
    final kelas = ((widget.santri['kelas'] as Map?)?['namaKelas'] ?? '-').toString();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _KC.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _KC.sage,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.workspace_premium_rounded, size: 22, color: _KC.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Catat Kelulusan',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800, color: _KC.ink)),
                        Text('$nama • NIS $nis • $kelas',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: _KC.inkSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _label('Predikat tahfidz'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final p in predikatOptions) _predChip(p)],
              ),
              const SizedBox(height: 16),
              _label('Juz yang dihafal'),
              TextField(
                controller: _juz,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _KC.ink),
                onChanged: (_) {
                  if (_juzError != null) setState(() => _juzError = null);
                },
                decoration:
                    _dec(hint: 'Contoh: 30', errorText: _juzError, icon: Icons.menu_book_outlined),
              ),
              const SizedBox(height: 16),
              _label('Catatan (opsional)'),
              TextField(
                controller: _catatan,
                maxLength: _kMaxCatatan,
                minLines: 2,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 14, color: _KC.ink),
                decoration: _dec(hint: 'Contoh: Lulus dengan lancar, hafalan mutqin'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _KC.inkSecondary,
                        side: const BorderSide(color: _KC.border),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                      ),
                      child: const Text('Batal',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: _KC.inkSecondary)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _KC.primary,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: BorderSide(color: _KC.gold.withOpacity(0.6)),
                        ),
                      ),
                      child: const Text('Simpan',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}