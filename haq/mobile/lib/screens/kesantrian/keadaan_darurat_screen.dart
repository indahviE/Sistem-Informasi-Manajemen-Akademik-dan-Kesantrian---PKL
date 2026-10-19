import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../santri/santri_ui.dart' show SC;

/// Palet layar Keadaan Darurat — sama dengan layar redesain lain
/// (beranda ustadz, absensi, konseling): zamrud + emas + gading.
class _DC {
  _DC._();

  static Color get primary => SC.primary;
  static Color get primaryEnd => SC.primaryEnd;

  static const gold = Color(0xFFC5A059);
  static const goldSurface = Color(0xFFFAF5EC);
  static const goldBorder = Color(0xFFE7D2A7);
  static const goldDark = Color(0xFF7A5B10);

  static const mint = Color(0xFFD2E4DC);
  static const sage = Color(0xFFE2ECE9);

  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);
  static const surfaceContainer = Color(0xFFEFEEEA);

  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const border = Color(0xFFEAE6DC);
  static const inputBorder = Color(0xFFE2E8F0);

  static const danger = Color(0xFFB91C1C);
  static const errorBg = Color(0xFFFEE2E2);
  static const errorText = Color(0xFF991B1B);

  static const amberBg = Color(0xFFFDE9B8);
  static const pendingBg = Color(0xFFFFF8E1);
  static const pendingText = Color(0xFFB78103);

  static const successBg = Color(0xFFD8F0E2);
  static const successText = Color(0xFF1B5E20);
}

// ---------------------------------------------------------------------------
// Helper status, jenis, dan format waktu
// ---------------------------------------------------------------------------

class _St {
  final String label;
  final Color fg;
  final Color bg;
  final IconData icon;
  const _St(this.label, this.fg, this.bg, this.icon);
}

_St _st(String s) {
  switch (s) {
    case 'DITANGANI':
      return const _St('DITANGANI', _DC.goldDark, _DC.amberBg, Icons.pending_actions_rounded);
    case 'SELESAI':
      return const _St('SELESAI', _DC.successText, _DC.successBg, Icons.check_circle_outline_rounded);
    default:
      return const _St('BARU', _DC.errorText, _DC.errorBg, Icons.emergency_rounded);
  }
}

IconData _jenisIcon(String jenis) {
  final j = jenis.toLowerCase();
  if (j.contains('sakit') || j.contains('demam') || j.contains('alergi')) {
    return Icons.medical_services_outlined;
  }
  if (j.contains('kecelakaan') || j.contains('cedera') || j.contains('luka')) {
    return Icons.personal_injury_outlined;
  }
  if (j.contains('hilang') || j.contains('izin')) return Icons.person_search_outlined;
  if (j.contains('keamanan') || j.contains('pencuri') || j.contains('kebakaran')) {
    return Icons.shield_outlined;
  }
  return Icons.emergency_rounded;
}

const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String _tgl(DateTime d) => '${d.day.toString().padLeft(2, '0')} ${_bulan[d.month - 1]} ${d.year}';

String _jam(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} WIB';

String _waktuLabel(DateTime? d) {
  if (d == null) return '-';
  final now = DateTime.now();
  final a = DateTime(d.year, d.month, d.day);
  final b = DateTime(now.year, now.month, now.day);
  final diff = b.difference(a).inDays;
  if (diff == 0) return '${_jam(d)} (Hari ini)';
  if (diff == 1) return 'Kemarin, ${_jam(d)}';
  return _tgl(d);
}

// ---------------------------------------------------------------------------
// Layar utama
// ---------------------------------------------------------------------------

class KeadaanDaruratScreen extends StatefulWidget {
  const KeadaanDaruratScreen({super.key});

  @override
  State<KeadaanDaruratScreen> createState() => _KeadaanDaruratScreenState();
}

class _KeadaanDaruratScreenState extends State<KeadaanDaruratScreen> {
  /// Sama dengan _maxMobileWidth di shell_screen.dart.
  static const double _maxWidth = 480;

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _filter = 'SEMUA'; // SEMUA | BARU | DITANGANI | SELESAI
  final Set<String> _open = {}; // id laporan yang sedang dibuka
  bool _firstLoad = true;

  /// Wali tidak boleh melapor. Pimpinan/Mudir bertugas menerima & menindaklanjuti
  /// laporan, bukan membuatnya. Admin dan role lain tetap bisa melapor.
  bool get _bisaLapor {
    final user = AppScope.of(context).user;
    return user?.isWali != true && user?.isPimpinan != true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.keadaanDarurat);
      if (!mounted) return;
      final list = (res as List).cast<Map<String, dynamic>>();
      setState(() {
        _items = list;
        _loading = false;
        if (_firstLoad) {
          // Laporan baru langsung terbuka supaya cepat terbaca.
          for (final d in list) {
            if ((d['status'] ?? 'BARU') == 'BARU') _open.add('${d['id']}');
          }
          _firstLoad = false;
        }
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    }
  }

  // ---- Notifikasi ----
  /// Notifikasi melayang bertema (sukses = zamrud, gagal = merah lembut).
  void _toast(String title, {String? subtitle, bool error = false}) {
    if (!mounted) return;
    final w = MediaQuery.of(context).size.width;
    final side = w > 472 ? (w - 440) / 2 : 16.0;
    final fg = error ? _DC.errorText : Colors.white;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? _DC.errorBg : _DC.primary,
          elevation: 6,
          // 88 = jarak dari bawah supaya tidak menutupi tombol "Lapor Darurat"
          margin: EdgeInsets.fromLTRB(side, 0, side, 88),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          duration: Duration(seconds: error ? 4 : 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: error ? _DC.errorText.withOpacity(0.25) : _DC.gold.withOpacity(0.5),
            ),
          ),
          content: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: error ? Colors.white : _DC.gold.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  error ? Icons.error_outline : Icons.check_rounded,
                  size: 18,
                  color: error ? _DC.errorText : _DC.gold,
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

  // ---- Lapor ----
  Future<void> _lapor() async {
    if (!_bisaLapor) return;
    final api = AppScope.of(context).api;
    final payload = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 480),
      builder: (_) => _LaporSheet(api: api),
    );
    if (payload == null || !mounted) return;
    try {
      await api.post(ApiUrl.keadaanDarurat, payload);
      if (!mounted) return;
      _toast('Laporan darurat dikirim',
          subtitle: 'Admin & Pimpinan akan segera mendapat notifikasi');
      _load();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message, error: true);
    }
  }

  // ---- Tindak lanjut (Admin / Pimpinan) ----
  Future<void> _tangani(Map<String, dynamic> item) async {
    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 480),
      builder: (_) => _TindakSheet(item: item),
    );
    if (res == null || !mounted) return;
    try {
      final api = AppScope.of(context).api;
      await api.patch('${ApiUrl.keadaanDarurat}/${item['id']}', res);
      if (!mounted) return;
      _toast('Status laporan diperbarui', subtitle: '${item['jenis']}');
      _load();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message, error: true);
    }
  }

  int _count(String status) => _items.where((e) => (e['status'] ?? 'BARU') == status).length;

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).user;
   final bisaTangani = user?.isAdmin == true || user?.isMusyrif == true;
    final bisaLapor = _bisaLapor;

    final konten = _loading
        ? Center(child: CircularProgressIndicator(color: _DC.primary, strokeWidth: 2.5))
        : _error != null
            ? _errorView()
            : RefreshIndicator(
                color: _DC.primary,
                onRefresh: _load,
                child: _body(bisaTangani),
              );

    // Konten dibatasi selebar _maxWidth dan diletakkan di tengah, sama seperti
    // halaman login dan bottom nav di shell (480px) — di web tidak melebar.
    return Scaffold(
      backgroundColor: _DC.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Stack(
            children: [
              Positioned.fill(child: konten),
              if (bisaLapor)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.extended(
                    onPressed: _lapor,
                    tooltip: 'Lapor Keadaan Darurat',
                    backgroundColor: _DC.danger,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    icon: const Icon(Icons.add_alert_rounded),
                    label: const Text('Lapor Darurat', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(bool bisaTangani) {
    final baru = _count('BARU');
    final proses = _count('DITANGANI');
    final selesai = _count('SELESAI');
    final tampil = _filter == 'SEMUA'
        ? _items
        : _items.where((e) => (e['status'] ?? 'BARU') == _filter).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: _bisaLapor ? 110 : 24),
      children: [
        _hero(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: _stat('Baru', baru, 'Laporan', Icons.emergency_rounded, _DC.errorText, _DC.errorBg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _stat('Proses', proses, 'Kasus', Icons.pending_actions_rounded, _DC.goldDark, _DC.amberBg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _stat('Selesai', selesai, 'Pulih', Icons.check_circle_outline_rounded,
                    _DC.successText, _DC.successBg),
              ),
            ],
          ),
        ),
        if (_items.isNotEmpty) ...[
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _chip('SEMUA', 'Semua (${_items.length})'),
                _chip('BARU', 'Baru ($baru)', dot: _DC.errorText),
                _chip('DITANGANI', 'Ditangani ($proses)', dot: _DC.goldDark),
                _chip('SELESAI', 'Selesai ($selesai)', dot: _DC.successText),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (_items.isEmpty)
          _emptyState('Belum ada laporan keadaan darurat.')
        else if (tampil.isEmpty)
          _emptyState('Tidak ada laporan dengan status ini.')
        else
          for (final d in tampil) _card(d, bisaTangani),
        if (_items.isNotEmpty && baru == 0) _footerAman(),
      ],
    );
  }

  // ---- Hero ----
  Widget _hero() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [_DC.primary, _DC.primaryEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -26,
            child: Icon(Icons.mosque_outlined, size: 120, color: Colors.white.withOpacity(0.06)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: _DC.gold, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      "SIAGA MA'HAD",
                      style: TextStyle(
                        color: _DC.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _DC.background,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 13, color: _DC.primary),
                        const SizedBox(width: 6),
                        Text(
                          _tgl(DateTime.now()),
                          style: TextStyle(
                              color: _DC.primary, fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Keadaan Darurat',
                style: TextStyle(
                    color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.3),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pantau dan tangani laporan\nkedaruratan santri',
                style: TextStyle(color: _DC.mint, fontSize: 13.5, height: 1.35),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int n, String caption, IconData icon, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: _DC.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _DC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: _DC.inkSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, size: 16, color: fg),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('$n', style: TextStyle(color: fg, fontSize: 26, fontWeight: FontWeight.w800, height: 1)),
          const SizedBox(height: 2),
          Text(caption, style: const TextStyle(color: _DC.inkSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _chip(String key, String label, {Color? dot}) {
    final selected = _filter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => setState(() => _filter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? _DC.primary : _DC.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? _DC.primary : _DC.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot != null && !selected) ...[
                Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : _DC.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Kartu laporan ----
  Widget _card(Map<String, dynamic> d, bool bisaTangani) {
    final id = '${d['id']}';
    final status = (d['status'] as String?) ?? 'BARU';
    final st = _st(status);
    final jenis = (d['jenis'] as String?) ?? 'Darurat';
    final santri = (d['santri'] as Map?)?.cast<String, dynamic>();
    final kelas = (santri?['kelas'] as Map?)?['namaKelas'];
    final lokasi = ((d['lokasi'] as String?) ?? '').trim();
    final deskripsi = (d['deskripsi'] as String?) ?? '';
    final tindak = (d['tindakLanjut'] as String?)?.trim();
    final dt = DateTime.tryParse('${d['tanggal']}')?.toLocal();
    final open = _open.contains(id);

    final nama = santri == null ? 'Umum' : '${santri['nama']}';
    final sub = kelas != null ? '$nama • $kelas' : nama;
    final adaLokasi = lokasi.isNotEmpty;

    void toggle() => setState(() => open ? _open.remove(id) : _open.add(id));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: _DC.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _DC.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: toggle,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: st.bg, borderRadius: BorderRadius.circular(14)),
                    child: Icon(_jenisIcon(jenis), color: st.fg, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(jenis,
                            style: const TextStyle(
                                color: _DC.ink, fontSize: 16, fontWeight: FontWeight.w800, height: 1.25)),
                        const SizedBox(height: 3),
                        Text(sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: _DC.inkSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _badge(st),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Waktu & lokasi
            Container(
              padding: open ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10) : EdgeInsets.zero,
              decoration: open
                  ? BoxDecoration(color: _DC.surfaceDim, borderRadius: BorderRadius.circular(14))
                  : null,
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 16, color: _DC.inkSecondary),
                  const SizedBox(width: 6),
                  Text(_waktuLabel(dt),
                      style: const TextStyle(
                          color: _DC.inkSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  if (adaLokasi) ...[
                    const SizedBox(width: 10),
                    Container(width: 1, height: 14, color: _DC.border),
                    const SizedBox(width: 10),
                    const Icon(Icons.location_on_outlined, size: 16, color: _DC.goldDark),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(lokasi,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: _DC.inkSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Deskripsi
            if (open)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _DC.background, borderRadius: BorderRadius.circular(14)),
                child: Text(deskripsi,
                    style: const TextStyle(color: _DC.ink, fontSize: 14, height: 1.45)),
              )
            else
              Text(deskripsi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _DC.inkSecondary, fontSize: 13.5, height: 1.4)),

            // Tindak lanjut
            if (open && tindak != null && tindak.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _DC.sage, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_user_outlined, size: 15, color: _DC.primary),
                        SizedBox(width: 6),
                        Text('TINDAK LANJUT',
                            style: TextStyle(
                                color: _DC.primary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(tindak, style: const TextStyle(color: _DC.ink, fontSize: 13.5, height: 1.4)),
                  ],
                ),
              ),
            ],

            // Aksi
            if (open && bisaTangani) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => _tangani(d),
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  label: const Text('Update Tindak Lanjut',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                  style: FilledButton.styleFrom(
                    backgroundColor: _DC.amberBg,
                    foregroundColor: _DC.goldDark,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text("Akses: Admin & Musyrif Ma'had",
                    style: TextStyle(color: _DC.inkSecondary, fontSize: 11.5)),
              ),
            ] else if (open && status != 'SELESAI') ...[
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 15, color: _DC.inkSecondary),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text('Tindak lanjut dilakukan oleh Admin & Musyrif.',
                        style: TextStyle(color: _DC.inkSecondary, fontSize: 12)),
                  ),
                ],
              ),
            ],

            // Toggle
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: toggle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(open ? 'Sembunyikan' : 'Detail Penanganan',
                          style: TextStyle(
                              color: _DC.primary, fontSize: 13, fontWeight: FontWeight.w800)),
                      Icon(open ? Icons.expand_less_rounded : Icons.chevron_right_rounded,
                          size: 20, color: _DC.primary),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(_St st) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: st.bg, borderRadius: BorderRadius.circular(999)),
      child: Text(st.label,
          style: TextStyle(color: st.fg, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
    );
  }

  Widget _footerAman() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _DC.surfaceDim, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: _DC.primary, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.verified_user_outlined, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alhamdulillah, Terkendali',
                    style: TextStyle(color: _DC.ink, fontSize: 14.5, fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('Tidak ada laporan baru yang menunggu penanganan.',
                    style: TextStyle(color: _DC.inkSecondary, fontSize: 12.5, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(color: _DC.sage, shape: BoxShape.circle),
            child: Icon(Icons.verified_user_outlined, size: 40, color: _DC.primary),
          ),
          const SizedBox(height: 14),
          Text(msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _DC.inkSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: _DC.errorBg, shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off_rounded, size: 34, color: _DC.errorText),
            ),
            const SizedBox(height: 12),
            Text(_error ?? 'Terjadi kesalahan.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _DC.inkSecondary, fontSize: 14)),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _load,
              style: FilledButton.styleFrom(backgroundColor: _DC.primary, shape: const StadiumBorder()),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kerangka bottom sheet (dipakai form Lapor & Tindak Lanjut)
// ---------------------------------------------------------------------------

class _SheetShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final Widget body;
  final Widget footer;

  const _SheetShell({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.body,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: (mq.size.height - mq.viewInsets.bottom) * 0.94),
        child: Container(
          decoration: const BoxDecoration(
            color: _DC.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: _DC.border, borderRadius: BorderRadius.circular(4)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
                      child: Icon(icon, color: iconFg, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  color: _DC.ink, fontSize: 18, fontWeight: FontWeight.w800)),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(subtitle!,
                                style: const TextStyle(color: _DC.inkSecondary, fontSize: 12.5, height: 1.3)),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(backgroundColor: _DC.surfaceContainer),
                      icon: const Icon(Icons.close_rounded, size: 20, color: _DC.ink),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: _DC.border),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: body,
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + mq.padding.bottom),
                decoration: const BoxDecoration(
                  color: _DC.background,
                  border: Border(top: BorderSide(color: _DC.border)),
                ),
                child: footer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _footerButtons({
  required BuildContext context,
  required String submitLabel,
  required IconData submitIcon,
  required VoidCallback onSubmit,
}) {
  return Row(
    children: [
      Expanded(
        flex: 2,
        child: SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: _DC.surfaceContainer,
              foregroundColor: _DC.ink,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 3,
        child: SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: onSubmit,
            icon: Icon(submitIcon, size: 20),
            label: Text(submitLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            style: FilledButton.styleFrom(
              backgroundColor: _DC.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _label(String text, {bool required = false, String? tag, bool tagStrong = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Text(text, style: const TextStyle(color: _DC.ink, fontSize: 15, fontWeight: FontWeight.w800)),
        if (required)
          const Text(' *', style: TextStyle(color: _DC.danger, fontSize: 15, fontWeight: FontWeight.w800)),
        const Spacer(),
        if (tag != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tagStrong ? Colors.transparent : _DC.surfaceContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(tag,
                style: TextStyle(
                  color: tagStrong ? _DC.primary : _DC.inkSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                )),
          ),
      ],
    ),
  );
}

InputDecoration _dec(String hint, {IconData? icon, Color? iconColor, String? counter}) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _DC.inkSecondary, fontSize: 14),
    prefixIcon: icon == null ? null : Icon(icon, size: 20, color: iconColor ?? _DC.inkSecondary),
    filled: true,
    fillColor: _DC.surface,
    counterText: counter ?? '',
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: b(_DC.inputBorder),
    enabledBorder: b(_DC.inputBorder),
    focusedBorder: b(_DC.primary, 1.5),
  );
}

// ---------------------------------------------------------------------------
// Sheet: Lapor Keadaan Darurat
// ---------------------------------------------------------------------------

class _LaporSheet extends StatefulWidget {
  final ApiClient api;
  const _LaporSheet({required this.api});

  @override
  State<_LaporSheet> createState() => _LaporSheetState();
}

class _LaporSheetState extends State<_LaporSheet> {
  static const _opsi = <(String, IconData)>[
    ('Sakit Mendadak', Icons.medical_services_outlined),
    ('Kecelakaan/Cedera', Icons.personal_injury_outlined),
    ('Kehilangan Santri', Icons.person_search_outlined),
    ('Keamanan Pondok', Icons.shield_outlined),
    ('Lainnya', Icons.more_horiz_rounded),
  ];
  static const _maxDeskripsi = 500;

  final _cari = TextEditingController();
  final _jenisLain = TextEditingController();
  final _lokasi = TextEditingController();
  final _deskripsi = TextEditingController();
  Timer? _debounce;

  Map<String, dynamic>? _santri;
  List<Map<String, dynamic>> _hasil = [];
  bool _mencari = false;
  String? _jenis;
  bool _tampilError = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _cari.dispose();
    _jenisLain.dispose();
    _lokasi.dispose();
    _deskripsi.dispose();
    super.dispose();
  }

  void _onCari(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() {
        _hasil = [];
        _mencari = false;
      });
      return;
    }
    setState(() => _mencari = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final res = await widget.api.get(ApiUrl.santri, query: {'search': q.trim(), 'perPage': '6'});
        if (!mounted) return;
        setState(() {
          _hasil = ((res['items'] as List?) ?? []).cast<Map<String, dynamic>>();
          _mencari = false;
        });
      } catch (_) {
        if (mounted) setState(() => _mencari = false);
      }
    });
  }

  String get _jenisFinal => _jenis == 'Lainnya' ? _jenisLain.text.trim() : (_jenis ?? '');

  void _kirim() {
    setState(() => _tampilError = true);
    if (_jenisFinal.isEmpty || _deskripsi.text.trim().isEmpty) return;
    Navigator.pop(context, {
      'santriId': _santri?['id'],
      'jenis': _jenisFinal,
      'lokasi': _lokasi.text.trim().isEmpty ? null : _lokasi.text.trim(),
      'deskripsi': _deskripsi.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Lapor Keadaan Darurat',
      subtitle: 'Admin dan Pimpinan akan mendapat notifikasi segera.',
      icon: Icons.emergency_rounded,
      iconBg: _DC.errorBg,
      iconFg: _DC.errorText,
      footer: _footerButtons(
        context: context,
        submitLabel: 'Kirim Laporan Darurat',
        submitIcon: Icons.send_rounded,
        onSubmit: _kirim,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Peringatan
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _DC.goldSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _DC.goldBorder),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: _DC.goldDark, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gunakan formulir ini hanya untuk situasi kritis yang membutuhkan penanganan medis, '
                    'keselamatan santri, atau pengamanan pondok secara cepat.',
                    style: TextStyle(color: _DC.goldDark, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Santri
          _label('Santri Terkait', tag: 'Opsional'),
          if (_santri != null)
            _santriTerpilih()
          else ...[
            TextField(
              controller: _cari,
              onChanged: _onCari,
              decoration: _dec('Cari nama atau NIS, atau biarkan kosong', icon: Icons.person_search_outlined),
            ),
            if (_mencari)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: LinearProgressIndicator(color: _DC.primary, minHeight: 2),
              ),
            if (_hasil.isNotEmpty) _hasilCari(),
          ],
          const SizedBox(height: 18),

          // Jenis
          _label('Jenis Kedaruratan', required: true, tag: 'Wajib Diisi', tagStrong: true),
          LayoutBuilder(
            builder: (context, c) {
              final w = (c.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [for (final o in _opsi) SizedBox(width: w, child: _jenisTile(o.$1, o.$2))],
              );
            },
          ),
          if (_jenis == 'Lainnya') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _jenisLain,
              onChanged: (_) => setState(() {}),
              decoration: _dec('Tulis jenis kedaruratan'),
            ),
          ],
          if (_tampilError && _jenisFinal.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Pilih jenis kedaruratan.',
                  style: TextStyle(color: _DC.errorText, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 18),

          // Lokasi
          _label('Lokasi Kejadian', tag: 'Opsional'),
          TextField(
            controller: _lokasi,
            decoration: _dec('Contoh: Asrama Putra Blok B, Kamar 04',
                icon: Icons.location_on_outlined, iconColor: _DC.goldDark),
          ),
          const SizedBox(height: 18),

          // Deskripsi
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Text('Deskripsi Kronologi & Kondisi',
                    style: TextStyle(color: _DC.ink, fontSize: 15, fontWeight: FontWeight.w800)),
                const Text(' *',
                    style: TextStyle(color: _DC.danger, fontSize: 15, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${_deskripsi.text.length} / $_maxDeskripsi',
                    style: const TextStyle(color: _DC.inkSecondary, fontSize: 12)),
              ],
            ),
          ),
          TextField(
            controller: _deskripsi,
            maxLines: 5,
            minLines: 4,
            maxLength: _maxDeskripsi,
            onChanged: (_) => setState(() {}),
            decoration: _dec('Ceritakan apa yang terjadi, kondisi santri, dan tindakan awal yang sudah dilakukan.'),
          ),
          if (_tampilError && _deskripsi.text.trim().isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Deskripsi wajib diisi.',
                  style: TextStyle(color: _DC.errorText, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _jenisTile(String label, IconData icon) {
    final sel = _jenis == label;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _jenis = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: sel ? _DC.primary : _DC.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? _DC.primary : _DC.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: sel ? Colors.white : _DC.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: sel ? Colors.white : _DC.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _santriTerpilih() {
    final s = _santri!;
    final kelas = (s['kelas'] as Map?)?['namaKelas'];
    final nis = s['nis'];
    final info = [if (nis != null) 'NIS $nis', if (kelas != null) '$kelas'].join(' • ');
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: _DC.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _DC.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: _DC.sage, shape: BoxShape.circle),
            child: Icon(Icons.school_outlined, size: 20, color: _DC.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s['nama']}',
                    style: const TextStyle(color: _DC.ink, fontSize: 14.5, fontWeight: FontWeight.w800)),
                if (info.isNotEmpty)
                  Text(info, style: const TextStyle(color: _DC.inkSecondary, fontSize: 12.5)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() {
              _santri = null;
              _hasil = [];
              _cari.clear();
            }),
            style: IconButton.styleFrom(backgroundColor: _DC.surfaceContainer),
            icon: const Icon(Icons.close_rounded, size: 18, color: _DC.ink),
          ),
        ],
      ),
    );
  }

  Widget _hasilCari() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: _DC.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _DC.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _hasil.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _DC.border),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() {
                _santri = _hasil[i];
                _hasil = [];
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${_hasil[i]['nama']}',
                          style: const TextStyle(
                              color: _DC.ink, fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                    Text(
                      '${(_hasil[i]['kelas'] as Map?)?['namaKelas'] ?? ''}',
                      style: const TextStyle(color: _DC.inkSecondary, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet: Tindak Lanjuti Laporan (Admin / Pimpinan)
// ---------------------------------------------------------------------------

class _TindakSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  const _TindakSheet({required this.item});

  @override
  State<_TindakSheet> createState() => _TindakSheetState();
}

class _TindakSheetState extends State<_TindakSheet> {
  late String _status = (widget.item['status'] as String?) ?? 'BARU';
  late final TextEditingController _tindak =
      TextEditingController(text: widget.item['tindakLanjut'] as String? ?? '');

  static const _hint = {
    'BARU': 'Laporan belum ditangani.',
    'DITANGANI': 'Pilih "Ditangani" saat tindakan medis atau penanganan awal santri dimulai.',
    'SELESAI': 'Pilih "Selesai" setelah kondisi santri pulih dan kasus ditutup.',
  };

  @override
  void dispose() {
    _tindak.dispose();
    super.dispose();
  }

  void _tambah(String teks) {
    final cur = _tindak.text.trim();
    setState(() {
      _tindak.text = cur.isEmpty ? teks : '$cur\n$teks';
      _tindak.selection = TextSelection.collapsed(offset: _tindak.text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.item;
    final santri = (d['santri'] as Map?)?.cast<String, dynamic>();
    final kelas = (santri?['kelas'] as Map?)?['namaKelas'];
    final lokasi = (d['lokasi'] as String?)?.trim();
    final dt = DateTime.tryParse('${d['tanggal']}')?.toLocal();
    final stAwal = _st((d['status'] as String?) ?? 'BARU');
    final ringkas = [
      santri == null ? 'Umum' : '${santri['nama']}',
      if (kelas != null) '$kelas',
      if (lokasi != null && lokasi.isNotEmpty) lokasi,
    ].join(' • ');

    return _SheetShell(
      title: 'Tindak Lanjuti Laporan',
      subtitle: 'Pembaruan status & catatan kedaruratan',
      icon: Icons.edit_note_rounded,
      iconBg: _DC.amberBg,
      iconFg: _DC.goldDark,
      footer: _footerButtons(
        context: context,
        submitLabel: 'Simpan Status',
        submitIcon: Icons.check_circle_outline_rounded,
        onSubmit: () => Navigator.pop(context, {
          'status': _status,
          'tindakLanjut': _tindak.text.trim().isEmpty ? null : _tindak.text.trim(),
        }),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ringkasan laporan
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _DC.surfaceDim, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: stAwal.bg, borderRadius: BorderRadius.circular(999)),
                      child: Text(stAwal.label,
                          style: TextStyle(
                              color: stAwal.fg, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                    ),
                  ],
                ),
                Text('${d['jenis']}',
                    style: const TextStyle(color: _DC.ink, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(ringkas, style: const TextStyle(color: _DC.inkSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 15, color: _DC.goldDark),
                    const SizedBox(width: 6),
                    Text(dt == null ? '-' : '${_tgl(dt)}, ${_jam(dt)}',
                        style: const TextStyle(color: _DC.inkSecondary, fontSize: 12.5)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Status
          _label('Status Penanganan', required: true),
          Row(
            children: [
              for (final s in const ['BARU', 'DITANGANI', 'SELESAI']) ...[
                Expanded(child: _statusTile(s)),
                if (s != 'SELESAI') const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 15, color: _DC.goldDark),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_hint[_status] ?? '',
                    style: const TextStyle(color: _DC.goldDark, fontSize: 12.5, height: 1.35)),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Tindak lanjut
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Text('Tindakan & Perkembangan Santri',
                    style: TextStyle(color: _DC.ink, fontSize: 15, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${_tindak.text.length} karakter',
                    style: const TextStyle(color: _DC.inkSecondary, fontSize: 12)),
              ],
            ),
          ),
          TextField(
            controller: _tindak,
            maxLines: 6,
            minLines: 4,
            onChanged: (_) => setState(() {}),
            decoration: _dec('Tulis tindakan yang sudah dilakukan dan perkembangan kondisi santri.'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quick('+ Hubungi Wali', 'Wali santri telah dihubungi.'),
              _quick('+ Rujuk Poskestren', 'Santri dirujuk ke Poskestren.'),
              _quick('+ Rujuk RSUD', 'Santri dirujuk ke RSUD.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusTile(String s) {
    final st = _st(s);
    final sel = _status == s;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => _status = s),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: sel ? st.bg : _DC.surfaceDim,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: sel ? st.fg.withOpacity(0.35) : Colors.transparent, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(sel ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 22, color: sel ? st.fg : _DC.inkSecondary),
            const SizedBox(height: 6),
            Text(st.label,
                style: TextStyle(
                  color: sel ? st.fg : _DC.inkSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                )),
          ],
        ),
      ),
    );
  }

  Widget _quick(String label, String teks) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => _tambah(teks),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _DC.surfaceContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: const TextStyle(color: _DC.ink, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ),
    );
  }
}