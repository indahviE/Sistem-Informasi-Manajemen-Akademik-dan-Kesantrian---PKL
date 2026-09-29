// pengaturan_admin_screen.dart
//
// Pengaturan — Admin Lembaga (pondok).
//
// Layar ini TIDAK punya Scaffold/AppBar sendiri: dirancang nempel di dalam
// ShellScreen (header + bottom nav dibawa shell), sama seperti Notifikasi.
//
// Data dari backend: GET /pengaturan/admin, PATCH /pengaturan/admin/notifikasi,
// PATCH /pengaturan/profil, PATCH /pengaturan/ubah-password.
//
// PENTING - sesuaikan 3 import di bawah dengan lokasi file aslinya:
//   - api_client.dart & app_scope.dart: samakan dengan pengaturan_screen.dart Super Admin
//   - pengaturan_dialogs.dart: file milik Super Admin (showEditProfilSheet,
//     showUbahPasswordSheet), dipakai ulang di sini.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../super_admin/pengaturan_dialogs.dart';

// ============================================================================
// Token warna lokal (emerald + emas). Private supaya tidak bentrok dengan
// PColors/PText milik Super Admin. Kalau dashboard admin sudah punya file
// token sendiri, ganti _AC.* dengan token itu.
// ============================================================================

class _AC {
  // Nilai disamakan dengan _WC di dashboard_screen.dart.
  static const primary = Color(0xFF0F3A2E);
  static const primarySoft = Color(0xFF1B4D3E);
  static const mint = Color(0xFFD2E4DC);
  static const gold = Color(0xFFF9D77E); // emas terang khusus tombol upgrade (sesuai screen.png)
  static const goldDark = Color(0xFF7A5B10);
  static const background = Color(0xFFFAF9F5);
  static const surface = Colors.white;
  static const surfaceDim = Color(0xFFF5F4EE);
  static const line = Color(0xFFEAE6DC);
  static const inkSecondary = Color(0xFF475569);
  static const sage = Color(0xFFE2ECE9);
  static const errorBg = Color(0xFFFEE2E2);
  static const errorText = Color(0xFF991B1B);
}

TextStyle _t(double size, FontWeight w, Color c, {double? height}) =>
    TextStyle(fontFamily: 'Nunito', fontSize: size, fontWeight: w, color: c, height: height);

// Nomor WhatsApp bantuan teknis (format internasional tanpa +, mis. 6281234567890).
// Kosong = tombol menampilkan info "belum diatur".
const String _kNomorBantuan = '';

// Definisi 5 toggle notifikasi (key = nama field di backend).
const List<({String key, String title, String desc})> _notifItems = [
  (
    key: 'perizinanBaru',
    title: 'Perizinan Baru Diajukan',
    desc: 'Pemberitahuan saat musyrif/santri mengajukan izin keluar/pulang',
  ),
  (
    key: 'pelanggaranBaru',
    title: 'Pelanggaran Baru Dicatat',
    desc: 'Laporan insiden kedisiplinan dan pengurangan poin santri',
  ),
  (
    key: 'waliBelumAktivasi',
    title: 'Wali Belum Aktivasi Akun',
    desc: 'Peringatan berkala jika ada token aktivasi wali yang kedaluwarsa',
  ),
  (
    key: 'eskalasiDarurat',
    title: 'Eskalasi Konseling & Medis Darurat',
    desc: 'Notifikasi prioritas tinggi kasus yang butuh perhatian Mudir/Admin',
  ),
  (
    key: 'rekapAbsensiShalat',
    title: 'Rekap Absensi Harian Shalat',
    desc: 'Kirim ringkasan otomatis tiap selesai shalat Isya berjamaah',
  ),
];

// ============================================================================
// Screen
// ============================================================================

class PengaturanAdminScreen extends StatefulWidget {
  const PengaturanAdminScreen({super.key, this.onBack});

  /// Dipanggil saat tombol panah kembali ditekan (mis. balik ke tab Beranda).
  final VoidCallback? onBack;

  @override
  State<PengaturanAdminScreen> createState() => _PengaturanAdminScreenState();
}

class _PengaturanAdminScreenState extends State<PengaturanAdminScreen> {
  bool _loading = true;
  bool _initialized = false;
  String? _error;

  Map<String, dynamic> _profil = {};
  Map<String, dynamic> _tenant = {};
  Map<String, dynamic>? _paket;
  final Map<String, bool> _notif = {
    for (final n in _notifItems) n.key: n.key != 'rekapAbsensiShalat',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  ApiClient get _api => AppScope.of(context).api;

  String get _urlAdmin => '${ApiUrl.pengaturan}/admin';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get(_urlAdmin) as Map<String, dynamic>;
      final notif = res['notifikasi'] as Map<String, dynamic>? ?? {};
      if (!mounted) return;
      setState(() {
        _profil = (res['profil'] as Map<String, dynamic>?) ?? {};
        _tenant = (res['tenant'] as Map<String, dynamic>?) ?? {};
        _paket = res['paket'] as Map<String, dynamic>?;
        for (final n in _notifItems) {
          final v = notif[n.key];
          if (v is bool) _notif[n.key] = v;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal memuat pengaturan: $e';
        _loading = false;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    AppToast.error(context, message);
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // -------------------------------------------------------------------
  // Edit Profil & Ubah Sandi (pakai bottom sheet milik Super Admin)
  // -------------------------------------------------------------------

  Future<void> _editProfil() async {
    final scope = AppScope.of(context);
    final api = _api;

    final saved = await showEditProfilSheet(
      context,
      nama: (_profil['nama'] ?? '') as String,
      email: (_profil['email'] ?? '') as String,
      onSubmit: (nama, email) async {
        await api.patch(ApiUrl.pengaturanProfil, {'nama': nama, 'email': email});
        await scope.updateProfil(nama: nama, email: email);
        if (mounted) {
          setState(() {
            _profil = {..._profil, 'nama': nama, 'email': email};
          });
        }
      },
    );

    if (saved == true && mounted) AppToast.success(context, 'Perubahan tersimpan');
  }

  Future<void> _ubahPassword() async {
    final api = _api;

    final saved = await showUbahPasswordSheet(
      context,
      onSubmit: (lama, baru) async {
        await api.patch(ApiUrl.pengaturanUbahPassword, {
          'passwordLama': lama,
          'passwordBaru': baru,
        });
      },
    );

    if (saved == true && mounted) AppToast.success(context, 'Password berhasil diubah');
  }

  // -------------------------------------------------------------------
  // Notifikasi (optimistic update, rollback kalau gagal)
  // -------------------------------------------------------------------

  Future<void> _toggleNotif(String key, bool value) async {
    final prev = _notif[key] ?? false;
    setState(() => _notif[key] = value);
    try {
      await _api.patch('$_urlAdmin/notifikasi', {key: value});
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _notif[key] = prev);
      _showError(e.message);
    }
  }

  // -------------------------------------------------------------------
  // Bantuan & logout
  // -------------------------------------------------------------------

  Future<void> _hubungiBantuan() async {
    if (_kNomorBantuan.isEmpty) {
      _showInfo('Nomor bantuan teknis belum diatur.');
      return;
    }
    final ok = await launchUrl(
      Uri.parse('https://wa.me/$_kNomorBantuan'),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) _showError('Tidak bisa membuka WhatsApp.');
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _AC.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Keluar dari Akun Admin?', style: _t(17, FontWeight.w800, _AC.primary)),
        content: Text(
          'Kamu perlu login kembali untuk mengakses pengaturan dan data pondok.',
          style: _t(13, FontWeight.w500, _AC.inkSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: _t(13, FontWeight.w700, _AC.inkSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AppScope.of(context).logout();
            },
            style: TextButton.styleFrom(foregroundColor: _AC.errorText),
            child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _AC.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _AC.primary));
    }
    if (_error != null) {
      return _LoadErrorState(message: _error!, onRetry: _load);
    }

    final namaPondok = (_tenant['namaPondok'] ?? 'Pondok') as String;

    return RefreshIndicator(
      color: _AC.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _TitleRow(onBack: widget.onBack),
          const SizedBox(height: 14),
          _ProfileCard(
            nama: (_profil['nama'] ?? '-') as String,
            email: (_profil['email'] ?? '-') as String,
            noHp: _profil['noHp'] as String?,
            role: (_profil['role'] ?? '') as String,
            onEditProfil: _editProfil,
            onUbahPassword: _ubahPassword,
          ),
          const SizedBox(height: 14),
          _PaketCard(
            paket: _paket,
            onUpgrade: () => _showInfo('Pengajuan upgrade kuota segera hadir.'),
          ),
          const SizedBox(height: 14),
          _NotifCard(values: _notif, onChanged: _toggleNotif),
          const SizedBox(height: 14),
          _PanduanCard(
            items: [
              _PanduanItem(
                icon: Icons.description_outlined,
                title: 'Pedoman & Tata Tertib',
                subtitle: 'Format PDF resmi Mudir Ma\'had',
                onTap: () => _showInfo('Segera hadir.'),
              ),
              _PanduanItem(
                icon: Icons.menu_book_outlined,
                title: 'Buku Panduan Admin',
                subtitle: 'Tata cara input nilai, mutaba\'ah & SPP',
                onTap: () => _showInfo('Segera hadir.'),
              ),
              _PanduanItem(
                icon: Icons.shield_outlined,
                title: 'Kebijakan Privasi & Enkripsi Santri',
                subtitle: 'Standar perlindungan data pribadi',
                onTap: () => _showInfo('Segera hadir.'),
              ),
              _PanduanItem(
                icon: Icons.support_agent_outlined,
                title: 'Hubungi Bantuan Teknis IT',
                subtitle: 'Layanan siaga WhatsApp 24/7',
                external: true,
                highlight: true,
                onTap: _hubungiBantuan,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _LogoutButton(onPressed: _confirmLogout),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Sistem Administrasi $namaPondok',
              textAlign: TextAlign.center,
              style: _t(11, FontWeight.w600, _AC.inkSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Error state
// ============================================================================

class _LoadErrorState extends StatelessWidget {
  const _LoadErrorState({required this.message, required this.onRetry});

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
            const Icon(Icons.error_outline, color: _AC.errorText, size: 32),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: _t(13, FontWeight.w500, _AC.inkSecondary)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: _AC.primary),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Shared
// ============================================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _AC.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0F3A2E), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        width: 50,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? _AC.primary : const Color(0xFFDAD8CF),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1))],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Title row
// ============================================================================

class _TitleRow extends StatelessWidget {
  const _TitleRow({this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: _AC.surfaceDim,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onBack,
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.arrow_back, size: 20, color: _AC.primary),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pengaturan', style: _t(20, FontWeight.w800, _AC.primary)),
              Text(
                'Akun & Preferensi Admin',
                overflow: TextOverflow.ellipsis,
                style: _t(12, FontWeight.w500, _AC.inkSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: _AC.sage, borderRadius: BorderRadius.circular(9999)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: _AC.primary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('Admin Aktif', style: _t(11, FontWeight.w800, _AC.primary)),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Profil
// ============================================================================

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.nama,
    required this.email,
    required this.noHp,
    required this.role,
    required this.onEditProfil,
    required this.onUbahPassword,
  });

  final String nama;
  final String email;
  final String? noHp;
  final String role;
  final VoidCallback onEditProfil;
  final VoidCallback onUbahPassword;

  String get _roleLabel => role == 'PIMPINAN' ? 'Pimpinan Pondok' : 'Admin Pondok';

  String get _inisial {
    final t = nama.trim();
    return t.isEmpty ? '?' : t.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: _AC.primary, shape: BoxShape.circle),
                child: Text(_inisial, style: _t(26, FontWeight.w800, _AC.gold)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nama, style: _t(17, FontWeight.w800, _AC.primary, height: 1.2)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: _AC.surfaceDim,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: _AC.line),
                      ),
                      child: Text(_roleLabel, style: _t(11, FontWeight.w700, _AC.inkSecondary)),
                    ),
                    const SizedBox(height: 8),
                    _InfoLine(icon: Icons.mail_outline, text: email),
                    if (noHp != null && noHp!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _InfoLine(icon: Icons.phone_outlined, text: noHp!),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 2FA belum tersedia di backend: tampil sebagai info, bukan status aktif.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: _AC.surfaceDim, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 20, color: _AC.inkSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Verifikasi 2 Langkah', style: _t(12, FontWeight.w800, _AC.primary)),
                      Text(
                        'Google Authenticator segera hadir',
                        style: _t(11, FontWeight.w500, _AC.inkSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.lock_outline, size: 18, color: _AC.inkSecondary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _GhostButton(icon: Icons.edit_outlined, label: 'Edit Profil', onPressed: onEditProfil),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _GhostButton(icon: Icons.key_outlined, label: 'Ubah Sandi', onPressed: onUbahPassword),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _AC.inkSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: _t(12, FontWeight.w500, _AC.inkSecondary),
          ),
        ),
      ],
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _AC.surfaceDim,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: _AC.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: _t(13, FontWeight.w700, _AC.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Paket langganan (tanpa bar penyimpanan)
// ============================================================================

class _PaketCard extends StatelessWidget {
  const _PaketCard({required this.paket, required this.onUpgrade});

  final Map<String, dynamic>? paket;
  final VoidCallback onUpgrade;

  static const _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  String? _tgl(dynamic iso) {
    if (iso is! String) return null;
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return null;
    return '${d.day} ${_bulan[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final p = paket;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _AC.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: p == null ? _kosong() : _isi(p),
    );
  }

  Widget _kosong() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Paket Langganan', style: _t(18, FontWeight.w800, Colors.white)),
        const SizedBox(height: 6),
        Text(
          'Belum ada paket aktif untuk pondok ini.',
          style: _t(12, FontWeight.w500, Colors.white70),
        ),
        const SizedBox(height: 14),
        _upgradeButton(),
      ],
    );
  }

  Widget _isi(Map<String, dynamic> p) {
    final periode = (p['periode'] ?? '') as String;
    final sisaHari = p['sisaHari'];
    final akhir = _tgl(p['tanggalAkhir']);
    final aktifLabel = [
      if (akhir != null) 'Aktif s.d. $akhir',
      if (sisaHari is int) 'Sisa $sisaHari Hari',
    ].join(' • ');

    final aktif = (p['santriAktif'] ?? 0) as int;
    final limit = (p['limitSantri'] ?? 0) as int;
    final persen = (p['persenSantri'] ?? 0) as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (periode.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: _AC.gold, borderRadius: BorderRadius.circular(9999)),
            child: Text(periode, style: _t(10, FontWeight.w800, _AC.primary)),
          ),
        const SizedBox(height: 10),
        Text((p['nama'] ?? 'Paket') as String, style: _t(20, FontWeight.w800, Colors.white)),
        if (aktifLabel.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(aktifLabel, style: _t(12, FontWeight.w600, Colors.white60)),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.groups_outlined, size: 16, color: Colors.white60),
            const SizedBox(width: 6),
            Expanded(child: Text('Santri Aktif', style: _t(12, FontWeight.w600, Colors.white60))),
            Text(
              '$aktif dari $limit Santri ($persen%)',
              style: _t(12, FontWeight.w800, Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: LinearProgressIndicator(
            value: (persen.clamp(0, 100)) / 100,
            minHeight: 7,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(persen >= 90 ? _AC.gold : _AC.mint),
          ),
        ),
        const SizedBox(height: 16),
        _upgradeButton(),
      ],
    );
  }

  Widget _upgradeButton() {
    return Material(
      color: _AC.gold,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onUpgrade,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.rocket_launch_outlined, size: 18, color: _AC.primary),
              const SizedBox(width: 8),
              Text('Ajukan Upgrade Kuota Santri', style: _t(14, FontWeight.w800, _AC.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Notifikasi
// ============================================================================

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.values, required this.onChanged});

  final Map<String, bool> values;
  final void Function(String key, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_none, size: 22, color: _AC.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Notifikasi & Peringatan Admin', style: _t(16, FontWeight.w800, _AC.primary)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih notifikasi otomatis yang ingin Anda terima di aplikasi dan WhatsApp dinas.',
            style: _t(12, FontWeight.w500, _AC.inkSecondary, height: 1.35),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < _notifItems.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _AC.line),
            _NotifRow(
              title: _notifItems[i].title,
              desc: _notifItems[i].desc,
              value: values[_notifItems[i].key] ?? false,
              onChanged: (v) => onChanged(_notifItems[i].key, v),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotifRow extends StatelessWidget {
  const _NotifRow({
    required this.title,
    required this.desc,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String desc;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _t(13, FontWeight.w800, _AC.primary)),
                const SizedBox(height: 2),
                Text(desc, style: _t(11.5, FontWeight.w500, _AC.inkSecondary, height: 1.35)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Toggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ============================================================================
// Panduan & Bantuan
// ============================================================================

class _PanduanItem {
  const _PanduanItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.external = false,
    this.highlight = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool external;
  final bool highlight;
}

class _PanduanCard extends StatelessWidget {
  const _PanduanCard({required this.items});

  final List<_PanduanItem> items;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 21, color: _AC.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Panduan & Bantuan', style: _t(16, FontWeight.w800, _AC.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in items) _PanduanRow(item: item),
        ],
      ),
    );
  }
}

class _PanduanRow extends StatelessWidget {
  const _PanduanRow({required this.item});

  final _PanduanItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.highlight ? _AC.sage : _AC.surfaceDim,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, size: 20, color: _AC.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(13, FontWeight.w800, _AC.primary),
                  ),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(11.5, FontWeight.w500, _AC.inkSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              item.external ? Icons.open_in_new : Icons.chevron_right,
              size: 19,
              color: _AC.inkSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Logout
// ============================================================================

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: _AC.errorBg,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, size: 19, color: _AC.errorText),
                const SizedBox(width: 8),
                Text('Keluar dari Akun Admin', style: _t(14, FontWeight.w800, _AC.errorText)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}