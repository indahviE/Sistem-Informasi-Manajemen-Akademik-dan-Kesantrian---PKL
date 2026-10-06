import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart';

/// Palet sama persis dengan `_UC` di users_screen.dart.
/// Warna utama diambil dari `SC` (getter), jadi otomatis ikut tema yang dipilih.
class _UC {
  _UC._();

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

class _JenisInfo {
  final String value;
  final String label;
  final String chip;
  final IconData icon;
  const _JenisInfo(this.value, this.label, this.chip, this.icon);
}

const _kJenis = [
  _JenisInfo('GURU', 'Guru', 'Guru', Icons.school_outlined),
  _JenisInfo('MUSYRIF', 'Musyrif / Pembina', 'Musyrif', Icons.night_shelter_outlined),
];

_JenisInfo _jenisOf(String value) {
  for (final j in _kJenis) {
    if (j.value == value) return j;
  }
  return _JenisInfo(value, value, value, Icons.person_outline_rounded);
}

class UstadzListScreen extends StatefulWidget {
  const UstadzListScreen({super.key});

  @override
  State<UstadzListScreen> createState() => _UstadzListScreenState();
}

class _UstadzListScreenState extends State<UstadzListScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _filter = 'SEMUA'; // 'SEMUA' atau nilai jenis
  String _q = '';

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
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.ustadz);
      if (!mounted) return;
      final raw = res is List ? res : (res is Map ? (res['items'] ?? res['data']) : null);
      setState(() {
        _items = (raw is List ? raw : const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
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
          _error = 'Gagal memuat daftar ustadz.';
          _loading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _openForm([Map<String, dynamic>? existing]) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _UC.surface,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FormSheet(existing: existing),
    );
  }

  Future<void> _add() async {
    final res = await _openForm();
    if (res == null || !mounted) return;
    try {
      await AppScope.of(context).api.post(ApiUrl.ustadz, res);
      if (!mounted) return;
      _toast('Ustadz ditambahkan', subtitle: '${res['nama']} • ${_jenisOf(res['jenis']).label}');
      _load();
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Gagal menambahkan ustadz.', error: true);
    }
  }

  Future<void> _edit(Map<String, dynamic> ustadz) async {
    final res = await _openForm(ustadz);
    if (res == null || !mounted) return;
    try {
      await AppScope.of(context).api.patch('${ApiUrl.ustadz}/${ustadz['id']}', res);
      if (!mounted) return;
      _toast('Ustadz diperbarui', subtitle: '${res['nama']} • ${_jenisOf(res['jenis']).label}');
      _load();
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Gagal memperbarui ustadz.', error: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> ustadz) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _UC.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _UC.border),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: _UC.errorBg, shape: BoxShape.circle),
              child: const Icon(Icons.delete_outline, size: 18, color: _UC.errorText),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Hapus ustadz?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _UC.ink)),
            ),
          ],
        ),
        content: Text(
          'Ustadz "${ustadz['nama']}" akan dihapus permanen.',
          style: const TextStyle(fontSize: 13, color: _UC.inkSecondary, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: _UC.inkSecondary,
              side: const BorderSide(color: _UC.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: _UC.errorText,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await AppScope.of(context).api.delete('${ApiUrl.ustadz}/${ustadz['id']}');
      if (!mounted) return;
      _toast('Ustadz dihapus', subtitle: (ustadz['nama'] ?? '').toString());
      _load();
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Gagal menghapus ustadz.', error: true);
    }
  }

  // ---------------------------------------------------------------------
  // Util
  // ---------------------------------------------------------------------
  String _inisial(String nama) {
    final n = nama.trim();
    return n.isEmpty ? '?' : n.substring(0, 1).toUpperCase();
  }

  /// Notifikasi melayang bertema (sukses = warna tema, gagal = merah lembut).
  void _toast(String title, {String? subtitle, bool error = false}) {
    if (!mounted) return;
    final w = MediaQuery.of(context).size.width;
    final side = w > 472 ? (w - 440) / 2 : 16.0;
    final fg = error ? _UC.errorText : Colors.white;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? _UC.errorBg : _UC.primary,
          elevation: 6,
          margin: EdgeInsets.fromLTRB(side, 0, side, 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          duration: Duration(seconds: error ? 4 : 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: error ? _UC.errorText.withOpacity(0.25) : _UC.gold.withOpacity(0.5)),
          ),
          content: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: error ? Colors.white : _UC.gold.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  error ? Icons.error_outline : Icons.check_rounded,
                  size: 18,
                  color: error ? _UC.errorText : _UC.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: fg)),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 11.5, color: fg.withOpacity(0.75))),
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
        color: _UC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _UC.border),
      ),
      child: child,
    );
  }

  Widget _header() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Data Ustadz & Pembina',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _UC.ink)),
        SizedBox(height: 2),
        Text('Guru pengajar dan musyrif / pembina pondok',
            style: TextStyle(fontSize: 12, color: _UC.inkSecondary)),
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
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8))),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('$value',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    final total = _items.length;
    final guru = _items.where((u) => (u['jenis'] ?? '').toString() == 'GURU').length;
    final musyrif = _items.where((u) => (u['jenis'] ?? '').toString() == 'MUSYRIF').length;
    final pct = total > 0 ? guru / total : 0.0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_UC.primary, _UC.primaryGradientEnd],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _UC.primary.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4)),
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
              decoration: BoxDecoration(color: _UC.gold.withOpacity(0.10), shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RINGKASAN USTADZ',
                    style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.7))),
                const SizedBox(height: 4),
                Text('$total Ustadz Terdaftar',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _counter(Icons.groups_2_outlined, 'Total', total),
                    const SizedBox(width: 8),
                    _counter(Icons.school_outlined, 'Guru', guru),
                    const SizedBox(width: 8),
                    _counter(Icons.night_shelter_outlined, 'Musyrif', musyrif),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Porsi Guru', style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.8))),
                    Text('${(pct * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(_UC.mint),
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
    return TextField(
      onChanged: (v) => setState(() => _q = v),
      style: const TextStyle(fontSize: 14, color: _UC.ink),
      decoration: InputDecoration(
        hintText: 'Cari nama atau no HP',
        hintStyle: const TextStyle(fontSize: 13, color: _UC.inkSecondary),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _UC.inkSecondary),
        filled: true,
        fillColor: _UC.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: _UC.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: _UC.primary),
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label, int count) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _UC.primary : _UC.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? _UC.primary : _UC.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _UC.inkSecondary,
                )),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withOpacity(0.2) : _UC.surfaceDim,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$count',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : _UC.inkSecondary,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterRow() {
    int countJenis(String j) => _items.where((u) => (u['jenis'] ?? '').toString() == j).length;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('SEMUA', 'Semua', _items.length),
          for (final j in _kJenis) ...[
            const SizedBox(width: 8),
            _filterChip(j.value, j.chip, countJenis(j.value)),
          ],
        ],
      ),
    );
  }

  Widget _emptyCard(String msg) {
    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: _UC.goldSurface, shape: BoxShape.circle),
            child: const Icon(Icons.manage_accounts_outlined, color: _UC.gold, size: 26),
          ),
          const SizedBox(height: 12),
          Text(msg,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _UC.inkSecondary, height: 1.4)),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String tooltip, Color fg, Color bg, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, size: 17, color: fg),
        ),
      ),
    );
  }

  Widget _ustadzCard(int index, Map<String, dynamic> u) {
    final nama = (u['nama'] ?? '-').toString().trim();
    final noHp = (u['noHp'] ?? '').toString().trim();
    final jenis = _jenisOf((u['jenis'] ?? '').toString());
    final even = index.isEven;

    // Pill jenis: guru = hijau tema, musyrif = emas
    Color pillBg;
    Color pillFg;
    if (jenis.value == 'MUSYRIF') {
      pillBg = const Color(0xFFF3E2B8);
      pillFg = _UC.goldDark;
    } else {
      pillBg = _UC.sage;
      pillFg = _UC.primary;
    }

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
                decoration: BoxDecoration(color: even ? _UC.sage : _UC.goldSurface, shape: BoxShape.circle),
                child: Text(_inisial(nama),
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: even ? _UC.primary : _UC.gold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _UC.ink)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 12, color: _UC.inkSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(noHp.isEmpty ? 'No HP belum diisi' : noHp,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.5, color: _UC.inkSecondary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _actionBtn(Icons.edit_outlined, 'Edit', _UC.primary, _UC.sage, () => _edit(u)),
              const SizedBox(width: 6),
              _actionBtn(Icons.delete_outline, 'Hapus', _UC.errorText, _UC.errorBg, () => _delete(u)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(jenis.icon, size: 14, color: pillFg),
                const SizedBox(width: 6),
                Text(jenis.label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: pillFg)),
              ],
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
    final q = _q.trim().toLowerCase();
    final filtered = _items.where((u) {
      if (_filter != 'SEMUA' && (u['jenis'] ?? '').toString() != _filter) return false;
      if (q.isEmpty) return true;
      return (u['nama'] ?? '').toString().toLowerCase().contains(q) ||
          (u['noHp'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    Widget content;
    if (_loading) {
      content = loadingView();
    } else if (_error != null) {
      content = errorView(_error!, _load);
    } else {
      content = RefreshIndicator(
        color: _UC.primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            _header(),
            const SizedBox(height: 14),
            _summaryCard(),
            const SizedBox(height: 14),
            _searchField(),
            const SizedBox(height: 12),
            _filterRow(),
            const SizedBox(height: 14),
            if (filtered.isEmpty)
              _emptyCard(_items.isEmpty ? 'Belum ada ustadz / pembina.' : 'Tidak ada ustadz yang cocok.')
            else
              for (var i = 0; i < filtered.length; i++) ...[
                _ustadzCard(i, filtered[i]),
                const SizedBox(height: 10),
              ],
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _UC.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Stack(
            children: [
              Positioned.fill(child: content),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.extended(
                  onPressed: _add,
                  backgroundColor: _UC.primary,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Tambah Ustadz'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Bottom sheet: tambah / edit ustadz
// ---------------------------------------------------------------------
class _FormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _FormSheet({this.existing});

  @override
  State<_FormSheet> createState() => _FormSheetState();
}

class _FormSheetState extends State<_FormSheet> {
  late final TextEditingController _nama;
  late final TextEditingController _noHp;
  late String _jenis;
  String? _err;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nama = TextEditingController(text: e?['nama'] as String? ?? '');
    _noHp = TextEditingController(text: e?['noHp'] as String? ?? '');
    _jenis = e?['jenis'] as String? ?? 'GURU';
  }

  @override
  void dispose() {
    _nama.dispose();
    _noHp.dispose();
    super.dispose();
  }

  void _submit() {
    final nama = _nama.text.trim();
    final noHp = _noHp.text.trim();
    if (nama.isEmpty) {
      setState(() => _err = 'Nama wajib diisi.');
      return;
    }
    Navigator.pop<Map<String, dynamic>>(context, {
      'nama': nama,
      'noHp': noHp.isEmpty ? null : noHp,
      'jenis': _jenis,
    });
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: _UC.inkSecondary),
        labelStyle: const TextStyle(fontSize: 13, color: _UC.inkSecondary),
        filled: true,
        fillColor: _UC.surfaceDim,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );

  Widget _jenisChip(_JenisInfo j) {
    final selected = _jenis == j.value;
    return GestureDetector(
      onTap: () => setState(() => _jenis = j.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _UC.primary : _UC.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? _UC.primary : _UC.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(j.icon, size: 15, color: selected ? Colors.white : _UC.inkSecondary),
            const SizedBox(width: 6),
            Text(j.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _UC.inkSecondary,
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(color: _UC.goldSurface, shape: BoxShape.circle),
                    child: Icon(_isEdit ? Icons.edit_outlined : Icons.person_add_alt_1_rounded,
                        size: 18, color: _UC.gold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isEdit ? 'Edit Ustadz / Pembina' : 'Tambah Ustadz / Pembina',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _UC.ink)),
                        Text(_isEdit ? 'Perbarui data ustadz' : 'Tambahkan guru atau musyrif baru',
                            style: const TextStyle(fontSize: 11.5, color: _UC.inkSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nama,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 14, color: _UC.ink),
                decoration: _dec('Nama', hint: 'Nama lengkap'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noHp,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 14, color: _UC.ink),
                decoration: _dec('No HP', hint: '08xxxxxxxxxx (opsional)'),
              ),
              const SizedBox(height: 16),
              const Text('JENIS',
                  style: TextStyle(
                      fontSize: 10, letterSpacing: 0.4, fontWeight: FontWeight.w700, color: _UC.inkSecondary)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [for (final j in _kJenis) _jenisChip(j)]),
              if (_err != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _UC.errorBg, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: _UC.errorText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_err!, style: const TextStyle(fontSize: 12.5, color: _UC.errorText)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _UC.inkSecondary,
                      side: const BorderSide(color: _UC.border),
                      minimumSize: const Size(0, 50),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: const Text('Batal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: _UC.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        icon: const Icon(Icons.verified_outlined, size: 18, color: Colors.white),
                        label: Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Ustadz',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
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