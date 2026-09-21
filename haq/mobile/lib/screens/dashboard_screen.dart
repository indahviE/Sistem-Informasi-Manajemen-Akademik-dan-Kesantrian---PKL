import 'dart:async';

import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/app_scope.dart';
import 'ui_utils.dart';
import 'super_admin/tenants_screen.dart'; // TODO: sesuaikan path bila struktur foldernya beda
import 'billing/billing_admin_screen.dart'; // TODO: sesuaikan nama class/path bila beda (asumsi: BillingAdminScreen)

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
///
/// Sekarang juga dipakai untuk bagian SUPER ADMIN (lihat _superAdminHeroHeader
/// & _superBody) supaya emerald-nya identik dengan landing page, sesuai
/// permintaan — bukan warna baru yang ditebak.
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
  final void Function(String label)? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});

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

  // Filter untuk section "Direktori Tenant Platform" di dashboard Super Admin.
  String _tenantFilter = 'semua'; // semua | aktif | pending | suspended

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
    final isSuperAdmin = role == 'SUPER_ADMIN';

    return Container(
      // Menyamakan background dashboard Super Admin dengan TenantsScreen
      // (PColors.background == _WC.background == 0xFFFAF9F5).
      color: isSuperAdmin ? _WC.background : null,
      child: RefreshIndicator(
        onRefresh: _load,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            // Sama seperti LandingScreen: dibatasi maxWidth supaya di web
            // tetap terasa "mobile-first" & proporsional, bukan melar penuh.
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                if (isWali)
                  _waliHeroHeader()
                else if (isTenantAdmin)
                  _heroHeader(role)
                else if (isSuperAdmin)
                  _superAdminHeroHeader()
                else
                  const PageHeader(title: 'Ringkasan', subtitle: 'Pantau kondisi pondok secara real-time'),
                const SizedBox(height: 20),
                if (isSuperAdmin)
                  _superBody()
                else if (isWali)
                  _waliBody()
                else
                  _tenantBody(),
              ],
            ),
          ),
        ),
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

  // =========================================================================
  // 1c. Hero header for SUPER_ADMIN — restyle mengikuti mockup dashboard,
  // dengan palet emerald `_WC` yang sama dengan landing page.
  //
  // TODO: "Latency" & "Cluster" adalah metrik infra platform, belum ada
  // endpoint-nya di PRD saat ini (mis. GET /api/platform/health). Nilai di
  // bawah masih placeholder statis — gampang disambungkan begitu ada.
  // =========================================================================
  Widget _superAdminHeroHeader() {
    final namaPengguna = _pick(_data!, ['namaPengguna', 'nama', 'userName']) ?? 'Super Admin';
    const latencyMs = 24;
    const clusterLabel = 'ap-southeast-1 (Jakarta DC)';

    // Catatan desain: mengikuti screen.png — kartu ini TERANG (bukan gradient
    // emerald), teks gelap. Yang berwarna cuma dua pill kecil: "ROOT SUPER
    // ADMIN..." (hijau tua + teks emas) dan "Latency" (abu-abu netral).
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _WC.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -30,
            top: -24,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(color: _WC.gold.withOpacity(0.10), shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: _WC.primary, borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: _WC.gold, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      const Flexible(
                        child: Text(
                          'ROOT SUPER ADMIN • MULTI-TENANT CONTROL',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
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
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: _WC.surfaceDim, borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: _WC.inkSecondary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text('Latency ${latencyMs}ms',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: _WC.inkSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Halo, $namaPengguna',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _WC.ink),
                ),
                const SizedBox(height: 2),
                const Text(
                  'SIMPesantren — Panel Platform Orchestration v4.2',
                  style: TextStyle(fontSize: 12, color: _WC.inkSecondary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.dns_outlined, size: 14, color: _WC.inkSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cluster: $clusterLabel',
                        style: const TextStyle(fontSize: 11.5, color: _WC.inkSecondary),
                      ),
                    ),
                    const Text(
                      'Semua Node Sehat',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _WC.gold),
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
  // SUPER ADMIN — restyle mengikuti mockup, palet emerald `_WC`
  // =========================================================================
  Widget _superBody() {
    final s = (_data!['statistik'] as Map).cast<String, dynamic>();

    // NOTE PENTING: `tenantTerbaru` dari GET /api/dashboard hanya berisi
    // tenant TERBARU (bukan seluruh tenant platform) — cocok untuk section
    // "Pendaftaran Baru" & pratinjau direktori, tapi untuk daftar lengkap +
    // filter yang akurat harus ke TenantsScreen (tombol "Lihat Semua" di
    // bawah). Angka statistik (Total Tenant, Tenant Aktif, dst) tetap
    // diambil dari `statistik`, bukan dihitung dari list yang cuma sebagian.
    final tenantTerbaru =
        ((_data!['tenantTerbaru'] as List?) ?? const []).cast<Map<String, dynamic>>();

    final totalTenant = _num(s, ['totalTenant']);
    final tenantAktif = _num(s, ['tenantAktif']);
    final tenantPendingCount = _num(s, ['tenantPending']).round();
    // TODO: pastikan key agregat "total user platform" ke tim backend —
    // sementara fallback ke totalSantri kalau belum ada.
    final totalUser = _num(s, ['totalUserPlatform', 'totalUser', 'totalSantri']);

    final pendingTerbaru = tenantTerbaru
        .where((t) => (t['status'] as String? ?? '').toUpperCase() == 'PENDING')
        .toList();

    List<Map<String, dynamic>> filteredDirektori;
    switch (_tenantFilter) {
      case 'aktif':
        filteredDirektori = tenantTerbaru
            .where((t) => (t['status'] as String? ?? '').toUpperCase() == 'AKTIF')
            .toList();
        break;
      case 'pending':
        filteredDirektori = pendingTerbaru;
        break;
      case 'suspended':
        filteredDirektori = tenantTerbaru
            .where((t) => (t['status'] as String? ?? '').toUpperCase() == 'SUSPENDED')
            .toList();
        break;
      default:
        filteredDirektori = tenantTerbaru;
    }

    // TODO: belum ada endpoint GET /api/audit-log di PRD saat ini — kalau
    // backend sudah mengirim `auditKeamanan` di payload dashboard, dipakai;
    // kalau belum, fallback ke placeholder statis di bawah.
    final auditItems = ((_data!['auditKeamanan'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map((e) => <String, dynamic>{
              'pesan': '${e['judul']} — ${e['tenantNama']}',
              'waktu': _elapsed(DateTime.tryParse('${e['waktu']}')?.toLocal()),
            })
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SAStatCard(
                icon: Icons.apartment_rounded,
                label: 'Total Tenant',
                value: _fmtInt(totalTenant),
                sublabel: '+3 bulan ini', // TODO: butuh histori pendaftaran dari backend
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SAStatCard(
                icon: Icons.verified_rounded,
                label: 'Tenant Aktif',
                value: _fmtInt(tenantAktif),
                sublabel: 'Berjalan normal',
                showDot: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SAReviewCard(
                count: tenantPendingCount,
                onTap: () => setState(() => _tenantFilter = 'pending'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SAStatCard(
                icon: Icons.groups_rounded,
                label: 'Total User Terdata',
                value: _fmtInt(totalUser),
                sublabel: 'Santri, Wali & Mudir',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _SAActionButton(
                icon: Icons.shield_outlined,
                label: 'Review Pendaftaran ($tenantPendingCount)',
                filled: true,
                onTap: () => setState(() => _tenantFilter = 'pending'),
              ),
              const SizedBox(width: 10),
              _SAActionButton(
                icon: Icons.corporate_fare_rounded,
                label: 'Kelola Tenant',
                onTap: () => widget.onNavigate?.call('Tenant'),
              ),
              const SizedBox(width: 10),
              _SAActionButton(
                icon: Icons.receipt_long_rounded,
                label: 'Billing & Paket',
                onTap: () => widget.onNavigate?.call('Billing'),
              ),
            ],
          ),
        ),
        if (pendingTerbaru.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SASectionHeader(
            title: 'Pendaftaran Baru',
            subtitle: 'Self-service onboarding perlu validasi legalitas',
            badgeLabel: '${pendingTerbaru.length} Masuk',
            badgeBg: _WC.goldSurface,
            badgeFg: _WC.gold,
          ),
          const SizedBox(height: 10),
          for (final t in pendingTerbaru)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SAPendaftaranCard(
                tenant: t,
                // TODO: ganti ke aksi 'reject' begitu backend punya endpoint
                // khusus untuk menolak pendaftaran (beda dari suspend tenant aktif).
                onTolak: () => _tenantAction(t, 'suspend'),
                onSetujui: () => _tenantAction(t, 'approve'),
              ),
            ),
        ],
        const SizedBox(height: 24),
        _SASectionHeader(
          title: 'Direktori Tenant Platform',
          badgeLabel: '${tenantTerbaru.length} Terdaftar',
          badgeBg: _WC.sage,
          badgeFg: _WC.primary,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _SAFilterChip(
                label: 'Semua (${tenantTerbaru.length})',
                selected: _tenantFilter == 'semua',
                onTap: () => setState(() => _tenantFilter = 'semua'),
              ),
              const SizedBox(width: 8),
              _SAFilterChip(
                label: 'Aktif',
                selected: _tenantFilter == 'aktif',
                onTap: () => setState(() => _tenantFilter = 'aktif'),
              ),
              const SizedBox(width: 8),
              _SAFilterChip(
                label: 'Pending',
                selected: _tenantFilter == 'pending',
                onTap: () => setState(() => _tenantFilter = 'pending'),
              ),
              const SizedBox(width: 8),
              _SAFilterChip(
                label: 'Suspended',
                selected: _tenantFilter == 'suspended',
                onTap: () => setState(() => _tenantFilter = 'suspended'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (filteredDirektori.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: _EmptyRow(text: 'Tidak ada tenant terbaru di kategori ini.'),
          )
        else
          for (final t in filteredDirektori)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SATenantCard(
                tenant: t,
                onSuspend: () => _tenantAction(t, 'suspend'),
                onAktifkan: () => _tenantAction(t, 'approve'),
              ),
            ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _WC.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _WC.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Audit Keamanan & Mutasi',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _WC.ink)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: _WC.gold, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      const Text('Real-time',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _WC.gold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (auditItems.isEmpty)
                Column(
                  children: const [
                    _SAAuditItem(
                      icon: Icons.person_add_alt_1_rounded,
                      iconBg: _WC.successBg,
                      iconFg: _WC.successText,
                      boldPrefix: "Tenant Ma'had Al-Qur'an:",
                      text: ' Penambahan 15 akun ustadz baru oleh Admin Tenant.',
                      time: '12 menit lalu',
                    ),
                    _SAAuditItem(
                      icon: Icons.warning_amber_rounded,
                      iconBg: Color(0xFFFEE2E2),
                      iconFg: _WC.errorText,
                      boldPrefix: 'Security Alert:',
                      text: ' Percobaan login gagal berulang kali (Rate Limit Exceeded) pada subdomain ',
                      boldSuffix: 'darussalam2',
                      afterBoldSuffix: '.',
                      textColor: _WC.errorText,
                      time: '1 jam lalu',
                    ),
                    _SAAuditItem(
                      icon: Icons.verified_rounded,
                      iconBg: _WC.goldSurface,
                      iconFg: _WC.gold,
                      boldPrefix: 'Billing Subscription:',
                      text: ' Auto-renewal sukses untuk Paket Enterprise Bina Insani.',
                      time: 'Kemarin, 23:59 WIB',
                      isLast: true,
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    for (int i = 0; i < auditItems.length; i++)
                      _SAAuditItem(
                        icon: Icons.history_rounded,
                        iconBg: _WC.sage,
                        iconFg: _WC.primary,
                        title: _pick(auditItems[i], ['pesan', 'message', 'judul']) ?? '-',
                        time: _pick(auditItems[i], ['waktu', 'time']) ?? '',
                        isLast: i == auditItems.length - 1,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
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
/// Reusable pieces — Tenant / Admin (unchanged)
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
/// Reusable pieces — SUPER ADMIN section only. Themed with `_WC` (mirrors
/// signup_screen.dart's PColors / palet landing page), sesuai permintaan.
/// ---------------------------------------------------------------------------

class _SAStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sublabel;
  final bool showDot;
  const _SAStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sublabel,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _WC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _WC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11.5, color: _WC.inkSecondary)),
              Icon(icon, size: 16, color: _WC.primary),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _WC.ink)),
          const SizedBox(height: 2),
          Row(
            children: [
              if (showDot) ...[
                Container(width: 5, height: 5, decoration: const BoxDecoration(color: _WC.successText, shape: BoxShape.circle)),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(sublabel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: _WC.primary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SAReviewCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _SAReviewCard({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ada = count > 0;
    final bg = ada ? _WC.goldSurface : _WC.surface;
    final border = ada ? _WC.goldBorder : _WC.border;
    final accent = ada ? _WC.errorText : _WC.inkSecondary;
    final labelColor = ada ? _WC.gold : _WC.inkSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Review Masuk', style: TextStyle(fontSize: 11.5, color: labelColor)),
                Icon(
                  ada ? Icons.priority_high_rounded : Icons.check_circle_outline,
                  size: 16,
                  color: accent,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: accent)),
            const SizedBox(height: 2),
            Text(
              ada ? 'Perlu Review Segera' : 'Tidak Ada Antrean',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _SASectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String badgeLabel;
  final Color badgeBg;
  final Color badgeFg;
  const _SASectionHeader({
    required this.title,
    this.subtitle,
    required this.badgeLabel,
    required this.badgeBg,
    required this.badgeFg,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _WC.ink)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: const TextStyle(fontSize: 11.5, color: _WC.inkSecondary)),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
          child: Text(badgeLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: badgeFg)),
        ),
      ],
    );
  }
}

class _SAFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SAFilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? _WC.primary : _WC.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? _WC.primary : _WC.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : _WC.inkSecondary,
          ),
        ),
      ),
    );
  }
}

class _SAActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;
  const _SAActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled ? _WC.primary : _WC.surface;
    final fg = filled ? Colors.white : _WC.ink;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(9999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9999),
            border: filled ? null : Border.all(color: _WC.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SAPendaftaranCard extends StatelessWidget {
  final Map<String, dynamic> tenant;
  final VoidCallback onTolak;
  final VoidCallback onSetujui;
  const _SAPendaftaranCard({required this.tenant, required this.onTolak, required this.onSetujui});

  @override
  Widget build(BuildContext context) {
    final nama = tenant['namaPondok'] as String? ?? '-';
    final kode = tenant['kodeTenant'] as String? ?? '-';
    // Field opsional — belum tentu dikirim backend saat ini (lihat catatan
    // skema Tenant di PRD: id, nama_pondok, kode_tenant, logo_url, status,
    // admin_awal_id, tanggal_daftar — belum ada lokasi/kategori).
    final lokasi = tenant['lokasi'] as String?;
    final kategori = tenant['kategori'] as String?;
    final waktuDaftar = tenant['tanggalDaftar'] as String?;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _WC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _WC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(nama, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _WC.ink)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _WC.surfaceDim, borderRadius: BorderRadius.circular(999)),
                child: Text(kode, style: const TextStyle(fontSize: 10, color: _WC.inkSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.link_rounded, size: 13, color: _WC.inkSecondary),
              const SizedBox(width: 4),
              Text('$kode.sistempesantren.com', style: const TextStyle(fontSize: 11.5, color: _WC.inkSecondary)),
            ],
          ),
          if (waktuDaftar != null || lokasi != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (waktuDaftar != null) ...[
                  const Icon(Icons.schedule_rounded, size: 13, color: _WC.inkSecondary),
                  const SizedBox(width: 4),
                  Text(waktuDaftar, style: const TextStyle(fontSize: 11.5, color: _WC.inkSecondary)),
                  const SizedBox(width: 10),
                ],
                if (lokasi != null) ...[
                  const Icon(Icons.place_outlined, size: 13, color: _WC.inkSecondary),
                  const SizedBox(width: 4),
                  Expanded(child: Text(lokasi, style: const TextStyle(fontSize: 11.5, color: _WC.inkSecondary))),
                ],
              ],
            ),
          ],
          if (kategori != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.menu_book_outlined, size: 13, color: _WC.inkSecondary),
                const SizedBox(width: 4),
                Text(kategori, style: const TextStyle(fontSize: 11.5, color: _WC.inkSecondary)),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFF1B8B8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  onPressed: onTolak,
                  child: const Text('Tolak',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _WC.errorText)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _WC.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  onPressed: onSetujui,
                  child: const Text('Setujui Tenant',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SATenantCard extends StatelessWidget {
  final Map<String, dynamic> tenant;
  final VoidCallback onSuspend;
  final VoidCallback onAktifkan;
  const _SATenantCard({required this.tenant, required this.onSuspend, required this.onAktifkan});

  @override
  Widget build(BuildContext context) {
    final nama = tenant['namaPondok'] as String? ?? '-';
    final kode = tenant['kodeTenant'] as String? ?? '-';
    final status = (tenant['status'] as String? ?? '').toUpperCase();
    final jumlahUser = tenant['jumlahUser']?.toString() ??
        ((tenant['_count'] as Map?)?['santris']?.toString()) ??
        '0';

    final isSuspended = status == 'SUSPENDED';
    final isPending = status == 'PENDING';
    final statusBg = isSuspended ? const Color(0xFFFEE2E2) : (isPending ? _WC.pendingBg : _WC.successBg);
    final statusFg = isSuspended ? _WC.errorText : (isPending ? _WC.pendingText : _WC.successText);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _WC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _WC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(nama, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _WC.ink))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(999)),
                child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusFg)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(kode, style: const TextStyle(fontSize: 11.5, color: _WC.inkSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.groups_2_outlined, size: 14, color: _WC.inkSecondary),
              const SizedBox(width: 4),
              Text('$jumlahUser Users', style: const TextStyle(fontSize: 11.5, color: _WC.inkSecondary)),
              const Spacer(),
              if (isSuspended)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _WC.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  onPressed: onAktifkan,
                  child: const Text('Pulihkan Tenant',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                )
              else if (!isPending)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFF1B8B8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  onPressed: onSuspend,
                  child: const Text('Suspend',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _WC.errorText)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SAAuditItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String time;
  // Dipakai untuk kalimat polos (mis. dari data API):
  final String? title;
  // Dipakai untuk kalimat dengan bagian bold, sesuai desain
  // (mis. "Security Alert:" bold, lalu kalimat normal, lalu "darussalam2" bold lagi):
  final String? boldPrefix;
  final String? text;
  final String? boldSuffix;
  final String? afterBoldSuffix;
  final Color textColor;

  final bool isLast;

  const _SAAuditItem({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.time,
    this.title,
    this.boldPrefix,
    this.text,
    this.boldSuffix,
    this.afterBoldSuffix,
    this.textColor = _WC.ink,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: iconFg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (boldPrefix != null)
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 12.5, height: 1.35, color: textColor),
                      children: [
                        TextSpan(text: boldPrefix, style: const TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: text ?? '', style: const TextStyle(fontWeight: FontWeight.w400)),
                        if (boldSuffix != null)
                          TextSpan(text: boldSuffix, style: const TextStyle(fontWeight: FontWeight.w700)),
                        if (afterBoldSuffix != null)
                          TextSpan(text: afterBoldSuffix, style: const TextStyle(fontWeight: FontWeight.w400)),
                      ],
                    ),
                  )
                else
                  Text(title ?? '-', style: TextStyle(fontSize: 12.5, color: textColor, height: 1.3)),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(fontSize: 11, color: _WC.inkSecondary)),
              ],
            ),
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
