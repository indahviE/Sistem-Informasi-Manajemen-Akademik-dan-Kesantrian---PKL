import 'dart:async';

import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/app_scope.dart';
import 'ui_utils.dart';

/// ---------------------------------------------------------------------------
/// Design tokens — mirrored 1:1 from DESIGN.md / the approved HTML mockup.
/// NOTE: font family is intentionally left unset everywhere in this file so
/// text inherits the app's default theme font — matching how signup_screen.dart
/// does not override fontFamily either.
/// ---------------------------------------------------------------------------
class _C {
  _C._();

  static const primary = Color(0xFF00231A);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF0F3A2E);
  static const onPrimaryContainer = Color(0xFF7AA494);
  static const primaryFixed = Color(0xFFC0ECDA);
  static const primaryFixedDim = Color(0xFFA4D0BF);
  static const onPrimaryFixed = Color(0xFF002118);

  static const secondary = Color(0xFF775A19);
  static const secondaryContainer = Color(0xFFFED488);
  static const onSecondaryContainer = Color(0xFF785A1A);
  static const secondaryFixed = Color(0xFFFFDEA5);
  static const secondaryFixedDim = Color(0xFFE9C176);
  static const onSecondaryFixed = Color(0xFF261900);

  static const tertiaryFixed = Color(0xFFD5E7DF);
  static const onTertiaryFixed = Color(0xFF0F1E1A);
  static const onTertiaryContainer = Color(0xFF8E9F98);

  static const surface = Color(0xFFFAF9F5);
  static const surfaceDim = Color(0xFFDBDAD6);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF4F4F0);
  static const surfaceContainer = Color(0xFFEFEEEA);
  static const surfaceContainerHigh = Color(0xFFE9E8E4);
  static const surfaceContainerHighest = Color(0xFFE3E2DF);

  static const onSurface = Color(0xFF1B1C1A);
  static const onSurfaceVariant = Color(0xFF414845);
  static const outline = Color(0xFF717975);
  static const outlineVariant = Color(0xFFC0C8C3);

  static const error = Color(0xFFBA1A1A);
}

/// ---------------------------------------------------------------------------
/// Wali Santri (parent) theme — mirrored 1:1 from signup_screen.dart's
/// `PColors`, so the parent-facing dashboard shares the same "Islamic
/// Academic & Kesantrian Experience" identity as the signup flow (Deep
/// Emerald Forest + Antique Gold on a warm ivory canvas).
/// ---------------------------------------------------------------------------
class _WC {
  _WC._();

  static const primary = Color(0xFF0F3A2E);
  static const primaryContainer = Color(0xFF1B4D3E);
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

  static const pendingBg = Color(0xFFFFF8E1);
  static const pendingText = Color(0xFFB78103);

  static const errorText = Color(0xFF991B1B);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  String? _error;
  DateTime? _lastLoaded;
  bool _syncing = false;
  Timer? _tickTimer;

  bool _didLoadOnce = false;

  @override
  void initState() {
    super.initState();
    // Keep "X menit lalu" fresh without needing another data fetch.
    _tickTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadOnce) {
      _didLoadOnce = true;
      _load();
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _syncing = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.dashboard);
      if (!mounted) return;
      setState(() {
        _data = res as Map<String, dynamic>;
        _lastLoaded = DateTime.now();
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = 'ApiException: ${e.message}');
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal memuat dashboard: $e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _notAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur ini akan segera tersedia.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return errorView(_error!, _load);
    if (_data == null) return loadingView();
    final role = _data!['role'] as String;
    final isTenantAdmin = role != 'SUPER_ADMIN' && role != 'WALI_SANTRI';
    final isWali = role == 'WALI_SANTRI';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          if (isWali)
            _waliHeroHeader()
          else if (isTenantAdmin)
            _heroHeader(role)
          else
            const PageHeader(title: 'Ringkasan', subtitle: 'Pantau kondisi pondok secara real-time'),
          const SizedBox(height: 20),
          if (role == 'SUPER_ADMIN')
            _superBody()
          else if (isWali)
            _waliBody()
          else
            _tenantBody(),
        ],
      ),
    );
  }

  // =========================================================================
  // Small data-safety helpers — the dashboard must never crash even if the
  // API hasn't shipped a particular field yet.
  // =========================================================================
  String? _pick(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v is String && v.trim().isNotEmpty) return v;
    }
    return null;
  }

  num _num(Map<String, dynamic> map, List<String> keys, [num fallback = 0]) {
    for (final k in keys) {
      final v = map[k];
      if (v is num) return v;
      if (v is String) {
        final p = num.tryParse(v);
        if (p != null) return p;
      }
    }
    return fallback;
  }

  String _fmtInt(num v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final remaining = s.length - i;
      if (i > 0 && remaining % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _elapsed(DateTime? t) {
    if (t == null) return 'baru saja';
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return 'baru saja';
    if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    return '${d.inDays} hari lalu';
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'ADMIN_PONDOK':
      case 'ADMIN':
        return 'Admin Operasional Lembaga';
      case 'USTADZ':
      case 'GURU':
        return 'Ustadz / Guru';
      case 'MUSYRIF':
        return 'Musyrif Asrama';
      case 'MUDIR':
      case 'PIMPINAN':
        return 'Pimpinan / Mudir';
      default:
        return 'Pengguna Pondok';
    }
  }

  String _formatIndoDate(DateTime dt) {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', "Jum'at", 'Sabtu'];
    const months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${days[dt.weekday % 7]}, ${dt.day} ${months[dt.month]} ${dt.year}';
  }

  String _kelasLabel(Map<String, dynamic> a) {
    final k = a['kelas'];
    if (k is String && k.trim().isNotEmpty) return k;
    if (k is Map && k['namaKelas'] != null) return k['namaKelas'].toString();
    final asrama = a['asrama'];
    if (asrama is String && asrama.trim().isNotEmpty) return asrama;
    return '-';
  }

  // =========================================================================
  // 1. Hero greeting / sync-status header (tenant & admin-like roles)
  // =========================================================================
  Widget _heroHeader(String role) {
    final namaPengguna = _pick(_data!, ['namaPengguna', 'nama', 'userName']) ?? 'Rekan Pondok';
    final namaPondok = _pick(_data!, ['namaPondok', 'namaLembaga', 'tenantNama']) ?? 'Ma\'had Anda';
    final semester = _pick(_data!, ['semester', 'tahunAjaran']) ?? 'Tahun Ajaran Berjalan';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _C.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: _C.primary.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(opacity: 0.05, child: _RubElHizb(size: 130, color: _C.primaryFixedDim)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _C.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: _C.secondary, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _roleLabel(role),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _C.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      namaPondok,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: _C.onPrimaryContainer),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Ahlan wa Sahlan, $namaPengguna',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    color: _C.onPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  semester,
                  style: TextStyle(fontSize: 12, color: _C.onPrimaryContainer),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: _syncing
                                ? const CircularProgressIndicator(
                                    strokeWidth: 2, color: _C.secondaryFixedDim)
                                : Icon(Icons.sync, size: 16, color: _C.secondaryFixedDim),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Sinkronisasi Data Master: ${_elapsed(_lastLoaded)}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11.5, color: _C.onPrimaryContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: _syncing ? null : _load,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.refresh, size: 14, color: _C.onPrimary),
                            SizedBox(width: 4),
                            Text('Perbarui', style: TextStyle(fontSize: 11.5, color: _C.onPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 1b. Hero header for WALI_SANTRI — themed with signup_screen.dart's
  // PColors (Deep Emerald Forest + Antique Gold) per the reference design.
  // =========================================================================
  Widget _waliHeroHeader() {
    final namaPengguna = _pick(_data!, ['namaPengguna', 'nama', 'userName']) ?? 'Wali Santri';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_WC.primary, _WC.primaryGradientEnd],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _WC.primary.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Opacity(opacity: 0.06, child: _RubElHizb(size: 120, color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _WC.gold.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield_outlined, size: 12, color: _WC.gold),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'PORTAL WALI SANTRI TERPADU',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  color: _WC.gold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Mode Pantau',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  "Assalamu'alaikum,",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  namaPengguna,
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.82)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(List<Widget> cards) {
    final w = MediaQuery.of(context).size.width;
    final cols = w >= 1400 ? 6 : (w >= 1024 ? 4 : (w >= 600 ? 3 : 2));
    return GridView.count(
      crossAxisCount: cols,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: w >= 600 ? 1.9 : 1.35,
      children: cards,
    );
  }

  // =========================================================================
  // SUPER ADMIN
  // =========================================================================
  Widget _superBody() {
    final s = (_data!['statistik'] as Map).cast<String, dynamic>();
    final tenants = (_data!['tenantTerbaru'] as List? ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _grid([
          _StatCard(label: 'Total Tenant', value: '${s['totalTenant'] ?? 0}', icon: Icons.apartment, iconColor: _C.primaryContainer, iconBg: _C.surfaceContainer),
          _StatCard(label: 'Tenant Aktif', value: '${s['tenantAktif'] ?? 0}', icon: Icons.check_circle_outline, iconColor: _C.secondary, iconBg: _C.surfaceContainer),
          _StatCard(label: 'Menunggu Persetujuan', value: '${s['tenantPending'] ?? 0}', icon: Icons.hourglass_top, iconColor: _C.secondary, iconBg: _C.surfaceContainer),
          _StatCard(label: 'Total Santri', value: '${s['totalSantri'] ?? 0}', icon: Icons.groups, iconColor: _C.primaryContainer, iconBg: _C.surfaceContainer),
        ]),
        const SizedBox(height: 16),
        _SectionShell(
          title: 'Tenant Terbaru',
          subtitle: 'Persetujuan & status keanggotaan',
          trailingIcon: Icons.apartment,
          child: tenants.isEmpty
              ? const _EmptyRow(text: 'Belum ada tenant.')
              : Column(
                  children: [
                    for (final t in tenants.cast<Map<String, dynamic>>()) _tenantRow(context, t),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _tenantRow(BuildContext context, Map<String, dynamic> t) {
    final status = t['status'] as String;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: _C.surfaceContainer, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.apartment, color: _C.primaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['namaPondok'] as String, style: const TextStyle(fontWeight: FontWeight.w600, color: _C.onSurface)),
                Text('${t['kodeTenant']} • Santri: ${(t['_count'] as Map)['santris'] ?? 0}',
                    style: const TextStyle(fontSize: 12, color: _C.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (status == 'PENDING')
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _C.primaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              onPressed: () => _tenantAction(t, 'approve'),
              child: const Text('Setujui', style: TextStyle(fontSize: 13)),
            )
          else
            _StatusPill(
              text: status,
              bg: status == 'AKTIF' ? const Color(0xFFE8F5E9) : const Color(0xFFFEE2E2),
              fg: status == 'AKTIF' ? const Color(0xFF1B5E20) : const Color(0xFF991B1B),
            ),
        ],
      ),
    );
  }

  Future<void> _tenantAction(Map<String, dynamic> t, String action) async {
    try {
      final api = AppScope.of(context).api;
      await api.post(action == 'approve' ? ApiUrl.tenantApprove : ApiUrl.tenantSuspend, {'tenantId': t['id']});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(action == 'approve' ? '${t['namaPondok']} telah diaktifkan.' : 'Tenant di-suspend.'),
      ));
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  // =========================================================================
  // WALI SANTRI — matches the reference design, themed with the signup
  // screen's Deep Emerald Forest + Antique Gold palette (see `_WC` above).
  // =========================================================================
  Widget _waliBody() {
    final anak = (_data!['anak'] as List? ?? []).cast<Map<String, dynamic>>();
    final today = _formatIndoDate(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (anak.isEmpty)
          const _WaliChildCard(nama: 'Belum ada data santri', kelas: '-', nis: '-', status: 'Aktif')
        else
          for (final a in anak)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _WaliChildCard(
                nama: (a['nama'] as String?) ?? 'Santri',
                kelas: _kelasLabel(a),
                nis: (a['nis'] as String?) ?? '-',
                status: _pick(a, ['status']) ?? 'Aktif',
              ),
            ),
        const SizedBox(height: 6),
        const _WaliVerificationBanner(),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Ringkasan Hari Ini',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _WC.ink)),
            Text(today, style: const TextStyle(fontSize: 11.5, color: _WC.inkSecondary)),
          ],
        ),
        const SizedBox(height: 10),
        const _WaliPresenceCard(),
        const SizedBox(height: 12),
        const _WaliTahfidzCard(),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(
              child: _WaliMiniStatCard(
                title: 'Kedisiplinan',
                badge: '0 Poin',
                icon: Icons.emoji_events_outlined,
                description: 'Pekan Bersih: Adab tepat waktu & kerapian lemari prima.',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _WaliMiniStatCard(
                title: 'Kondisi Fisik',
                badge: '36.6°C',
                icon: Icons.favorite_outline,
                description: "Sehat Wal'afiat. Skrining berkala Poskestren normal.",
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _WaliMukimCard(),
        const SizedBox(height: 20),
        const _WaliQuoteCard(),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Riwayat Lengkap Santri',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _WC.ink)),
            Text('Laporan Terarsip', style: TextStyle(fontSize: 11.5, color: _WC.inkSecondary)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _WC.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _WC.border),
          ),
          child: Column(
            children: const [
              _WaliHistoryItem(
                icon: Icons.school_outlined,
                title: 'Riwayat Nilai & Raport Diniyah',
                subtitle: 'Kompilasi semester & ujian lisan',
              ),
              Divider(height: 1, color: _WC.border),
              _WaliHistoryItem(
                icon: Icons.menu_book_outlined,
                title: "Riwayat & Mutaba'ah Tahfidz",
                subtitle: "Grafik setoran, muraja'ah harian",
              ),
              Divider(height: 1, color: _WC.border),
              _WaliHistoryItem(
                icon: Icons.fact_check_outlined,
                title: 'Riwayat Kehadiran & Shalat',
                subtitle: 'Log presensi 5 waktu & taklim',
              ),
              Divider(height: 1, color: _WC.border),
              _WaliHistoryItem(
                icon: Icons.gavel_outlined,
                title: 'Riwayat Disiplin & Izin Keluar',
                subtitle: 'Arsip kepulangan dan mahkamah santri',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _WaliContactCard(),
        const SizedBox(height: 24),
        const _WaliDuaFooter(),
      ],
    );
  }

  // =========================================================================
  // TENANT / ADMIN PONDOK — matches the approved mockup
  // =========================================================================
  Widget _tenantBody() {
    final s = (_data!['statistik'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    final santriAktif = _num(s, ['santriAktif', 'totalSantriAktif']);
    final santriPutra = _num(s, ['santriPutra', 'santriBanin']);
    final santriPutri = _num(s, ['santriPutri', 'santriBanat']);

    final totalUstadz = _num(s, ['totalUstadz', 'jumlahUstadz', 'ustadzAktif']);
    final ustadzMukim = _num(s, ['ustadzMukim']);
    final ustadzEksternal = _num(s, ['ustadzEksternal']);

    final totalKelas = _num(s, ['totalKelas', 'totalRombel']);
    final kelasTahfidz = _num(s, ['kelasTahfidz', 'rombelTahfidz']);
    final kelasDiniyah = _num(s, ['kelasDiniyah', 'rombelDiniyah']);

    final totalAkun = _num(s, ['totalAkun', 'akunTerdaftar']);
    final akunWali = _num(s, ['akunWali']);
    final akunGuru = _num(s, ['akunGuru']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- 2. Ringkasan angka pondok ----
        _SectionLabel(title: 'Master Data Terdata', trailing: 'Cakupan Lembaga Sendiri'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.5,
          children: [
            _MetricCard(
              label: 'Santri Aktif',
              value: _fmtInt(santriAktif),
              icon: Icons.school,
              iconColor: _C.primaryContainer,
              caption: (santriPutra > 0 || santriPutri > 0)
                  ? '${_fmtInt(santriPutra)} Putra • ${_fmtInt(santriPutri)} Putri'
                  : 'Data santri aktif pondok',
            ),
            _MetricCard(
              label: 'Ustadz / Pembina',
              value: _fmtInt(totalUstadz),
              icon: Icons.badge,
              iconColor: _C.secondary,
              caption: (ustadzMukim > 0 || ustadzEksternal > 0)
                  ? '${_fmtInt(ustadzMukim)} Mukim • ${_fmtInt(ustadzEksternal)} Eksternal'
                  : 'Tenaga pendidik aktif',
            ),
            _MetricCard(
              label: 'Kelas & Halaqah',
              value: '${_fmtInt(totalKelas)} Rombel',
              icon: Icons.menu_book,
              iconColor: _C.primaryContainer,
              caption: (kelasTahfidz > 0 || kelasDiniyah > 0)
                  ? '${_fmtInt(kelasTahfidz)} Tahfidz • ${_fmtInt(kelasDiniyah)} Diniyah'
                  : 'Rombongan belajar aktif',
            ),
            _MetricCard(
              label: 'Akun Terdaftar',
              value: _fmtInt(totalAkun),
              icon: Icons.manage_accounts,
              iconColor: _C.secondary,
              caption: (akunWali > 0 || akunGuru > 0)
                  ? '${_fmtInt(santriAktif)} Santri • ${_fmtInt(akunWali)} Wali • ${_fmtInt(akunGuru)} Guru'
                  : 'Akun aktif portal mobile & web',
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ---- 3. Tindakan cepat ----
        _SectionLabel(title: 'Tindakan Data Master', trailing: 'Input Langsung'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.55,
          children: [
            _QuickAction(
              title: 'Santri Baru',
              subtitle: 'Entri biodata & berkas santri',
              icon: Icons.person_add,
              iconBg: _C.primaryFixed,
              iconColor: _C.primaryContainer,
              tag: 'Auto-NIS',
              onTap: _notAvailable,
            ),
            _QuickAction(
              title: 'Ustadz / Guru',
              subtitle: 'Registrasi asatidz & musyrif',
              icon: Icons.assignment_ind,
              iconBg: _C.secondaryFixed,
              iconColor: _C.onSecondaryFixed,
              onTap: _notAvailable,
            ),
            _QuickAction(
              title: 'Rombel & Halaqah',
              subtitle: 'Plotting santri & wali kelas',
              icon: Icons.meeting_room,
              iconBg: _C.tertiaryFixed,
              iconColor: _C.onTertiaryFixed,
              onTap: _notAvailable,
            ),
            _QuickAction(
              title: 'Akun Pengguna',
              subtitle: 'Generate kredensial wali & santri',
              icon: Icons.lock_person,
              iconBg: _C.surfaceContainerHigh,
              iconColor: _C.primaryContainer,
              onTap: _notAvailable,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ---- 4. Audit kelengkapan data ----
        _buildAuditCard(),
        const SizedBox(height: 20),

        // ---- 5. Kelola akademik & KBM ----
        _buildAcademicCard(),
        const SizedBox(height: 20),

        // ---- 6. Log aktivitas ----
        _buildLogCard(),
        const SizedBox(height: 16),

        // ---- Catatan batas akses ----
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _C.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 18, color: _C.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 11.5, color: _C.onSurfaceVariant, height: 1.5),
                    children: [
                      TextSpan(
                        text: 'Catatan Batas Akses Admin Lembaga: ',
                        style: TextStyle(fontWeight: FontWeight.w700, color: _C.onSurfaceVariant),
                      ),
                      TextSpan(
                        text:
                            'Pengajuan perizinan kepulangan santri dan evaluasi mutaba\'ah kelulusan diproses secara terpisah oleh Mudir Pesantren & Dewan Asatidz. Modul Anda difokuskan penuh pada integritas master data pondok.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuditCard() {
    final items = ((_data!['auditKelengkapan'] as List?) ?? const []).cast<Map<String, dynamic>>();
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: _C.secondaryContainer, borderRadius: BorderRadius.circular(999)),
                    child: const Icon(Icons.verified_user, size: 18, color: _C.onSecondaryContainer),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Audit Kelengkapan Data',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _C.primaryContainer)),
                      Text('Kelola data wajib sebelum penomoran ijazah',
                          style: TextStyle(fontSize: 11.5, color: _C.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
              if (items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _C.secondaryContainer, borderRadius: BorderRadius.circular(999)),
                  child: Text('${items.length} Tindakan',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _C.onSecondaryContainer)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const _EmptyRow(text: 'Semua data wajib sudah lengkap.', icon: Icons.check_circle_outline)
          else
            Column(
              children: [
                for (final item in items) _auditRow(item),
              ],
            ),
        ],
      ),
    );
  }

  Widget _auditRow(Map<String, dynamic> item) {
    final title = _pick(item, ['judul', 'title']) ?? 'Tindakan diperlukan';
    final subtitle = _pick(item, ['deskripsi', 'subtitle']) ?? '';
    final actionLabel = _pick(item, ['aksi', 'actionLabel']) ?? 'Lihat';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: _C.surfaceContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline, size: 18, color: _C.secondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _C.onSurface)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: TextStyle(fontSize: 11.5, color: _C.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _notAvailable,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: _C.primaryContainer, borderRadius: BorderRadius.circular(999)),
              child: Text(actionLabel, style: const TextStyle(fontSize: 11, color: _C.onPrimary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicCard() {
    final absensi = (_data!['kepatuhanAbsensi'] as Map?)?.cast<String, dynamic>();
    final terisi = absensi != null ? _num(absensi, ['terisi', 'sudah']) : null;
    final total = absensi != null ? _num(absensi, ['total']) : null;
    final pct = (terisi != null && total != null && total > 0) ? (terisi / total) : null;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kelola Akademik & KBM',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _C.primaryContainer)),
                    Text('Pusat entri kolektif dan monitoring rombel',
                        style: TextStyle(fontSize: 11.5, color: _C.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: _C.primaryFixed, borderRadius: BorderRadius.circular(999)),
                child: const Icon(Icons.library_books, size: 18, color: _C.onPrimaryFixed),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _C.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text('Kepatuhan Rekap Absensi Harian', style: TextStyle(fontSize: 12, color: _C.onSurface)),
                    ),
                    Text(
                      pct != null ? '${_fmtInt(terisi!)} / ${_fmtInt(total!)} Rombel (${(pct * 100).round()}%)' : 'Belum ada data',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _C.primaryContainer),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct ?? 0,
                    minHeight: 8,
                    backgroundColor: _C.surfaceContainer,
                    valueColor: const AlwaysStoppedAnimation(_C.primaryContainer),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _academicShortcut(
            icon: Icons.fact_check,
            label: 'Input Rekap Absensi Terpusat',
            onTap: _notAvailable,
          ),
          const SizedBox(height: 8),
          _academicShortcut(
            icon: Icons.upload_file,
            label: 'Unggah Nilai Kolektif (Excel/CSV)',
            onTap: _notAvailable,
          ),
          const SizedBox(height: 8),
          _academicShortcut(
            icon: Icons.auto_stories,
            label: 'Katalog Mata Pelajaran & Kitab Turats',
            onTap: _notAvailable,
          ),
        ],
      ),
    );
  }

  Widget _academicShortcut({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: _C.surfaceContainer, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: _C.primaryContainer),
                const SizedBox(width: 10),
                Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _C.primaryContainer)),
              ],
            ),
            const Icon(Icons.chevron_right, size: 18, color: _C.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard() {
    final logs = ((_data!['logAktivitas'] as List?) ?? const []).cast<Map<String, dynamic>>();
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: _C.surfaceContainer, borderRadius: BorderRadius.circular(999)),
                    child: const Icon(Icons.history, size: 18, color: _C.onSurfaceVariant),
                  ),
                  const SizedBox(width: 10),
                  const Text('Log Aktivitas Data Master',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _C.primaryContainer)),
                ],
              ),
              Text('Internal Ma\'had', style: TextStyle(fontSize: 11, color: _C.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 10),
          if (logs.isEmpty)
            const _EmptyRow(text: 'Belum ada aktivitas tercatat.')
          else
            Column(
              children: [
                for (final log in logs) _logRow(log),
              ],
            ),
        ],
      ),
    );
  }

  Widget _logRow(Map<String, dynamic> log) {
    final message = _pick(log, ['pesan', 'message']) ?? '-';
    final actor = _pick(log, ['oleh', 'actor']) ?? 'Admin Lembaga';
    final time = _pick(log, ['waktu', 'time']) ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(color: _C.primaryFixed, borderRadius: BorderRadius.circular(999)),
            child: const Icon(Icons.person_add, size: 14, color: _C.primaryContainer),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: const TextStyle(fontSize: 12.5, color: _C.onSurface, height: 1.3)),
                Text(
                  time.isNotEmpty ? '$actor • $time' : actor,
                  style: TextStyle(fontSize: 11, color: _C.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Reusable pieces — Tenant / Admin / Super Admin (unchanged)
/// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String trailing;
  const _SectionLabel({required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.primaryContainer)),
        Text(trailing, style: TextStyle(fontSize: 11.5, color: _C.onSurfaceVariant)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color iconColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: _C.onSurfaceVariant)),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: _C.surfaceContainer, shape: BoxShape.circle),
                child: Icon(icon, size: 15, color: iconColor),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _C.primaryContainer)),
              const SizedBox(height: 2),
              Text(caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: _C.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String? tag;
  final VoidCallback onTap;

  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _C.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                    child: Icon(icon, size: 19, color: iconColor),
                  ),
                  if (tag != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: _C.surfaceContainer, borderRadius: BorderRadius.circular(999)),
                      child: Text(tag!, style: TextStyle(fontSize: 8.5, color: _C.onSurfaceVariant, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _C.onSurface)),
              const SizedBox(height: 1),
              Text(subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: _C.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _C.primaryContainer)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, color: _C.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _StatusPill({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _SectionShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData trailingIcon;
  final Widget child;

  const _SectionShell({
    required this.title,
    required this.subtitle,
    required this.trailingIcon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: _C.surfaceContainer, borderRadius: BorderRadius.circular(999)),
                child: Icon(trailingIcon, size: 18, color: _C.primaryContainer),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _C.primaryContainer)),
                    Text(subtitle, style: TextStyle(fontSize: 11.5, color: _C.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String text;
  final IconData icon;
  const _EmptyRow({required this.text, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _C.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12.5, color: _C.onSurfaceVariant))),
      ],
    );
  }
}

/// Faint 8-point "Rub el Hizb" style geometric watermark used on hero banners.
class _RubElHizb extends StatelessWidget {
  final double size;
  final Color color;
  const _RubElHizb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.55,
            height: size * 0.55,
            decoration: BoxDecoration(border: Border.all(color: color, width: 2), borderRadius: BorderRadius.circular(6)),
          ),
          Transform.rotate(
            angle: 0.785398, // 45deg
            child: Container(
              width: size * 0.55,
              height: size * 0.55,
              decoration: BoxDecoration(border: Border.all(color: color, width: 2), borderRadius: BorderRadius.circular(6)),
            ),
          ),
          Container(
            width: size * 0.3,
            height: size * 0.3,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Reusable pieces — WALI SANTRI (parent) section only. Themed with `_WC`
/// (mirrors signup_screen.dart's PColors) per the reference design.
/// ---------------------------------------------------------------------------

class _WaliChildCard extends StatelessWidget {
  final String nama;
  final String kelas;
  final String nis;
  final String status;
  const _WaliChildCard({required this.nama, required this.kelas, required this.nis, required this.status});

  @override
  Widget build(BuildContext context) {
    final isAktif = status.toLowerCase() == 'aktif';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _WC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _WC.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: _WC.sage, shape: BoxShape.circle),
            child: const Icon(Icons.person, color: _WC.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _WC.ink)),
                const SizedBox(height: 2),
                Text('$kelas • NIS: $nis',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: _WC.inkSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isAktif ? _WC.successBg : _WC.pendingBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isAktif ? _WC.successText : _WC.pendingText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaliVerificationBanner extends StatelessWidget {
  const _WaliVerificationBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _WC.primary, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.verified, size: 14, color: _WC.gold),
                  SizedBox(width: 6),
                  Text('TERVERIFIKASI OTENTIK',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: _WC.gold)),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.lock_outline, size: 12, color: Colors.white.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Text('Read-Only', style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.7))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Di Lingkungan Asrama & Masjid',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Mukim Aktif (Aman di Dalam Pondok)',
                    style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.9))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.pin_drop_outlined, size: 14, color: Colors.white.withOpacity(0.9)),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Piket Musyrif: 17:15 WIB (Maghrib Berjamaah) • Gedung Ali',
                    style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.9))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaliPresenceCard extends StatelessWidget {
  const _WaliPresenceCard();

  static const _sesi = ['Shubuh', 'Diniyah', 'Ashar', 'Maghrib'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _WC.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _WC.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Presensi & Kehadiran',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _WC.ink)),
                    SizedBox(height: 3),
                    Text('100% Hadir (4 Sesi Lengkap)', style: TextStyle(fontSize: 11.5, color: _WC.inkSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: _WC.successBg, borderRadius: BorderRadius.circular(999)),
                child: const Text('Disiplin',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _WC.successText)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final s in _sesi)
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(color: _WC.successBg, shape: BoxShape.circle),
                        child: const Icon(Icons.check, size: 16, color: _WC.successText),
                      ),
                      const SizedBox(height: 6),
                      Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _WC.ink)),
                      Text('Hadir', style: TextStyle(fontSize: 10, color: _WC.inkSecondary)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaliTahfidzCard extends StatelessWidget {
  const _WaliTahfidzCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _WC.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _WC.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Setoran Tahfidz Terbaru',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _WC.ink)),
                    SizedBox(height: 3),
                    Text("Saba' & Ziyadah Ba'da Ashar", style: TextStyle(fontSize: 11.5, color: _WC.inkSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _WC.goldSurface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _WC.goldBorder),
                ),
                child: const Text('Mumtaz (A)',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _WC.gold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Expanded(
                child: Text('Juz 28 (QS. Al-Mujadilah: 1–15)',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _WC.ink)),
              ),
              Text('24 / 30 Juz (80%)',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _WC.primary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.8,
              minHeight: 8,
              backgroundColor: _WC.surfaceDim,
              valueColor: const AlwaysStoppedAnimation(_WC.gold),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: _WC.inkSecondary),
              const SizedBox(width: 4),
              const Expanded(
                child: Text('Disimak oleh: Ust. Ahmad Fauzan, Lc.',
                    style: TextStyle(fontSize: 11, color: _WC.inkSecondary)),
              ),
              const Text('Tajwid: Mumtaz',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _WC.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaliMiniStatCard extends StatelessWidget {
  final String title;
  final String badge;
  final IconData icon;
  final String description;
  const _WaliMiniStatCard({
    required this.title,
    required this.badge,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _WC.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _WC.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: _WC.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _WC.inkSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _WC.mint, borderRadius: BorderRadius.circular(999)),
            child: Text(badge, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _WC.primary)),
          ),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(fontSize: 10.5, color: _WC.inkSecondary, height: 1.35)),
        ],
      ),
    );
  }
}

class _WaliMukimCard extends StatelessWidget {
  const _WaliMukimCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _WC.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _WC.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.home_outlined, size: 16, color: _WC.primary),
                  SizedBox(width: 8),
                  Text('Status Mukim & Perizinan',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _WC.ink)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: _WC.successBg, borderRadius: BorderRadius.circular(999)),
                child: const Text('Mukim Aktif',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _WC.successText)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _WC.surfaceDim, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _WC.goldSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _WC.goldBorder),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('20', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _WC.gold)),
                      Text('MEI', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: _WC.gold)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('3 Minggu Lagi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _WC.ink)),
                      SizedBox(height: 2),
                      Text('Libur Akhir Semester Genap', style: TextStyle(fontSize: 11, color: _WC.inkSecondary)),
                      Text('Kepulangan serentak santri', style: TextStyle(fontSize: 11, color: _WC.inkSecondary)),
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

class _WaliQuoteCard extends StatelessWidget {
  const _WaliQuoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _WC.goldSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _WC.goldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.format_quote, size: 16, color: _WC.gold),
                  SizedBox(width: 6),
                  Text('Catatan Wali Asrama / Halaqah',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _WC.ink)),
                ],
              ),
              const Text('28 Apr 2025', style: TextStyle(fontSize: 10.5, color: _WC.inkSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "\"Alhamdulillah ananda menunjukkan ketekunan istimewa dalam meraja'ah hafalan Juz 28 dan senantiasa istiqomah di shaf terdepan Masjid Jami' Pesantren.\"",
            style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: _WC.ink, height: 1.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: _WC.primary, shape: BoxShape.circle),
                child: const Icon(Icons.person, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ust. Ahmad Fauzan, Lc.', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _WC.ink)),
                  Text('Musyrif Tahfidz & Wali Halaqah', style: TextStyle(fontSize: 10.5, color: _WC.inkSecondary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaliHistoryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _WaliHistoryItem({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: _WC.sage, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 17, color: _WC.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _WC.ink)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: _WC.inkSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: _WC.inkSecondary),
          ],
        ),
      ),
    );
  }
}

class _WaliContactCard extends StatelessWidget {
  const _WaliContactCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _WC.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _WC.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kontak Musyrif & Informasi Besuk',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _WC.ink)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: _WC.primary, shape: BoxShape.circle),
                child: const Icon(Icons.person, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ust. Hamdan As-Suyuthi',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _WC.ink)),
                    Text('Musyrif Gedung Ali Lt. 2 (Kamar 204)',
                        style: TextStyle(fontSize: 11, color: _WC.inkSecondary)),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: _WC.sage, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.chat_bubble_outline, size: 16, color: _WC.primary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jadwal Jam Besuk', style: TextStyle(fontSize: 10.5, color: _WC.inkSecondary)),
                    SizedBox(height: 3),
                    Text('Ahad', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _WC.ink)),
                    Text('09:00 - 16:00 WIB', style: TextStyle(fontSize: 11, color: _WC.inkSecondary)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Darurat Poskestren', style: TextStyle(fontSize: 10.5, color: _WC.inkSecondary)),
                    SizedBox(height: 3),
                    Text('(021) 8892-1200',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _WC.errorText)),
                    Text('Layanan Medis 24 Jam', style: TextStyle(fontSize: 11, color: _WC.inkSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaliDuaFooter extends StatelessWidget {
  const _WaliDuaFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'رَبِّ هَبْ لِي مِنَ الصَّالِحِينَ',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _WC.gold),
        ),
        const SizedBox(height: 6),
        const Text(
          '"Ya Tuhanku, anugerahkanlah kepadaku (anak) yang termasuk orang-orang yang saleh."',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: _WC.inkSecondary),
        ),
        const SizedBox(height: 10),
        const Text(
          "SIMPesantren Terpadu • Sistem Keamanan Santri Terenkripsi",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: _WC.inkSecondary),
        ),
      ],
    );
  }
}