// notifikasi_wali_screen.dart  ->  simpan di lib/screens/wali/
//
// Notifikasi — Wali Santri.
//
// Widget ini CUMA konten (tanpa Scaffold/AppBar/bottomNavigationBar). Dipasang
// sebagai `body` ShellScreen (sama seperti NotifikasiAdminScreen), jadi
// WaliHeader & bottom nav Shell tetap kepakai.
//
// Beda dengan versi Admin: penyaringan kategori yang dimatikan di Pengaturan
// Wali dilakukan di BACKEND (NotifikasiService), jadi daftar & badge lonceng
// selalu konsisten. Di sini cuma tampilan + filter chip.
//
// Kategori (jenis di backend -> toggle Pengaturan Wali):
//   PERIZINAN   -> perizinanAnak
//   PELANGGARAN -> pelanggaranAnak
//   KESEHATAN   -> kesehatanAnak
//   NILAI       -> nilaiRapor
//   ABSENSI     -> absensiAnak
//   DARURAT     -> selalu tampil (tidak ada toggle)
// Jenis lain tetap tampil di tab "Semua" (kategori Info).

import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../santri/santri_ui.dart';
import '../ui_utils.dart';

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

enum _Kat { perizinan, pelanggaran, kesehatan, nilai, absensi, darurat, lainnya }

enum _Filter { semua, belumDibaca, perizinan, pelanggaran, kesehatan, nilai, absensi, darurat }

_Kat _katOf(String jenis) {
  final j = jenis.toUpperCase();
  if (j.contains('PERIZINAN')) return _Kat.perizinan;
  if (j.contains('PELANGGARAN')) return _Kat.pelanggaran;
  if (j.contains('DARURAT')) return _Kat.darurat;
  if (j.contains('KESEHATAN')) return _Kat.kesehatan;
  if (j.contains('NILAI') || j.contains('RAPOR')) return _Kat.nilai;
  if (j.contains('ABSENSI')) return _Kat.absensi;
  return _Kat.lainnya;
}

class NotifikasiWaliScreen extends StatefulWidget {
  const NotifikasiWaliScreen({
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
  State<NotifikasiWaliScreen> createState() => _NotifikasiWaliScreenState();
}

class _NotifikasiWaliScreenState extends State<NotifikasiWaliScreen> {
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
      case _Filter.perizinan:
        return k == _Kat.perizinan;
      case _Filter.pelanggaran:
        return k == _Kat.pelanggaran;
      case _Filter.kesehatan:
        return k == _Kat.kesehatan;
      case _Filter.nilai:
        return k == _Kat.nilai;
      case _Filter.absensi:
        return k == _Kat.absensi;
      case _Filter.darurat:
        return k == _Kat.darurat;
    }
  }

  int _countFor(_Filter f) => _items.where((n) => _match(f, n)).length;

  List<Map<String, dynamic>> get _filtered => _items.where((n) => _match(_filter, n)).toList();

  /// "Penting": kabar darurat yang belum dibaca.
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
    // Admin: 'Pusat Informasi & Peringatan'
    // Wali : 'Kabar tentang anak Anda'
    const subtitle = 'Kabar tentang anak Anda';
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
                  subtitle,
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

  // Header versi sebelumnya, tidak dipakai lagi. Boleh dihapus.
  // ignore: unused_element
  Widget _buildHeaderLama2() {
    // Admin: 'Pusat Informasi & Peringatan'
    // Wali : 'Kabar tentang anak Anda'
    const subtitle = 'Kabar tentang anak Anda';
    final unread = _unreadCount;

    return Row(
      children: [
        InkResponse(
          onTap: widget.onBack,
          radius: 24,
          child: const Padding(
            padding: EdgeInsets.fromLTRB(0, 10, 14, 10),
            child: Icon(Icons.arrow_back_rounded, size: 24, color: _NC.ink),
          ),
        ),
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
                          fontSize: 21, fontWeight: FontWeight.w800, color: _NC.ink, height: 1.15),
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
                              fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: _NC.inkSecondary),
              ),
            ],
          ),
        ),
        if (unread > 0) ...[
          const SizedBox(width: 8),
          _HeaderIconButton(
            icon: Icons.done_all_rounded,
            tooltip: 'Tandai semua dibaca',
            tinted: true,
            onTap: _markAllRead,
          ),
        ],
      ],
    );
  }

  // Header lama, tidak dipakai lagi. Boleh dihapus.
  Widget _buildHeaderLama() {
    return Row(
      children: [
        IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back, color: _NC.ink),
        ),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notifikasi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _NC.ink)),
              Text('Kabar tentang anak Anda',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: _NC.inkSecondary)),
            ],
          ),
        ),
        if (_unreadCount > 0)
          Material(
            color: _NC.surfaceDim,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: _markAllRead,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.done_all, size: 16, color: _NC.ink),
                    SizedBox(width: 6),
                    Text('Tandai Dibaca',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _NC.ink)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusCard() {
    final urgent = _urgent;
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
                Text('KABAR SANTRI',
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
                child: const Text('Mode Pantau', style: TextStyle(color: Colors.white, fontSize: 11)),
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
          if (urgent.isNotEmpty) ...[
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
                          text: '${urgent.length} Kabar Penting: ',
                          style: const TextStyle(
                              color: _NC.goldLight, fontWeight: FontWeight.w700, fontSize: 12.5)),
                      const TextSpan(
                          text: 'ada informasi keadaan darurat yang perlu Anda baca.',
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
      MapEntry(_Filter.perizinan, 'Perizinan'),
      MapEntry(_Filter.pelanggaran, 'Pelanggaran'),
      MapEntry(_Filter.kesehatan, 'Kesehatan'),
      MapEntry(_Filter.nilai, 'Nilai'),
      MapEntry(_Filter.absensi, 'Absensi'),
      MapEntry(_Filter.darurat, 'Darurat'),
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
    final sub = (n['subjenis'] ?? n['label']);
    final tag = (sub is String && sub.trim().isNotEmpty)
        ? '${_katLabel(kat)} • $sub'
        : _katLabel(kat);
    final aksi = _actions(kat);

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
                        child: Text(tag,
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
                      if (aksi.isNotEmpty) ...[
                        const SizedBox(height: 10),
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
                    width: 8,
                    height: 8,
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
      case _Kat.kesehatan:
        return 'Kesehatan';
      case _Kat.nilai:
        return 'Nilai & Rapor';
      case _Kat.absensi:
        return 'Absensi';
      case _Kat.darurat:
        return 'Darurat';
      case _Kat.lainnya:
        return 'Info';
    }
  }

  ({IconData icon, Color bg, Color fg}) _style(_Kat k) {
    switch (k) {
      case _Kat.perizinan:
        return (icon: Icons.exit_to_app, bg: _NC.mint, fg: _NC.primary);
      case _Kat.pelanggaran:
        return (icon: Icons.gavel, bg: const Color(0xFFFFE9B8), fg: const Color(0xFF7A5B10));
      case _Kat.kesehatan:
        return (icon: Icons.medical_services_outlined, bg: _NC.errorBg, fg: _NC.errorText);
      case _Kat.nilai:
        return (icon: Icons.grade_outlined, bg: const Color(0xFFFAF5EC), fg: _NC.gold);
      case _Kat.absensi:
        return (icon: Icons.checklist, bg: _NC.mint, fg: _NC.primary);
      case _Kat.darurat:
        return (icon: Icons.emergency, bg: _NC.errorBg, fg: _NC.errorText);
      case _Kat.lainnya:
        return (icon: Icons.notifications_none, bg: _NC.sage, fg: _NC.primary);
    }
  }

  /// Tombol aksi per kategori. `menu` = label menu wali di ShellScreen (_goToMenu).
  List<({String label, String menu})> _actions(_Kat k) {
    switch (k) {
      case _Kat.perizinan:
        return [(label: 'Lihat Izin', menu: 'Perizinan')];
      case _Kat.pelanggaran:
        return [(label: 'Lihat Pelanggaran', menu: 'Pelanggaran')];
      case _Kat.kesehatan:
      case _Kat.darurat:
        return [(label: 'Lihat Data Anak', menu: 'Anak Saya')];
      case _Kat.nilai:
        return [(label: 'Lihat Nilai', menu: 'Anak Saya')];
      case _Kat.absensi:
        return [(label: 'Lihat Kehadiran', menu: 'Anak Saya')];
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.tinted = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: tinted ? _NC.mint : _NC.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tinted ? _NC.primary.withOpacity(0.15) : _NC.border),
            ),
            child: Icon(icon, size: 20, color: tinted ? _NC.primary : _NC.ink),
          ),
        ),
      ),
    );
  }
}

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
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: filled ? null : Border.all(color: _NC.border),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : _NC.inkSecondary)),
        ),
      ),
    );
  }
}

class _AllClearFooter extends StatelessWidget {
  const _AllClearFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _NC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _NC.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: _NC.mint, shape: BoxShape.circle),
            child: Icon(Icons.check_circle_outline, color: _NC.primary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Semua Kabar Sudah Dibaca',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _NC.ink)),
                SizedBox(height: 2),
                Text('Tidak ada kabar baru tentang anak Anda saat ini.',
                    style: TextStyle(fontSize: 12, color: _NC.inkSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _AllReadCard extends StatelessWidget {
  const _AllReadCard({
    this.title = 'Semua kabar sudah dibaca',
    this.subtitle =
        'Tidak ada kabar baru tentang anak Anda. Kami akan memberi tahu saat ada perkembangan.',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: _NC.mint,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _NC.primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Container(
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
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _NC.primary),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: _NC.inkSecondary, height: 1.45),
          ),
        ],
      ),
    );
  }
}