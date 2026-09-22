// notifikasi_superadmin_screen.dart
//
// Notifikasi — Super Admin
//
// Data & logic TIDAK berubah: tetap hanya 4 jenis yang pernah dikirim lewat
// NotifikasiService.kirimKeSuperAdmin() di backend (TENANT_BARU, TAGIHAN,
// KEAMANAN, LAPORAN). Backend sudah scope notifikasi ini ke akun Super Admin
// yang login (lihat NotifikasiService.scope()), jadi tidak perlu filter role
// manual.
//
// Widget ini CUMA konten (tidak punya Scaffold/AppBar/bottomNavigationBar
// sendiri). Ia dipasang sebagai `body` ShellScreen — mirip mekanisme
// "Lainnya" yang sudah ada — bukan lewat Navigator.push, supaya AppBar
// (SuperAdminHeader) & bottom nav asli ShellScreen otomatis tetap kepakai,
// tidak perlu duplikat top bar / bottom nav sendiri lagi.
//
// Warna memakai palet `_SC` yang nilainya DISAMAKAN PERSIS dengan class
// `_WC` di dashboard_screen.dart (dikalibrasi mengikuti screen.png untuk
// section Super Admin) — bukan tebakan PColors. `_WC` sendiri `private` ke
// dashboard_screen.dart jadi tidak bisa di-import; nilai hex-nya di-mirror
// di sini supaya identik.
//
// Cara pakai dari shell.dart: lihat `_notifikasiOpen` di ShellScreen.

import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';

/// ---------------------------------------------------------------------------
/// Palet Super Admin — nilai di-mirror 1:1 dari `_WC` di dashboard_screen.dart
/// supaya identik dengan Beranda, Tenant, Audit Log, Billing & Pengaturan.
/// ---------------------------------------------------------------------------
class _SC {
  _SC._();

  static const primary = Color(0xFF0F3A2E);
  static const primaryGradientEnd = Color(0xFF164E3D);

  static const gold = Color(0xFFC5A059);
  static const goldSurface = Color(0xFFFAF5EC);
  static const goldBorder = Color(0xFFE7D2A7);

  static const mint = Color(0xFFD2E4DC);
  static const sage = Color(0xFFE2ECE9);

  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);

  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);

  static const border = Color(0xFFEAE6DC);

  static const successBg = Color(0xFFE8F5E9);
  static const successText = Color(0xFF1B5E20);

  static const errorText = Color(0xFF991B1B);
}

enum _NotifFilter { semua, belumDibaca, tenantBaru, tagihan, keamanan, laporan }

class NotifikasiSuperAdminScreen extends StatefulWidget {
  const NotifikasiSuperAdminScreen({
    super.key,
    required this.onBack,
    this.onNavigate,
    this.onReadStateChanged,
  });

  /// Dipanggil saat tombol back di header notifikasi ditekan. ShellScreen
  /// yang nentuin artinya — biasanya: setState(() => _notifikasiOpen = false).
  final VoidCallback onBack;

  /// Diteruskan dari ShellScreen (`_goToMenu`) supaya kartu notifikasi yang
  /// punya aksi (mis. "Tinjau Tenant") bisa pindah tab beneran.
  final void Function(String label)? onNavigate;

  /// Dipanggil tiap kali status baca berubah (mark satu atau mark semua),
  /// supaya titik merah di lonceng header (ShellScreen) ikut ke-update
  /// tanpa nunggu user pencet tombol back dulu.
  final VoidCallback? onReadStateChanged;

  @override
  State<NotifikasiSuperAdminScreen> createState() =>
      _NotifikasiSuperAdminScreenState();
}

class _NotifikasiSuperAdminScreenState
    extends State<NotifikasiSuperAdminScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  _NotifFilter _filter = _NotifFilter.semua;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

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
      _load(); // rollback dengan cara sync ulang dari server
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

  int get _unreadCount => _items.where((n) => n['statusBaca'] != true).length;

  int _countFor(_NotifFilter f) {
    switch (f) {
      case _NotifFilter.semua:
        return _items.length;
      case _NotifFilter.belumDibaca:
        return _unreadCount;
      case _NotifFilter.tenantBaru:
        return _items.where((n) => n['jenis'] == 'TENANT_BARU').length;
      case _NotifFilter.tagihan:
        return _items.where((n) => n['jenis'] == 'TAGIHAN').length;
      case _NotifFilter.keamanan:
        return _items.where((n) => n['jenis'] == 'KEAMANAN').length;
      case _NotifFilter.laporan:
        return _items.where((n) => n['jenis'] == 'LAPORAN').length;
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    switch (_filter) {
      case _NotifFilter.semua:
        return _items;
      case _NotifFilter.belumDibaca:
        return _items.where((n) => n['statusBaca'] != true).toList();
      case _NotifFilter.tenantBaru:
        return _items.where((n) => n['jenis'] == 'TENANT_BARU').toList();
      case _NotifFilter.tagihan:
        return _items.where((n) => n['jenis'] == 'TAGIHAN').toList();
      case _NotifFilter.keamanan:
        return _items.where((n) => n['jenis'] == 'KEAMANAN').toList();
      case _NotifFilter.laporan:
        return _items.where((n) => n['jenis'] == 'LAPORAN').toList();
    }
  }

  /// Yang dianggap "mendesak": tagihan & percobaan login mencurigakan
  /// yang belum dibaca. Sesuaikan kalau definisi "mendesak" kamu beda.
  List<Map<String, dynamic>> get _urgentItems => _items
      .where((n) =>
          n['statusBaca'] != true &&
          (n['jenis'] == 'KEAMANAN' || n['jenis'] == 'TAGIHAN'))
      .toList();

  @override
  Widget build(BuildContext context) {
    // Konten doang — nggak ada Scaffold/AppBar/bottomNavigationBar sendiri.
    // Widget ini ditaruh sebagai `body` ShellScreen (mirip mekanisme
    // "Lainnya"), jadi AppBar (SuperAdminHeader) & bottom nav asli
    // ShellScreen otomatis tetap kepakai, nggak perlu duplikat.
    return Container(
      color: _SC.background,
      child: _loading
          ? loadingView()
          : _error != null
              ? errorView(_error!, _load)
              : RefreshIndicator(
                  color: _SC.primary,
                  onRefresh: _load,
                  child: Align(
                    // Sama kayak DashboardScreen: dibatasi maxWidth 480 &
                    // di-center, biar di web nggak melar penuh — konsisten
                    // sama Beranda/Tenant/Billing Super Admin lainnya.
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 14),
                          _buildStatusCard(),
                          const SizedBox(height: 14),
                          _buildFilterChips(),
                          const SizedBox(height: 12),
                          ..._buildGroupedList(),
                          const SizedBox(height: 6),
                          const _AllClearFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Material(
          color: _SC.surface,
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back, color: _SC.primary),
          ),
        ),
        const SizedBox(width: 4),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notifikasi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _SC.ink)),
              Text('Pusat Informasi & Peringatan Platform',
                  style: TextStyle(fontSize: 12, color: _SC.inkSecondary)),
            ],
          ),
        ),
        if (_unreadCount > 0)
          TextButton.icon(
            onPressed: _markAllRead,
            style: TextButton.styleFrom(foregroundColor: _SC.primary),
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Tandai Dibaca'),
          ),
      ],
    );
  }

  // Restyle: dulu banner gradient gelap sendirian — sekarang dua kartu
  // terang (_NotifStatCard) + pill "Pekan Ini", niru persis pola _SAStatCard
  // di dashboard_screen.dart (Total Tenant, Tenant Aktif, dst) biar
  // konsisten sama section Super Admin lainnya (Beranda/Tenant/Billing).
  Widget _buildStatusCard() {
    final urgent = _urgentItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: const [
              Icon(Icons.circle, size: 8, color: _SC.gold),
              SizedBox(width: 6),
              Text('STATUS OPERASIONAL',
                  style: TextStyle(
                      color: _SC.inkSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _SC.surfaceDim, borderRadius: BorderRadius.circular(20)),
              child: const Text('Pekan Ini', style: TextStyle(color: _SC.inkSecondary, fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _NotifStatCard(
                icon: Icons.mark_email_unread_outlined,
                label: 'Belum Dibaca',
                value: '$_unreadCount',
                sublabel: _unreadCount > 0 ? 'Perlu ditinjau' : 'Semua terbaca',
                accent: _unreadCount > 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NotifStatCard(
                icon: Icons.notifications_none_rounded,
                label: 'Total Notifikasi',
                value: '${_items.length}',
                sublabel: 'Platform-wide',
              ),
            ),
          ],
        ),
        if (urgent.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _SC.goldSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _SC.goldBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: _SC.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: '${urgent.length} Peringatan Mendesak: ',
                          style: const TextStyle(
                              color: _SC.errorText, fontWeight: FontWeight.bold, fontSize: 12)),
                      TextSpan(
                          text: urgent
                              .map((n) => _jenisLabel(n['jenis'] as String))
                              .toSet()
                              .join(' & '),
                          style: const TextStyle(color: _SC.inkSecondary, fontSize: 12)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilterChips() {
    final entries = <MapEntry<_NotifFilter, String>>[
      const MapEntry(_NotifFilter.semua, 'Semua'),
      const MapEntry(_NotifFilter.belumDibaca, 'Belum Dibaca'),
      const MapEntry(_NotifFilter.tenantBaru, 'Tenant Baru'),
      const MapEntry(_NotifFilter.tagihan, 'Tagihan'),
      const MapEntry(_NotifFilter.keamanan, 'Keamanan'),
      const MapEntry(_NotifFilter.laporan, 'Laporan'),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final f = entries[i].key;
          final label = entries[i].value;
          final count = _countFor(f);
          final selected = _filter == f;
          final showDot = f == _NotifFilter.belumDibaca && _unreadCount > 0;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? _SC.primary : _SC.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? _SC.primary : _SC.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showDot) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text('$label ($count)',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : _SC.inkSecondary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildGroupedList() {
    final items = _filteredItems;
    if (items.isEmpty) {
      return [
        const SizedBox(height: 60),
        Center(
          child: emptyView(_items.isEmpty
              ? 'Belum ada notifikasi platform.'
              : 'Tidak ada notifikasi di kategori ini.'),
        ),
      ];
    }

    final sorted = [...items]
      ..sort((a, b) => (b['tanggal'] as String).compareTo(a['tanggal'] as String));

    final groups = <String, List<Map<String, dynamic>>>{};
    for (final n in sorted) {
      final dt = DateTime.parse(n['tanggal'] as String).toLocal();
      final key = _dateKey(dt);
      groups.putIfAbsent(key, () => []).add(n);
    }

    final widgets = <Widget>[];
    groups.forEach((key, list) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(key,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: _SC.inkSecondary)),
            Text('${list.length} Aktivitas',
                style: const TextStyle(fontSize: 12, color: _SC.inkSecondary)),
          ],
        ),
      ));
      widgets.addAll(list.map(_buildCard));
    });
    return widgets;
  }

  Widget _buildCard(Map<String, dynamic> n) {
    final jenis = n['jenis'] as String;
    final isRead = n['statusBaca'] == true;
    final dt = DateTime.parse(n['tanggal'] as String).toLocal();
    final color = _jenisColor(jenis);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      // Konsisten sama _SATenantCard/_SAPendaftaranCard di dashboard_screen.dart
      // — selalu putih + border tipis, tanpa tint warna per-jenis atau shadow
      // tambahan; status belum-dibaca cukup lewat teks bold + dot merah.
      decoration: BoxDecoration(
        color: _SC.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _SC.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _markRead(n['id'] as String),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(_jenisIcon(jenis), size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                          child: Text(_jenisLabel(jenis),
                              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                        ),
                        if (!isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(n['pesan'] as String,
                        style: TextStyle(
                            fontSize: 13,
                            color: _SC.ink,
                            fontWeight: isRead ? FontWeight.normal : FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(_relativeTime(dt), style: const TextStyle(fontSize: 11, color: _SC.inkSecondary)),
                    if (_actionLabel(jenis) != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Material(
                          color: color,
                          borderRadius: BorderRadius.circular(9),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(9),
                            onTap: () => _handleAction(jenis, n),
                            child: Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.center,
                              child: Text(_actionLabel(jenis)!,
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -- Aksi per jenis. Sesuaikan nama rute dengan router kamu sendiri. --
  // Nggak perlu pop lagi (bukan halaman terpisah) — manggil onNavigate aja,
  // itu yang nutup tampilan notifikasi & mindahin tab di ShellScreen.
  void _handleAction(String jenis, Map<String, dynamic> n) {
    _markRead(n['id'] as String);
    switch (jenis) {
      case 'TENANT_BARU':
        widget.onNavigate?.call('Tenant');
        break;
      case 'TAGIHAN':
        widget.onNavigate?.call('Billing');
        break;
      case 'KEAMANAN':
        widget.onNavigate?.call('Audit Log');
        break;
    }
  }

  String? _actionLabel(String jenis) {
    switch (jenis) {
      case 'TENANT_BARU':
        return 'Tinjau Tenant';
      case 'TAGIHAN':
        return 'Lihat Tagihan';
      case 'KEAMANAN':
        return 'Lihat Log';
      default:
        return null; // LAPORAN cukup dibaca, tanpa aksi lanjutan
    }
  }

  String _jenisLabel(String jenis) {
    switch (jenis) {
      case 'TENANT_BARU':
        return 'Tenant Baru';
      case 'TAGIHAN':
        return 'Tagihan';
      case 'KEAMANAN':
        return 'Keamanan';
      case 'LAPORAN':
        return 'Laporan';
      default:
        return jenis;
    }
  }

  IconData _jenisIcon(String jenis) {
    switch (jenis) {
      case 'TENANT_BARU':
        return Icons.domain_add;
      case 'TAGIHAN':
        return Icons.receipt_long;
      case 'KEAMANAN':
        return Icons.security;
      case 'LAPORAN':
        return Icons.insights;
      default:
        return Icons.notifications;
    }
  }

  Color _jenisColor(String jenis) {
    switch (jenis) {
      case 'TENANT_BARU':
        return const Color(0xFF2563EB);
      case 'TAGIHAN':
        return const Color(0xFFD97706);
      case 'KEAMANAN':
        return const Color(0xFFDC2626);
      case 'LAPORAN':
        return const Color(0xFF0D9488);
      default:
        return Colors.grey;
    }
  }

  String _dateKey(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(that).inDays;
    final formatted = '${dt.day} ${_bulan[dt.month - 1]} ${dt.year}';
    if (diff == 0) return 'HARI INI ($formatted)';
    if (diff == 1) return 'KEMARIN ($formatted)';
    return formatted.toUpperCase();
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB';
  }

  static const _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
}

// ============================================================================
// Kartu statistik ringkas — niru _SAStatCard di dashboard_screen.dart
// (label + icon di atas, angka besar, sublabel di bawah) biar section
// Notifikasi konsisten sama section Beranda/Tenant/Billing Super Admin.
// ============================================================================

class _NotifStatCard extends StatelessWidget {
  const _NotifStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sublabel,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String sublabel;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final valueColor = accent ? _SC.errorText : _SC.ink;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent ? _SC.goldSurface : _SC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent ? _SC.goldBorder : _SC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11.5, color: _SC.inkSecondary)),
              Icon(icon, size: 16, color: _SC.primary),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: valueColor)),
          const SizedBox(height: 2),
          Text(sublabel, style: const TextStyle(fontSize: 11, color: _SC.primary)),
        ],
      ),
    );
  }
}

// ============================================================================
// Footer "semua terkendali" — versi Super Admin.
// ============================================================================

class _AllClearFooter extends StatelessWidget {
  const _AllClearFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: _SC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _SC.border),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: _SC.mint, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline, color: _SC.primary),
          ),
          const SizedBox(height: 8),
          const Text('Tata Kelola Platform Terkendali',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _SC.primary)),
          const SizedBox(height: 2),
          const Text(
            'Semua urusan tenant, tagihan & keamanan berjalan tertib.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _SC.inkSecondary),
          ),
        ],
      ),
    );
  }
}