// notifikasi_ustadz_screen.dart  ->  simpan di lib/screens/master/ustadz/
//
// Notifikasi — Ustadz / Guru.
//
// Widget ini CUMA konten (tanpa Scaffold/AppBar/bottom nav). Dipasang sebagai
// `body` ShellScreen (sama seperti NotifikasiWaliScreen), jadi UstadzHeader &
// bottom nav Shell tetap kepakai.
//
// Memakai endpoint yang sama dengan role lain (ApiUrl.notifikasi); backend
// sudah men-scope per user yang login.
//
// Kategori (jenis di backend):
//   ABSENSI     -> pengingat absensi belum diisi
//   NILAI       -> pengingat input nilai / rapor
//   JADWAL      -> perubahan jadwal / kelas ampuan
//   PENGUMUMAN  -> pengumuman dari admin / pimpinan
// Jenis lain tetap tampil di tab "Semua" (kategori Info).

import 'package:flutter/material.dart';
import '../../../services/api_client.dart';
import '../../../services/app_scope.dart';
import '../../santri/santri_ui.dart';
import '../../ui_utils.dart';

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
  static const dot = Color(0xFFB91C1C);
}

enum _Kat { absensi, nilai, jadwal, pengumuman, lainnya }

enum _Filter { semua, belumDibaca, absensi, nilai, jadwal, pengumuman }

_Kat _katOf(String jenis) {
  final j = jenis.toUpperCase();
  if (j.contains('ABSENSI')) return _Kat.absensi;
  if (j.contains('NILAI') || j.contains('RAPOR')) return _Kat.nilai;
  if (j.contains('JADWAL')) return _Kat.jadwal;
  if (j.contains('PENGUMUMAN')) return _Kat.pengumuman;
  return _Kat.lainnya;
}

class NotifikasiUstadzScreen extends StatefulWidget {
  const NotifikasiUstadzScreen({
    super.key,
    required this.onBack,
    this.onNavigate,
    this.onReadStateChanged,
  });

  /// Tombol back. Biasanya: setState(() => _notifikasiOpen = false).
  final VoidCallback onBack;

  /// Diteruskan dari ShellScreen (`_goToMenu`) untuk tombol aksi di kartu.
  final void Function(String label)? onNavigate;

  /// Dipanggil tiap status baca berubah, supaya titik merah lonceng ikut update.
  final VoidCallback? onReadStateChanged;

  @override
  State<NotifikasiUstadzScreen> createState() => _NotifikasiUstadzScreenState();
}

class _NotifikasiUstadzScreenState extends State<NotifikasiUstadzScreen> {
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
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.notifikasi);
      if (!mounted) return;
      setState(() {
        _items = (res as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat notifikasi: $e';
          _loading = false;
        });
      }
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
      case _Filter.absensi:
        return k == _Kat.absensi;
      case _Filter.nilai:
        return k == _Kat.nilai;
      case _Filter.jadwal:
        return k == _Kat.jadwal;
      case _Filter.pengumuman:
        return k == _Kat.pengumuman;
    }
  }

  int _countFor(_Filter f) => _items.where((n) => _match(f, n)).length;

  List<Map<String, dynamic>> get _filtered => _items.where((n) => _match(_filter, n)).toList();

  /// "Perlu tindakan": pengingat absensi/nilai yang belum dibaca.
  int get _perluTindakan => _items.where((n) {
        final k = _katOf('${n['jenis']}');
        return _isUnread(n) && (k == _Kat.absensi || k == _Kat.nilai);
      }).length;

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
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 14),
                          _buildStatusCard(),
                          const SizedBox(height: 14),
                          _buildFilterChips(),
                          ..._buildGroupedList(),
                          const SizedBox(height: 12),
                          if (_unreadCount == 0 && _items.isNotEmpty) const _AllReadCard(),
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
        color: _NC.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _NC.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0F172A), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: _NC.mint,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: widget.onBack,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(Icons.arrow_back_rounded, size: 22, color: _NC.primary),
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
                            color: _NC.ink,
                            height: 1.15),
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
                  'Pengingat & kabar tugas mengajar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: _NC.inkSecondary),
                ),
              ],
            ),
          ),
          if (unread > 0) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: 'Tandai semua dibaca',
              child: Material(
                color: _NC.primary,
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
    final perlu = _perluTindakan;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_NC.primary, _NC.primaryEnd],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _NC.primary.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: const [
                Icon(Icons.circle, size: 8, color: _NC.gold),
                SizedBox(width: 6),
                Text('PENGINGAT USTADZ',
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
                child: const Text('Mode Mengajar', style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$_unreadCount',
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(width: 8),
              const Text('Belum Dibaca',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
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
                  const Icon(Icons.priority_high_rounded, size: 18, color: _NC.gold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(TextSpan(children: [
                      TextSpan(
                          text: '$perlu Perlu Tindakan: ',
                          style: const TextStyle(
                              color: _NC.goldLight, fontWeight: FontWeight.w700, fontSize: 12.5)),
                      const TextSpan(
                          text: 'ada pengingat absensi atau nilai yang belum Anda tindak lanjuti.',
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
    const entries = <MapEntry<_Filter, String>>[
      MapEntry(_Filter.semua, 'Semua'),
      MapEntry(_Filter.belumDibaca, 'Belum Dibaca'),
      MapEntry(_Filter.absensi, 'Absensi'),
      MapEntry(_Filter.nilai, 'Nilai'),
      MapEntry(_Filter.jadwal, 'Jadwal'),
      MapEntry(_Filter.pengumuman, 'Pengumuman'),
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
          final showDot = f == _Filter.belumDibaca && _unreadCount > 0;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? _NC.primary : _NC.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? _NC.primary : _NC.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showDot) ...[
                    Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: _NC.dot, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                  ],
                  Text('${entries[i].value} (${_countFor(f)})',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : _NC.inkSecondary)),
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
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(key,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: _NC.inkSecondary)),
            Text('${list.length} Kabar',
                style: const TextStyle(fontSize: 12, color: _NC.inkSecondary)),
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
    final aksi = _action(kat);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: unread ? _NC.surface : _NC.surfaceDim,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: unread ? _NC.border : Colors.transparent),
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
                    color: unread ? st.bg : _NC.border.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(st.icon, size: 20, color: unread ? st.fg : _NC.inkSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: unread ? st.bg : _NC.border.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(_katLabel(kat),
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: unread ? st.fg : _NC.inkSecondary)),
                      ),
                      const SizedBox(height: 8),
                      Text('${n['pesan']}',
                          style: TextStyle(
                              fontSize: 13.5,
                              height: 1.35,
                              color: _NC.ink,
                              fontWeight: unread ? FontWeight.w700 : FontWeight.w400)),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.schedule, size: 13, color: _NC.inkSecondary),
                        const SizedBox(width: 5),
                        Text(dt == null ? '-' : _relativeTime(dt),
                            style: const TextStyle(fontSize: 11.5, color: _NC.inkSecondary)),
                      ]),
                      if (aksi != null) ...[
                        const SizedBox(height: 10),
                        _ActionPill(
                          label: aksi.label,
                          onTap: () {
                            _markRead('${n['id']}');
                            widget.onNavigate?.call(aksi.menu);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                if (unread)
                  Container(
                    margin: const EdgeInsets.only(top: 4, left: 6),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: _NC.dot, shape: BoxShape.circle),
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
      case _Kat.absensi:
        return 'Absensi';
      case _Kat.nilai:
        return 'Nilai & Rapor';
      case _Kat.jadwal:
        return 'Jadwal Mengajar';
      case _Kat.pengumuman:
        return 'Pengumuman';
      case _Kat.lainnya:
        return 'Info';
    }
  }

  ({IconData icon, Color bg, Color fg}) _style(_Kat k) {
    switch (k) {
      case _Kat.absensi:
        return (icon: Icons.checklist, bg: _NC.mint, fg: _NC.primary);
      case _Kat.nilai:
        return (icon: Icons.grade_outlined, bg: const Color(0xFFFAF5EC), fg: _NC.gold);
      case _Kat.jadwal:
        return (icon: Icons.event_note_outlined, bg: const Color(0xFFFFE9B8), fg: const Color(0xFF7A5B10));
      case _Kat.pengumuman:
        return (icon: Icons.campaign_outlined, bg: _NC.sage, fg: _NC.primary);
      case _Kat.lainnya:
        return (icon: Icons.notifications_none, bg: _NC.sage, fg: _NC.primary);
    }
  }

  /// `menu` = label menu ustadz di ShellScreen (_goToMenu).
  ({String label, String menu})? _action(_Kat k) {
    switch (k) {
      case _Kat.absensi:
        return (label: 'Isi Absensi', menu: 'Absensi');
      case _Kat.nilai:
        return (label: 'Input Nilai', menu: 'Nilai');
      case _Kat.jadwal:
        return (label: 'Buka Beranda', menu: 'Dashboard');
      case _Kat.pengumuman:
      case _Kat.lainnya:
        return null;
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
  const _ActionPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _NC.primary,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}

class _AllReadCard extends StatelessWidget {
  const _AllReadCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(color: _NC.mint, borderRadius: BorderRadius.circular(22)),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _NC.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _NC.primary.withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(Icons.done_all_rounded, size: 28, color: _NC.primary),
          ),
          const SizedBox(height: 14),
          Text(
            'Semua kabar sudah dibaca',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _NC.primary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tidak ada pengingat baru. Kami akan memberi tahu saat ada tugas atau kabar baru.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _NC.inkSecondary, height: 1.45),
          ),
        ],
      ),
    );
  }
}