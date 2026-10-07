// notifikasi_admin_screen.dart  ->  simpan di lib/screens/admin/
//
// Notifikasi — Admin Lembaga (pondok).
//
// Widget ini CUMA konten (tanpa Scaffold/AppBar/bottomNavigationBar). Dipasang
// sebagai `body` ShellScreen (sama seperti NotifikasiSuperAdminScreen), jadi
// AdminHeader & bottom nav Shell tetap kepakai.
//
// Kategori notifikasi MENGIKUTI 5 toggle di Pengaturan Admin:
//   perizinanBaru      -> jenis PERIZINAN
//   pelanggaranBaru    -> jenis PELANGGARAN
//   waliBelumAktivasi  -> jenis mengandung WALI / AKTIVASI (mis. WALI_BELUM_AKTIVASI)
//   eskalasiDarurat    -> jenis DARURAT / KESEHATAN / KONSELING
//   rekapAbsensiShalat -> jenis ABSENSI / REKAP_ABSENSI
// Jenis lain yang tidak dikenal tetap tampil di tab "Semua" (kategori Lainnya).
// >> Kalau nama `jenis` di backend kamu beda, cukup ubah `_katOf()` di bawah.

import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../santri/santri_ui.dart';
import '../ui_utils.dart';

// ---------------------------------------------------------------------------
// Palet — nilai sama dengan _WC di dashboard_screen.dart
// ---------------------------------------------------------------------------
class _NC {
  _NC._();

  static Color get primary => SC.primary;
  static Color get primaryEnd => SC.primaryEnd;
  static const gold = Color(0xFFC5A059);
  static const goldLight = Color(0xFFF9D77E);
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
  static const dot = Color(0xFFB91C1C);
}

enum _Kat { perizinan, pelanggaran, wali, darurat, absensi, lainnya }

enum _Filter { semua, belumDibaca, perizinan, pelanggaran, wali, darurat, absensi }

_Kat _katOf(String jenis) {
  final j = jenis.toUpperCase();
  if (j.contains('PERIZINAN')) return _Kat.perizinan;
  if (j.contains('PELANGGARAN')) return _Kat.pelanggaran;
  if (j.contains('WALI') || j.contains('AKTIVASI')) return _Kat.wali;
  if (j.contains('DARURAT') || j.contains('KESEHATAN') || j.contains('KONSELING')) {
    return _Kat.darurat;
  }
  if (j.contains('ABSENSI') || j.contains('REKAP')) return _Kat.absensi;
  return _Kat.lainnya;
}

/// Kategori -> nama field toggle di Pengaturan Admin. null = selalu tampil.
String? _settingKey(_Kat k) {
  switch (k) {
    case _Kat.perizinan:
      return 'perizinanBaru';
    case _Kat.pelanggaran:
      return 'pelanggaranBaru';
    case _Kat.wali:
      return 'waliBelumAktivasi';
    case _Kat.darurat:
      return 'eskalasiDarurat';
    case _Kat.absensi:
      return 'rekapAbsensiShalat';
    case _Kat.lainnya:
      return null;
  }
}

class NotifikasiAdminScreen extends StatefulWidget {
  const NotifikasiAdminScreen({
    super.key,
    required this.onBack,
    this.onNavigate,
    this.onReadStateChanged,
  });

  /// Tombol back di header notifikasi. Biasanya: setState(() => _notifikasiOpen = false).
  final VoidCallback onBack;

  /// Diteruskan dari ShellScreen (`_goToMenu`) untuk tombol aksi di kartu.
  final void Function(String label)? onNavigate;

  /// Dipanggil tiap status baca berubah, supaya titik merah lonceng ikut update.
  final VoidCallback? onReadStateChanged;

  @override
  State<NotifikasiAdminScreen> createState() => _NotifikasiAdminScreenState();
}

class _NotifikasiAdminScreenState extends State<NotifikasiAdminScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  _Filter _filter = _Filter.semua;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  // ------------------------------------------------------------------ data
  Future<Map<String, bool>> _loadPref(ApiClient api) async {
    try {
      final res = await api.get('${ApiUrl.pengaturan}/admin') as Map<String, dynamic>;
      final n = (res['notifikasi'] as Map<String, dynamic>?) ?? {};
      return {
        for (final e in n.entries)
          if (e.value is bool) e.key: e.value as bool,
      };
    } catch (_) {
      return {}; // gagal ambil pengaturan -> tampilkan semua
    }
  }

  bool _enabled(Map<String, dynamic> n, Map<String, bool> pref) {
    final key = _settingKey(_katOf('${n['jenis']}'));
    if (key == null) return true;
    // Default sama seperti di Pengaturan: semua aktif kecuali rekap absensi.
    return pref[key] ?? (key != 'rekapAbsensiShalat');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final results = await Future.wait([
        api.get(ApiUrl.notifikasi),
        _loadPref(api),
      ]);
      if (!mounted) return;
      final all = (results[0] as List).cast<Map<String, dynamic>>();
      final pref = results[1] as Map<String, bool>;
      setState(() {
        _items = all.where((n) => _enabled(n, pref)).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Gagal memuat notifikasi: $e';
        _loading = false;
      });
    }
  }

  Future<void> _markRead(String id) async {
    final idx = _items.indexWhere((n) => n['id'] == id);
    if (idx == -1 || _items[idx]['statusBaca'] == true) return;
    setState(() => _items[idx] = {..._items[idx], 'statusBaca': true});
    try {
      await AppScope.of(context).api.patch('${ApiUrl.notifikasi}/$id/read', {});
      widget.onReadStateChanged?.call();
    } catch (_) {
      _load();
    }
  }

  Future<void> _markAllRead() async {
    final before = List<Map<String, dynamic>>.from(_items);
    setState(() => _items = _items.map((n) => {...n, 'statusBaca': true}).toList());
    try {
      await AppScope.of(context).api.post('${ApiUrl.notifikasi}/read-all', {});
      widget.onReadStateChanged?.call();
    } catch (_) {
      if (mounted) setState(() => _items = before);
    }
  }

  bool _isUnread(Map<String, dynamic> n) => n['statusBaca'] != true;

  int get _unreadCount => _items.where(_isUnread).length;

  bool _match(_Filter f, Map<String, dynamic> n) {
    final k = _katOf('${n['jenis']}');
    switch (f) {
      case _Filter.semua:
        return true;
      case _Filter.belumDibaca:
        return _isUnread(n);
      case _Filter.perizinan:
        return k == _Kat.perizinan;
      case _Filter.pelanggaran:
        return k == _Kat.pelanggaran;
      case _Filter.wali:
        return k == _Kat.wali;
      case _Filter.darurat:
        return k == _Kat.darurat;
      case _Filter.absensi:
        return k == _Kat.absensi;
    }
  }

  int _countFor(_Filter f) => _items.where((n) => _match(f, n)).length;

  List<Map<String, dynamic>> get _filtered => _items.where((n) => _match(_filter, n)).toList();

  /// "Mendesak": eskalasi darurat/medis yang belum dibaca.
  List<Map<String, dynamic>> get _urgent =>
      _items.where((n) => _isUnread(n) && _katOf('${n['jenis']}') == _Kat.darurat).toList();

  // ----------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _NC.background,
      child: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : RefreshIndicator(
                  color: _NC.primary,
                  onRefresh: _load,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 14),
                          _buildStatusCard(),
                          const SizedBox(height: 16),
                          _buildFilterChips(),
                          ..._buildGroupedList(),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  // ------------------------------------------------------------ header baru
  Widget _buildHeader() {
    // Admin: 'Pusat Informasi & Peringatan'
    // Wali : 'Kabar tentang anak Anda'
    const subtitle = 'Pusat Informasi & Peringatan';
    final unread = _unreadCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(
        color: _NC.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _NC.border),
        boxShadow: [
          BoxShadow(
            color: _NC.primary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tombol back
          Tooltip(
            message: 'Kembali',
            child: Material(
              color: _NC.mint,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: widget.onBack,
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _NC.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Judul + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Notifikasi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _NC.ink,
                          height: 1.1,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (unread > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _NC.dot,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 3,
                      decoration: BoxDecoration(
                        color: _NC.gold,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: _NC.inkSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Aksi kanan
          if (unread > 0)
            Tooltip(
              message: 'Tandai semua dibaca',
              child: Material(
                color: _NC.primary,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: _markAllRead,
                  borderRadius: BorderRadius.circular(16),
                  child: const SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(Icons.done_all_rounded, size: 20, color: Colors.white),
                  ),
                ),
              ),
            )
          else
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _NC.surfaceDim,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.notifications_none_rounded, size: 21, color: _NC.inkSecondary),
            ),
        ],
      ),
    );
  }

  // Kartu status gelap (sesuai screen.png)
  Widget _buildStatusCard() {
    final urgent = _urgent;
    final labels = urgent.map((n) => _katLabel(_katOf('${n['jenis']}'))).toSet().join(' & ');
    final total = _items.length;
    final progress = total == 0 ? 1.0 : (total - _unreadCount) / total;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_NC.primary, _NC.primaryEnd],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: _NC.primary.withOpacity(0.22), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Stack(
        children: [
          // Dekorasi lingkaran halus
          Positioned(
            right: -30,
            top: -34,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            right: 36,
            bottom: -44,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _NC.gold.withOpacity(0.10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: const [
                      Icon(Icons.circle, size: 8, color: _NC.gold),
                      SizedBox(width: 6),
                      Text('STATUS OPERASIONAL',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8)),
                    ]),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(999)),
                      child: const Text('Pekan Ini',
                          style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('$_unreadCount',
                        style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1)),
                    const SizedBox(width: 8),
                    const Text('Belum Dibaca',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    const Spacer(),
                    Text('dari $total notifikasi',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.65))),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.16),
                    valueColor: const AlwaysStoppedAnimation<Color>(_NC.goldLight),
                  ),
                ),
                const SizedBox(height: 6),
                Text('${(progress * 100).round()}% sudah dibaca',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
                if (urgent.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _NC.gold.withOpacity(0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.priority_high_rounded, size: 18, color: _NC.gold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(TextSpan(children: [
                            TextSpan(
                                text: '${urgent.length} Peringatan Mendesak: ',
                                style: const TextStyle(
                                    color: _NC.goldLight,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5)),
                            TextSpan(
                                text: '$labels membutuhkan tindak lanjut.',
                                style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                          ])),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    const entries = <MapEntry<_Filter, String>>[
      MapEntry(_Filter.semua, 'Semua'),
      MapEntry(_Filter.belumDibaca, 'Belum Dibaca'),
      MapEntry(_Filter.perizinan, 'Perizinan'),
      MapEntry(_Filter.pelanggaran, 'Pelanggaran'),
      MapEntry(_Filter.wali, 'Wali'),
      MapEntry(_Filter.darurat, 'Darurat'),
      MapEntry(_Filter.absensi, 'Absensi'),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = entries[i].key;
          final selected = _filter == f;
          final showDot = f == _Filter.belumDibaca && _unreadCount > 0;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              padding: const EdgeInsets.only(left: 14, right: 6),
              decoration: BoxDecoration(
                color: selected ? _NC.primary : _NC.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? _NC.primary : _NC.border),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _NC.primary.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showDot) ...[
                    Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: selected ? _NC.goldLight : _NC.dot, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                  ],
                  Text(entries[i].value,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : _NC.inkSecondary)),
                  const SizedBox(width: 6),
                  Container(
                    constraints: const BoxConstraints(minWidth: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white.withOpacity(0.2) : _NC.surfaceDim,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('${_countFor(f)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: selected ? Colors.white : _NC.ink)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildGroupedList() {
    final items = _filtered;
    if (items.isEmpty) {
      return [
        const SizedBox(height: 60),
        Center(
          child: emptyView(_items.isEmpty
              ? 'Belum ada notifikasi.'
              : 'Tidak ada notifikasi di kategori ini.'),
        ),
      ];
    }

    DateTime dtOf(Map<String, dynamic> n) =>
        DateTime.tryParse('${n['tanggal']}')?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);

    final sorted = [...items]..sort((a, b) => dtOf(b).compareTo(dtOf(a)));

    final groups = <String, List<Map<String, dynamic>>>{};
    for (final n in sorted) {
      groups.putIfAbsent(_dateKey(dtOf(n)), () => []).add(n);
    }

    final widgets = <Widget>[];
    groups.forEach((key, list) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 14,
              decoration: BoxDecoration(
                color: _NC.gold,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: _NC.inkSecondary)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: _NC.surfaceDim,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('${list.length} Aktivitas',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: _NC.inkSecondary)),
            ),
          ],
        ),
      ));
      widgets.addAll(list.map(_buildCard));
    });
    return widgets;
  }

  Widget _buildCard(Map<String, dynamic> n) {
    final kat = _katOf('${n['jenis']}');
    final st = _style(kat);
    final unread = _isUnread(n);
    final dt = DateTime.tryParse('${n['tanggal']}')?.toLocal();
    // Sub-label opsional ("Terlambat", "Rujukan RSUD", dst) kalau backend mengirimnya.
    final sub = (n['subjenis'] ?? n['label']);
    final tag = (sub is String && sub.trim().isNotEmpty)
        ? '${_katLabel(kat)} • $sub'
        : _katLabel(kat);
    final aksi = _actions(kat);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: unread ? _NC.surface : _NC.surfaceDim,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: unread ? _NC.border : Colors.transparent),
        boxShadow: unread
            ? [
                BoxShadow(
                  color: _NC.ink.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _markRead('${n['id']}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: unread ? st.bg : _NC.border.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(st.icon, size: 21, color: unread ? st.fg : _NC.inkSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: unread ? st.bg : _NC.border.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(tag,
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                                color: unread ? st.fg : _NC.inkSecondary)),
                      ),
                      const SizedBox(height: 8),
                      Text('${n['pesan']}',
                          style: TextStyle(
                              fontSize: 13.5,
                              height: 1.4,
                              color: _NC.ink,
                              fontWeight: unread ? FontWeight.w700 : FontWeight.w400)),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.schedule_rounded, size: 13, color: _NC.inkSecondary),
                        const SizedBox(width: 5),
                        Text(dt == null ? '-' : _relativeTime(dt),
                            style: const TextStyle(fontSize: 11.5, color: _NC.inkSecondary)),
                      ]),
                      if (aksi.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            for (int i = 0; i < aksi.length; i++)
                              _ActionPill(
                                label: aksi[i].label,
                                filled: i == 0,
                                onTap: () {
                                  _markRead('${n['id']}');
                                  widget.onNavigate?.call(aksi[i].menu);
                                },
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (unread)
                  Container(
                    margin: const EdgeInsets.only(top: 4, left: 6),
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                        color: kat == _Kat.pelanggaran ? _NC.goldLight : _NC.dot,
                        shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- helpers
  String _katLabel(_Kat k) {
    switch (k) {
      case _Kat.perizinan:
        return 'Perizinan';
      case _Kat.pelanggaran:
        return 'Pelanggaran';
      case _Kat.wali:
        return 'Aktivasi Wali';
      case _Kat.darurat:
        return 'Darurat';
      case _Kat.absensi:
        return 'Absensi';
      case _Kat.lainnya:
        return 'Info';
    }
  }

  ({IconData icon, Color bg, Color fg}) _style(_Kat k) {
    switch (k) {
      case _Kat.perizinan:
        return (icon: Icons.exit_to_app, bg: _NC.errorBg, fg: _NC.errorText);
      case _Kat.pelanggaran:
        return (icon: Icons.gavel, bg: const Color(0xFFFFE9B8), fg: const Color(0xFF7A5B10));
      case _Kat.wali:
        return (icon: Icons.family_restroom, bg: const Color(0xFFFAF5EC), fg: _NC.gold);
      case _Kat.darurat:
        return (icon: Icons.medical_services_outlined, bg: _NC.errorBg, fg: _NC.errorText);
      case _Kat.absensi:
        return (icon: Icons.checklist, bg: _NC.mint, fg: _NC.primary);
      case _Kat.lainnya:
        return (icon: Icons.notifications_none, bg: _NC.sage, fg: _NC.primary);
    }
  }

  /// Tombol aksi per kategori. `menu` = label menu di ShellScreen (_goToMenu).
  List<({String label, String menu})> _actions(_Kat k) {
    switch (k) {
      case _Kat.perizinan:
        return [(label: 'Lihat Izin', menu: 'Perizinan')];
      case _Kat.pelanggaran:
        return [(label: 'Lihat Pelanggaran', menu: 'Pelanggaran')];
      case _Kat.wali:
        return [(label: 'Kelola Akun', menu: 'Kelola User')];
      case _Kat.darurat:
        return [(label: 'Detail', menu: 'Keadaan Darurat')];
      case _Kat.absensi:
        return [(label: 'Lihat Absensi', menu: 'Absensi')];
      case _Kat.lainnya:
        return [];
    }
  }

  static const _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  String _dateKey(DateTime dt) {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(dt.year, dt.month, dt.day))
        .inDays;
    final f = '${dt.day} ${_bulan[dt.month - 1]} ${dt.year}'.toUpperCase();
    if (diff == 0) return 'HARI INI ($f)';
    if (diff == 1) return 'KEMARIN ($f)';
    return f;
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB';
  }
}

// ============================================================================
// Widget kecil
// ============================================================================

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.label, required this.filled, required this.onTap});

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? _NC.primary : _NC.surfaceDim,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 34,
          padding: const EdgeInsets.only(left: 14, right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: filled ? null : Border.all(color: _NC.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: filled ? Colors.white : _NC.inkSecondary)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded,
                  size: 14, color: filled ? Colors.white : _NC.inkSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu "semua sudah dibaca" — tampil di bawah daftar kalau tidak ada yang belum dibaca.
class _AllReadCard extends StatelessWidget {
  const _AllReadCard({
    this.title = 'Semua notifikasi sudah dibaca',
    this.subtitle =
        'Tidak ada peringatan baru saat ini. Kami akan memberi tahu saat ada perizinan, pelanggaran, atau kabar penting lainnya.',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_NC.mint, _NC.surface],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _NC.primary.withOpacity(0.10)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -26,
            top: -26,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _NC.primary.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            right: -20,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _NC.gold.withOpacity(0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
            child: Column(
              children: [
                // Ikon bertingkat
                Container(
                  width: 92,
                  height: 92,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _NC.primary.withOpacity(0.07),
                  ),
                  child: Container(
                    width: 70,
                    height: 70,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _NC.primary.withOpacity(0.10),
                    ),
                    child: Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_NC.primary, _NC.primaryEnd],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _NC.primary.withOpacity(0.30),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.done_all_rounded, size: 26, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _NC.ink,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, color: _NC.inkSecondary, height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _NC.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _NC.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_outlined, size: 14, color: _NC.primary),
                      const SizedBox(width: 6),
                      const Text('Semua sudah terbaca',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _NC.inkSecondary)),
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
}