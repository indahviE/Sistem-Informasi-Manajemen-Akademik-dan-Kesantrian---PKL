import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../notifikasi/notifikasi_screen.dart';
import '../kesantrian/pelanggaran_screen.dart';
import '../kesantrian/perizinan_screen.dart';
import '../kesantrian/kesehatan_screen.dart';
import '../kesantrian/kunjungan_screen.dart';

/// ---------------------------------------------------------------------------
/// Design tokens — mirrored 1:1 dari signup_screen.dart (PColors/PText) dan
/// konsisten dengan token yang dipakai di billing_admin_screen.dart, jadi
/// halaman ini tetap satu identitas visual "Islamic Academic & Kesantrian
/// Experience" (Deep Emerald Forest + Antique Gold di atas kanvas ivory)
/// dengan tipografi Nunito yang sama.
/// ---------------------------------------------------------------------------
class _DC {
  _DC._();

  static const primary = Color(0xFF00231A);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF0F3A2E);
  static const onPrimaryContainer = Color(0xFF7AA494);
  static const primaryFixed = Color(0xFFC0ECDA);
  static const primaryFixedDim = Color(0xFFA4D0BF);
  static const onPrimaryFixedVariant = Color(0xFF254E41);

  static const secondary = Color(0xFF775A19);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFF785A19);
  static const secondaryFixed = Color(0xFFFFDEA3);
  static const secondaryFixedDim = Color(0xFFE8C176);
  static const onSecondaryFixed = Color(0xFF261900);

  static const background = Color(0xFFFBF9F5);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF5F3F0);
  static const surfaceContainer = Color(0xFFEFEEEA);
  static const surfaceContainerHigh = Color(0xFFE9E8E4);
  static const surfaceContainerHighest = Color(0xFFE4E2DF);

  static const onSurface = Color(0xFF1B1C1A);
  static const onSurfaceVariant = Color(0xFF414845);
  static const outlineVariant = Color(0xFFC0C8C3);

  static const error = Color(0xFFBA1A1A);
  static const onErrorContainer = Color(0xFF93000A);
  static const errorContainer = Color(0xFFFFDAD6);
}

class _DT {
  _DT._();
  static const _font = 'Nunito';

  static const headlineSm = TextStyle(
    fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w700, height: 24 / 18, color: _DC.primaryContainer,
  );
  static const headlineXs = TextStyle(
    fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w800, height: 16 / 13, color: _DC.onSurface,
  );
  static const bodyMd = TextStyle(
    fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14, color: _DC.onSurfaceVariant,
  );
  static const bodySm = TextStyle(
    fontFamily: _font, fontSize: 12.5, fontWeight: FontWeight.w400, height: 18 / 12.5, color: _DC.onSurfaceVariant,
  );
  static const labelLg = TextStyle(
    fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w700, height: 20 / 14, color: _DC.onSurface,
  );
  static const labelMd = TextStyle(
    fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w700, height: 16 / 12, color: _DC.onSurfaceVariant,
  );
  static const labelSm = TextStyle(
    fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w700, height: 14 / 11, color: _DC.onSurfaceVariant,
  );
}

/// ---------------------------------------------------------------------------
/// Model kartu santri untuk grid direktori.
///
/// CATATAN: `status` kehadiran/kesehatan harian (Hadir/Izin/Sakit) dan `poin`
/// takzir belum ada endpoint gabungannya di backend saat ini — nilainya di-
/// default-kan "Hadir" & 0 poin sebagai placeholder. Begitu ada endpoint
/// rekap Absensi/KesehatanLog/Pelanggaran per-tanggal, tinggal isi dua field
/// ini dari situ saat mapping response di `_load()`.
/// ---------------------------------------------------------------------------
class _SantriItem {
  final String id;
  final String nama;
  final String nis;
  final String kamar;
  String status;
  String? statusNote;
  int poin;

  _SantriItem({
    required this.id,
    required this.nama,
    required this.nis,
    required this.kamar,
    this.status = 'Hadir',
    this.statusNote,
    this.poin = 0,
  });

  String get initials {
    final parts = nama.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class DirektoriSantriScreen extends StatefulWidget {
  /// Kalau di-set, dipakai sebagai tombol back custom (misal saat screen ini
  /// di-swap in-place di dalam body ShellScreen, bukan lewat Navigator.push).
  final VoidCallback? onBack;

  /// Subjudul di bawah "Direktori Santri", contoh: "Musyrif Asrama Putra".
  final String subtitle;

  const DirektoriSantriScreen({
    super.key,
    this.onBack,
    this.subtitle = 'Musyrif • Santri Asuhan',
  });

  @override
  State<DirektoriSantriScreen> createState() => _DirektoriSantriScreenState();
}

class _DirektoriSantriScreenState extends State<DirektoriSantriScreen> {
  bool _loading = true;
  String? _error;
  List<_SantriItem> _all = [];

  final _searchCtrl = TextEditingController();
  String _query = '';
  String _roomFilter = 'Semua Kamar';
  String _statusFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool showSpinner = true}) async {
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final data = await api.get(ApiUrl.santri, query: {'perPage': '100'});
      // Endpoint bisa mengembalikan List langsung, atau Map berpaginasi
      // { items: [...], ... }. Tangani keduanya.
      final rawList = data is List ? data : ((data as Map)['items'] as List? ?? []);
      final list = rawList.map((e) {
        final m = (e as Map).cast<String, dynamic>();
        final asrama = (m['asrama'] as String?)?.trim();
        return _SantriItem(
          id: m['id'] as String,
          nama: (m['nama'] as String?) ?? '-',
          nis: (m['nis'] as String?) ?? '-',
          kamar: (asrama != null && asrama.isNotEmpty) ? asrama : 'Belum diatur',
        );
      }).toList();
      list.sort((a, b) => a.nama.compareTo(b.nama));
      if (!mounted) return;
      setState(() {
        _all = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Gagal memuat data santri: $e';
        _loading = false;
      });
    }
  }

  void _notAvailable() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Fitur ini akan segera tersedia.')));
  }

  List<String> get _rooms {
    final set = _all.map((e) => e.kamar).toSet().toList()..sort();
    return ['Semua Kamar', ...set];
  }

  List<_SantriItem> get _filtered {
    return _all.where((s) {
      final matchQuery = _query.isEmpty ||
          s.nama.toLowerCase().contains(_query) ||
          s.nis.toLowerCase().contains(_query);
      final matchRoom = _roomFilter == 'Semua Kamar' || s.kamar == _roomFilter;
      final matchStatus = _statusFilter == 'Semua' || s.status == _statusFilter;
      return matchQuery && matchRoom && matchStatus;
    }).toList();
  }

  int _countStatus(String status) => _all.where((e) => e.status == status).length;

  /// Badge blok di kanan ringkasan — diambil dari huruf sebelum tanda "-" pada
  /// kamar yang paling sering muncul (mis. "C-04" -> blok "C"). Kalau datanya
  /// campur/tidak ada pola, fallback ke teks generik.
  String get _blokBadge {
    final letters = <String, int>{};
    for (final s in _all) {
      final parts = s.kamar.split('-');
      if (parts.length >= 2 && parts[0].trim().isNotEmpty) {
        final letter = parts[0].trim().toUpperCase();
        letters[letter] = (letters[letter] ?? 0) + 1;
      }
    }
    if (letters.isEmpty) return 'Santri Asuhan';
    final top = letters.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return 'Blok ${top.key}';
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Sakit':
        return _DC.errorContainer;
      case 'Izin':
      case 'Izin Pulang':
        return _DC.secondaryFixed;
      default:
        return _DC.primaryFixed;
    }
  }

  Color _statusFg(String status) {
    switch (status) {
      case 'Sakit':
        return _DC.onErrorContainer;
      case 'Izin':
      case 'Izin Pulang':
        return _DC.onSecondaryFixed;
      default:
        return _DC.onPrimaryFixedVariant;
    }
  }

  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DC.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                _buildStickyBar(),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? _buildErrorView()
                          : RefreshIndicator(
                              onRefresh: () => _load(showSpinner: false),
                              child: _buildContent(),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambahSantriDialog,
        backgroundColor: _DC.primaryContainer,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text('Tambah Santri',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: _DC.error, size: 40),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: _DT.bodyMd),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 1. Header — judul, subjudul, aksi (cari, notifikasi, avatar)
  // ---------------------------------------------------------------------
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      decoration: BoxDecoration(
        color: _DC.background,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          if (widget.onBack != null) ...[
            IconButton(
              onPressed: widget.onBack,
              tooltip: 'Kembali',
              icon: const Icon(Icons.arrow_back, color: _DC.primary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
            ),
            const SizedBox(width: 2),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Direktori Santri', style: TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w800, color: _DC.primaryContainer)),
                const SizedBox(height: 1),
                Text(widget.subtitle, style: _DT.labelSm),
              ],
            ),
          ),
          IconButton(
            onPressed: () => FocusScope.of(context).requestFocus(FocusNode()),
            tooltip: 'Pencarian',
            icon: const Icon(Icons.search, color: _DC.onSurfaceVariant),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotifikasiScreen())),
                tooltip: 'Notifikasi',
                icon: const Icon(Icons.notifications_outlined, color: _DC.onSurfaceVariant),
              ),
              Positioned(
                top: 10, right: 10,
                child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: _DC.secondary, shape: BoxShape.circle)),
              ),
            ],
          ),
          Container(
            width: 32, height: 32,
            margin: const EdgeInsets.only(left: 2),
            decoration: const BoxDecoration(color: _DC.primary, shape: BoxShape.circle),
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 2. Search + filter chips (kamar, status) + ringkasan
  // ---------------------------------------------------------------------
  Widget _buildStickyBar() {
    return Container(
      color: _DC.background,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search box
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: _DC.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
            ),
            child: TextField(
              controller: _searchCtrl,
              style: _DT.bodyMd.copyWith(color: _DC.onSurface),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintText: 'Cari nama atau NIS santri...',
                hintStyle: _DT.bodyMd,
                prefixIcon: const Icon(Icons.search, size: 20, color: _DC.onSurfaceVariant),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 16, color: _DC.onSurfaceVariant),
                        onPressed: () => _searchCtrl.clear(),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Room chips
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final room in _rooms) ...[
                  _chip(
                    label: room,
                    selected: _roomFilter == room,
                    onTap: () => setState(() => _roomFilter = room),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Status chips
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _statusChip('Semua', _all.length),
                const SizedBox(width: 6),
                _statusChip('Hadir', _countStatus('Hadir'), dot: _DC.primaryFixedDim),
                const SizedBox(width: 6),
                _statusChip('Izin', _countStatus('Izin'), dot: _DC.secondaryFixed),
                const SizedBox(width: 6),
                _statusChip('Sakit', _countStatus('Sakit'), dot: _DC.error),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Summary line
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.verified, size: 15, color: _DC.secondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(style: _DT.labelSm, children: [
                          const TextSpan(text: 'Menampilkan '),
                          TextSpan(
                              text: '${_filtered.length} Santri ',
                              style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w800, color: _DC.primaryContainer)),
                          const TextSpan(text: 'Asuhan'),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _DC.secondaryFixed.withOpacity(0.5), borderRadius: BorderRadius.circular(999)),
                child: Text(_blokBadge, style: _DT.labelSm.copyWith(color: _DC.secondary, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip({required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _DC.primaryContainer : _DC.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 3)],
        ),
        alignment: Alignment.center,
        child: Text(label, style: _DT.labelMd.copyWith(color: selected ? Colors.white : _DC.onSurfaceVariant)),
      ),
    );
  }

  Widget _statusChip(String label, int count, {Color? dot}) {
    final selected = _statusFilter == label;
    return InkWell(
      onTap: () => setState(() => _statusFilter = label),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? _DC.surfaceContainerHighest : _DC.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(999),
          border: selected ? Border.all(color: _DC.primaryContainer, width: 1.4) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 3)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              const SizedBox(width: 5),
            ],
            Text(label, style: _DT.labelSm.copyWith(color: _DC.onSurface)),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: _DC.surfaceContainerLow, borderRadius: BorderRadius.circular(999)),
              child: Text('$count', style: const TextStyle(fontFamily: 'Nunito', fontSize: 9.5, fontWeight: FontWeight.w800, color: _DC.onSurface)),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 3. Grid konten + empty state + tips
  // ---------------------------------------------------------------------
  Widget _buildContent() {
    final filtered = _filtered;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      children: [
        if (filtered.isEmpty)
          _buildEmptyState()
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.74,
            ),
            itemBuilder: (_, i) => _santriCard(filtered[i]),
          ),
        const SizedBox(height: 20),
        _buildTipsCard(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(color: _DC.surfaceContainerHigh, shape: BoxShape.circle),
            child: const Icon(Icons.person_search, size: 30, color: _DC.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Text(_all.isEmpty ? 'Belum Ada Santri' : 'Santri Tidak Ditemukan', style: _DT.headlineSm.copyWith(fontSize: 16)),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _all.isEmpty
                  ? 'Belum ada data santri yang bisa ditampilkan di sini. Tambahkan santri lewat tombol "Tambah Santri" di bawah.'
                  : 'Coba gunakan kata kunci pencarian lain atau sesuaikan filter kamar & status santri.',
              textAlign: TextAlign.center,
              style: _DT.bodySm,
            ),
          ),
          if (_all.isNotEmpty) ...[
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _DC.primaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              onPressed: () => setState(() {
                _searchCtrl.clear();
                _roomFilter = 'Semua Kamar';
                _statusFilter = 'Semua';
              }),
              child: const Text('Reset Pencarian'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _DC.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: _DC.secondary.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.lightbulb_outline, size: 17, color: _DC.secondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pedoman Musyrif', style: _DT.labelLg.copyWith(color: _DC.primaryContainer)),
                const SizedBox(height: 2),
                Text(
                  'Ketuk kartu santri untuk membuka menu pembinaan harian: perizinan malam, pantau takzir, input kesehatan, dan rekap wali.',
                  style: _DT.bodySm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 4. Kartu santri
  // ---------------------------------------------------------------------
  Widget _santriCard(_SantriItem s) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openKelolaSheet(s),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _DC.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [_DC.primaryContainer, _DC.primary],
                ),
              ),
              alignment: Alignment.center,
              child: Text(s.initials, style: const TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            const SizedBox(height: 8),
            Text(s.nama, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: _DT.headlineXs),
            const SizedBox(height: 2),
            Text('NIS ${s.nis}', style: _DT.labelSm.copyWith(fontSize: 10.5)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: _DC.primaryFixed, borderRadius: BorderRadius.circular(999)),
              child: Text(s.kamar, style: _DT.labelSm.copyWith(color: _DC.onPrimaryFixedVariant, fontSize: 10.5)),
            ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 5, runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _statusBg(s.status), borderRadius: BorderRadius.circular(999)),
                  child: Text(s.status,
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 9.5, fontWeight: FontWeight.w800, color: _statusFg(s.status))),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: _DC.surfaceContainerHigh, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    s.poin > 0 ? '${s.poin}P' : (s.statusNote ?? '0 Poin'),
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 9.5, fontWeight: FontWeight.w700, color: _DC.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const Spacer(),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(color: _DC.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Kelola Santri', style: _DT.labelSm.copyWith(color: _DC.primaryContainer, fontWeight: FontWeight.w800)),
                  const Icon(Icons.expand_more, size: 15, color: _DC.primaryContainer),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 5. Bottom sheet aksi cepat per santri
  // ---------------------------------------------------------------------
  void _openKelolaSheet(_SantriItem s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _KelolaSantriSheet(
        santri: s,
        statusBg: _statusBg(s.status),
        statusFg: _statusFg(s.status),
        onDetail: _notAvailable,
        onPelanggaran: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PelanggaranScreen())),
        onIzin: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PerizinanScreen())),
        onKesehatan: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KesehatanScreen())),
        onKunjungan: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KunjunganScreen())),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 6. Dialog tambah santri
  // ---------------------------------------------------------------------
  Future<void> _tambahSantriDialog() async {
    final nama = TextEditingController();
    final nis = TextEditingController();
    final kamar = TextEditingController();
    final tahunMasuk = TextEditingController(text: '${DateTime.now().year}');
    String jenisKelamin = 'L';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Tambah Santri'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nama, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
                const SizedBox(height: 8),
                TextField(controller: nis, decoration: const InputDecoration(labelText: 'NIS')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: jenisKelamin,
                  decoration: const InputDecoration(labelText: 'Jenis Kelamin'),
                  items: const [
                    DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                    DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                  ],
                  onChanged: (v) => setSt(() => jenisKelamin = v ?? jenisKelamin),
                ),
                const SizedBox(height: 8),
                TextField(controller: kamar, decoration: const InputDecoration(labelText: 'Kamar / Asrama (mis. C-04)')),
                const SizedBox(height: 8),
                TextField(controller: tahunMasuk, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tahun Masuk')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (nama.text.trim().isEmpty || nis.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama dan NIS wajib diisi.')));
      return;
    }
    try {
      final api = AppScope.of(context).api;
      await api.post(ApiUrl.santri, {
        'nama': nama.text.trim(),
        'nis': nis.text.trim(),
        'jenisKelamin': jenisKelamin,
        'asrama': kamar.text.trim().isEmpty ? null : kamar.text.trim(),
        'tahunMasuk': int.tryParse(tahunMasuk.text.trim()) ?? DateTime.now().year,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Santri berhasil ditambahkan.')));
      _load(showSpinner: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menambahkan santri.')));
    }
  }
}

/// ---------------------------------------------------------------------------
/// Bottom sheet "Kelola Santri" — 5 aksi cepat, meniru drawer di desain HTML.
/// ---------------------------------------------------------------------------
class _KelolaSantriSheet extends StatelessWidget {
  final _SantriItem santri;
  final Color statusBg;
  final Color statusFg;
  final VoidCallback onDetail;
  final VoidCallback onPelanggaran;
  final VoidCallback onIzin;
  final VoidCallback onKesehatan;
  final VoidCallback onKunjungan;

  const _KelolaSantriSheet({
    required this.santri,
    required this.statusBg,
    required this.statusFg,
    required this.onDetail,
    required this.onPelanggaran,
    required this.onIzin,
    required this.onKesehatan,
    required this.onKunjungan,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          color: _DC.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(width: 44, height: 5, decoration: BoxDecoration(color: _DC.surfaceContainerHighest, borderRadius: BorderRadius.circular(999))),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(colors: [_DC.primaryContainer, _DC.primary]),
                    ),
                    alignment: Alignment.center,
                    child: Text(santri.initials, style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(santri.nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: _DT.headlineSm.copyWith(fontSize: 15)),
                        Text('NIS ${santri.nis} • ${santri.kamar}', maxLines: 1, overflow: TextOverflow.ellipsis, style: _DT.labelSm),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(999)),
                          child: Text(santri.status, style: TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w800, color: statusFg)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Column(
                children: [
                  _action(context, Icons.badge, 'Lihat Detail Santri', 'Biodata, riwayat akademik & rekam jejak',
                      _DC.primaryFixed, _DC.primaryContainer, onDetail),
                  _action(context, Icons.gavel, 'Input Pelanggaran', 'Catat indisipliner & tambah poin takzir',
                      _DC.errorContainer, _DC.error, onPelanggaran),
                  _action(context, Icons.logout, 'Ajukan Izin', 'Buat surat izin keluar atau pulang',
                      _DC.secondaryFixed, _DC.onSecondaryFixed, onIzin),
                  _action(context, Icons.health_and_safety, 'Catat Kesehatan', 'Periksa keluhan di Poskestren',
                      _DC.primaryFixedDim, _DC.primaryContainer, onKesehatan),
                  _action(context, Icons.diversity_1, 'Log Kunjungan Wali', 'Catat kedatangan orang tua atau tamu',
                      _DC.surfaceContainerHighest, _DC.onSurface, onKunjungan),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _DC.surfaceContainerHigh,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: const Text('Tutup', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: _DC.onSurface)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, String title, String subtitle, Color iconBg, Color iconFg, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: iconFg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _DT.labelLg.copyWith(fontSize: 14)),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: _DT.bodySm.copyWith(fontSize: 11.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: _DC.outlineVariant),
          ],
        ),
      ),
    );
  }
}