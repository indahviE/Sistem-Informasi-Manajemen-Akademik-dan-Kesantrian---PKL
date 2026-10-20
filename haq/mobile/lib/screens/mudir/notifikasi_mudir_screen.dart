// notifikasi_mudir_screen.dart
//
// Notifikasi — Mudir.
//
// Konten saja (tanpa Scaffold/AppBar/bottom nav), dipasang sebagai body
// ShellScreen. Tampilan disamakan dengan NotifikasiUstadzScreen.
//
// Jenis notifikasi mengikuti toggle di Pengaturan Mudir:
//   RINGKASAN_HARIAN, LAPORAN_KESANTRIAN, PENDAFTARAN_BARU, LAPORAN_KEUANGAN
// (nilai `jenis` ini harus sama dengan yang dikirim backend).
//
// Warna utama ikut tema pondok (SC.*), jadi widget yang memakai warna tema
// TIDAK dibuat const.

import 'package:flutter/material.dart';
import 'package:sim_pesantren/services/api_client.dart';
import 'package:sim_pesantren/services/app_scope.dart';
import 'package:sim_pesantren/screens/santri/santri_ui.dart';

class _NM {
  _NM._();

  // Dinamis: ikut tema pondok.
  static Color get primary => SC.primary;
  static Color get primaryEnd => SC.primaryEnd;
  static Color get mint => SC.mint;
  static Color get sage => SC.sage;

  static const gold = Color(0xFFC5A059);
  static const goldLight = Color(0xFFF9D77E);

  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);
  static const border = Color(0xFFEAE6DC);

  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);

  static const dot = Color(0xFFB91C1C);
  static const errorBg = Color(0xFFFEE2E2);
  static const errorText = Color(0xFF991B1B);
}

// Nilai `jenis` dari backend.
const _kRingkasan = 'RINGKASAN_HARIAN';
const _kKesantrian = 'LAPORAN_KESANTRIAN';
const _kPendaftaran = 'PENDAFTARAN_BARU';
const _kKeuangan = 'LAPORAN_KEUANGAN';

enum _NotifFilter { semua, belumDibaca, ringkasan, kesantrian, pendaftaran, keuangan }

class NotifikasiMudirScreen extends StatefulWidget {
  const NotifikasiMudirScreen({
    super.key,
    required this.onBack,
    this.onNavigate,
    this.onReadStateChanged,
  });

  /// Tombol back di header. Biasanya: setState(() => _notifikasiOpen = false).
  final VoidCallback onBack;

  /// Tidak dipakai lagi (tombol aksi di kartu dihapus). Dipertahankan supaya
  /// pemanggil di ShellScreen tidak perlu diubah.
  final void Function(String label)? onNavigate;

  /// Dipanggil setiap status baca berubah, supaya titik merah di lonceng
  /// header ikut ter-update.
  final VoidCallback? onReadStateChanged;

  @override
  State<NotifikasiMudirScreen> createState() => _NotifikasiMudirScreenState();
}

class _NotifikasiMudirScreenState extends State<NotifikasiMudirScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _initialized = false;
  String? _error;
  _NotifFilter _filter = _NotifFilter.semua;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  // ------------------------------------------------------------------ data

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.notifikasi);
      if (!mounted) return;
      setState(() {
        _items = (res as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal memuat notifikasi: $e';
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
      _load(); // sinkron ulang dari server
    }
  }

  Future<void> _markAllRead() async {
    final before = List<Map<String, dynamic>>.from(_items);
    setState(() {
      _items = _items.map((n) => {...n, 'statusBaca': true}).toList();
    });
    try {
      await AppScope.of(context).api.post('${ApiUrl.notifikasi}/read-all', {});
      widget.onReadStateChanged?.call();
    } catch (_) {
      if (mounted) setState(() => _items = before);
    }
  }

  bool _isUnread(Map<String, dynamic> n) => n['statusBaca'] != true;

  int get _unreadCount => _items.where(_isUnread).length;

  String? _jenisOf(_NotifFilter f) {
    switch (f) {
      case _NotifFilter.ringkasan:
        return _kRingkasan;
      case _NotifFilter.kesantrian:
        return _kKesantrian;
      case _NotifFilter.pendaftaran:
        return _kPendaftaran;
      case _NotifFilter.keuangan:
        return _kKeuangan;
      default:
        return null;
    }
  }

  List<Map<String, dynamic>> _itemsFor(_NotifFilter f) {
    if (f == _NotifFilter.semua) return _items;
    if (f == _NotifFilter.belumDibaca) return _items.where(_isUnread).toList();
    final j = _jenisOf(f);
    return _items.where((n) => n['jenis'] == j).toList();
  }

  int _countFor(_NotifFilter f) => _itemsFor(f).length;

  /// "Perlu perhatian": laporan kesantrian yang belum dibaca
  /// (pelanggaran, perizinan, kasus santri).
  int get _perluPerhatian =>
      _items.where((n) => _isUnread(n) && n['jenis'] == _kKesantrian).length;

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _NM.background,
      child: _loading
          ? Center(child: CircularProgressIndicator(color: _NM.primary))
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: _NM.primary,
                  onRefresh: _load,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 14),
                          _buildStatusCard(),
                          const SizedBox(height: 14),
                          _buildFilterChips(),
                          ..._buildGroupedList(),
                          const SizedBox(height: 12),
                          if (_unreadCount == 0 && _items.isNotEmpty) _AllReadCard(),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    final unread = _unreadCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
      decoration: BoxDecoration(
        color: _NM.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _NM.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0F172A), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: _NM.mint,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: widget.onBack,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(Icons.arrow_back_rounded, size: 22, color: _NM.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Notifikasi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _NM.ink,
                            height: 1.15),
                      ),
                    ),
                    if (unread > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _NM.dot,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('$unread',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Kabar & laporan pondok',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: _NM.inkSecondary),
                ),
              ],
            ),
          ),
          if (unread > 0) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: 'Tandai semua dibaca',
              child: Material(
                color: _NM.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _markAllRead,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(Icons.done_all_rounded, size: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final perlu = _perluPerhatian;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_NM.primary, _NM.primaryEnd],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _NM.primary.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: const [
                Icon(Icons.circle, size: 8, color: _NM.gold),
                SizedBox(width: 6),
                Text('RINGKASAN PONDOK',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(999)),
                child: const Text('Mode Memantau',
                    style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$_unreadCount',
                  style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(width: 8),
              const Text('Belum Dibaca',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
              const Spacer(),
              Text('dari ${_items.length} notifikasi',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
            ],
          ),
          if (perlu > 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.priority_high_rounded, size: 18, color: _NM.gold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(TextSpan(children: [
                      TextSpan(
                          text: '$perlu Laporan Kesantrian: ',
                          style: const TextStyle(
                              color: _NM.goldLight,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5)),
                      const TextSpan(
                          text: 'ada kabar santri yang perlu perhatian Anda.',
                          style: TextStyle(color: Colors.white, fontSize: 12.5)),
                    ])),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    const entries = <MapEntry<_NotifFilter, String>>[
      MapEntry(_NotifFilter.semua, 'Semua'),
      MapEntry(_NotifFilter.belumDibaca, 'Belum Dibaca'),
      MapEntry(_NotifFilter.ringkasan, 'Ringkasan'),
      MapEntry(_NotifFilter.kesantrian, 'Kesantrian'),
      MapEntry(_NotifFilter.pendaftaran, 'Pendaftaran'),
      MapEntry(_NotifFilter.keuangan, 'Keuangan'),
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = entries[i].key;
          final selected = _filter == f;
          final showDot = f == _NotifFilter.belumDibaca && _unreadCount > 0;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? _NM.primary : _NM.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? _NM.primary : _NM.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showDot) ...[
                    Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: _NM.dot, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                  ],
                  Text('${entries[i].value} (${_countFor(f)})',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : _NM.inkSecondary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildGroupedList() {
    final items = _itemsFor(_filter);
    if (items.isEmpty) {
      return [
        const SizedBox(height: 60),
        Center(
          child: Column(
            children: [
              Icon(Icons.notifications_off_outlined,
                  size: 40, color: _NM.inkSecondary.withOpacity(0.5)),
              const SizedBox(height: 10),
              Text(
                _items.isEmpty
                    ? 'Belum ada notifikasi.'
                    : 'Tidak ada notifikasi di kategori ini.',
                style: const TextStyle(fontSize: 13, color: _NM.inkSecondary),
              ),
            ],
          ),
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
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(key,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: _NM.inkSecondary)),
            Text('${list.length} Kabar',
                style: const TextStyle(fontSize: 12, color: _NM.inkSecondary)),
          ],
        ),
      ));
      widgets.addAll(list.map(_buildCard));
    });
    return widgets;
  }

  Widget _buildCard(Map<String, dynamic> n) {
    final jenis = '${n['jenis']}';
    final st = _style(jenis);
    final unread = _isUnread(n);
    final dt = DateTime.tryParse('${n['tanggal']}')?.toLocal();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: unread ? _NM.surface : _NM.surfaceDim,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: unread ? _NM.border : Colors.transparent),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _markRead('${n['id']}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: unread ? st.bg : _NM.border.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(st.icon, size: 20, color: unread ? st.fg : _NM.inkSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: unread ? st.bg : _NM.border.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(_jenisLabel(jenis),
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: unread ? st.fg : _NM.inkSecondary)),
                      ),
                      const SizedBox(height: 8),
                      Text('${n['pesan']}',
                          style: TextStyle(
                              fontSize: 13.5,
                              height: 1.35,
                              color: _NM.ink,
                              fontWeight: unread ? FontWeight.w700 : FontWeight.w400)),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.schedule, size: 13, color: _NM.inkSecondary),
                        const SizedBox(width: 5),
                        Text(dt == null ? '-' : _relativeTime(dt),
                            style: const TextStyle(fontSize: 11.5, color: _NM.inkSecondary)),
                      ]),
                    ],
                  ),
                ),
                if (unread)
                  Container(
                    margin: const EdgeInsets.only(top: 4, left: 6),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: _NM.dot, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- helpers

  String _jenisLabel(String jenis) {
    switch (jenis) {
      case _kRingkasan:
        return 'Ringkasan Harian';
      case _kKesantrian:
        return 'Kesantrian';
      case _kPendaftaran:
        return 'Pendaftaran Baru';
      case _kKeuangan:
        return 'Keuangan';
      default:
        return 'Info';
    }
  }

  ({IconData icon, Color bg, Color fg}) _style(String jenis) {
    switch (jenis) {
      case _kRingkasan:
        return (icon: Icons.today_outlined, bg: _NM.mint, fg: _NM.primary);
      case _kKesantrian:
        return (icon: Icons.shield_outlined, bg: _NM.errorBg, fg: const Color(0xFFDC2626));
      case _kPendaftaran:
        return (
          icon: Icons.person_add_alt_outlined,
          bg: const Color(0xFFCCFBF1),
          fg: const Color(0xFF0D9488)
        );
      case _kKeuangan:
        return (
          icon: Icons.account_balance_wallet_outlined,
          bg: const Color(0xFFFFE9B8),
          fg: const Color(0xFF7A5B10)
        );
      default:
        return (icon: Icons.notifications_none, bg: _NM.sage, fg: _NM.primary);
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

class _AllReadCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(color: _NM.mint, borderRadius: BorderRadius.circular(22)),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _NM.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _NM.primary.withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(Icons.done_all_rounded, size: 28, color: _NM.primary),
          ),
          const SizedBox(height: 14),
          Text(
            'Semua kabar sudah dibaca',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _NM.primary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tidak ada kabar baru. Kesantrian, pendaftaran, dan keuangan pondok akan tercatat di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _NM.inkSecondary, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: _NM.errorBg, shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off_rounded, color: _NM.errorText, size: 30),
            ),
            const SizedBox(height: 14),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _NM.inkSecondary, height: 1.4)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              style: FilledButton.styleFrom(backgroundColor: _NM.primary),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}