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
import '../santri/santri_ui.dart';
import '../super_admin/pengaturan_dialogs.dart';

// ============================================================================
// Token warna lokal (emerald + emas). Private supaya tidak bentrok dengan
// PColors/PText milik Super Admin. Kalau dashboard admin sudah punya file
// token sendiri, ganti _AC.* dengan token itu.
// ============================================================================

class _AC {
  // Nilai disamakan dengan _WC di dashboard_screen.dart.
  static Color get primary => SC.primary;
  static Color get primarySoft => SC.primaryEnd;
  static Color get mint => SC.mint;
  static const gold = Color(0xFFF9D77E); // emas terang khusus tombol upgrade (sesuai screen.png)
  static const goldDark = Color(0xFF7A5B10);
  static const background = Color(0xFFFAF9F5);
  static const surface = Colors.white;
  static const surfaceDim = Color(0xFFF5F4EE);
  static const line = Color(0xFFEAE6DC);
  static const inkSecondary = Color(0xFF475569);
  static Color get sage => SC.sage;
  static const errorBg = Color(0xFFFEE2E2);
  static const errorText = Color(0xFF991B1B);
}

TextStyle _t(double size, FontWeight w, Color c, {double? height}) =>
    TextStyle(fontFamily: 'Nunito', fontSize: size, fontWeight: w, color: c, height: height);

// Nomor WhatsApp bantuan teknis (format internasional tanpa +, mis. 6281234567890).
// Kosong = tombol menampilkan info "belum diatur".
const String _kNomorBantuan = '628996733553';

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

// Ikon visual per toggle (hanya tampilan).
IconData _notifIcon(String key) {
  switch (key) {
    case 'perizinanBaru':
      return Icons.exit_to_app_rounded;
    case 'pelanggaranBaru':
      return Icons.gavel_rounded;
    case 'waliBelumAktivasi':
      return Icons.how_to_reg_outlined;
    case 'eskalasiDarurat':
      return Icons.priority_high_rounded;
    case 'rekapAbsensiShalat':
      return Icons.fact_check_outlined;
    default:
      return Icons.notifications_none;
  }
}

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(color: _AC.errorBg, shape: BoxShape.circle),
          child: const Icon(Icons.logout_rounded, size: 24, color: _AC.errorText),
        ),
        title: Text(
          'Keluar dari Akun Admin?',
          textAlign: TextAlign.center,
          style: _t(17, FontWeight.w800, _AC.primary),
        ),
        content: Text(
          'Kamu perlu login kembali untuk mengakses pengaturan dan data pondok.',
          textAlign: TextAlign.center,
          style: _t(13, FontWeight.w500, _AC.inkSecondary, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
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
      return Center(child: CircularProgressIndicator(color: _AC.primary));
    }
    if (_error != null) {
      return _LoadErrorState(message: _error!, onRetry: _load);
    }

    final namaPondok = (_tenant['namaPondok'] ?? 'Pondok') as String;

    return RefreshIndicator(
      color: _AC.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const _Reveal(index: 0, child: _TitleRow()),
          const SizedBox(height: 16),
          _Reveal(
            index: 1,
            child: _ProfileCard(
              nama: (_profil['nama'] ?? '-') as String,
              email: (_profil['email'] ?? '-') as String,
              noHp: _profil['noHp'] as String?,
              role: (_profil['role'] ?? '') as String,
              onEditProfil: _editProfil,
              onUbahPassword: _ubahPassword,
            ),
          ),
          const SizedBox(height: 16),
          _Reveal(
            index: 2,
            child: _PaketCard(
              paket: _paket,
              onUpgrade: () => _showInfo('Pengajuan upgrade kuota segera hadir.'),
            ),
          ),
          const SizedBox(height: 16),
          _Reveal(index: 3, child: _NotifCard(values: _notif, onChanged: _toggleNotif)),
          const SizedBox(height: 16),
          _Reveal(
            index: 4,
            child: _PanduanCard(
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
          ),
          const SizedBox(height: 16),
          _Reveal(index: 5, child: _LogoutButton(onPressed: _confirmLogout)),
          const SizedBox(height: 18),
          _Reveal(
            index: 6,
            child: Center(
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 3,
                    decoration: BoxDecoration(
                      color: _AC.line,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sistem Administrasi $namaPondok',
                    textAlign: TextAlign.center,
                    style: _t(11, FontWeight.w600, _AC.inkSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Animasi masuk (fade + slide halus, berurutan)
// ============================================================================

class _Reveal extends StatelessWidget {
  const _Reveal({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 16), child: c),
      ),
      child: child,
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
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: _AC.errorBg, shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off_rounded, color: _AC.errorText, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: _t(13, FontWeight.w500, _AC.inkSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              style: FilledButton.styleFrom(
                backgroundColor: _AC.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              label: const Text('Coba Lagi'),
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
  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _AC.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _AC.line.withOpacity(0.7)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F0F3A2E), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

/// Header section seragam: ikon dalam kotak tint + judul + subjudul opsional.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title, this.subtitle, this.trailing});

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _AC.sage,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: _AC.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _t(15.5, FontWeight.w800, _AC.primary, height: 1.2)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: _t(11.5, FontWeight.w500, _AC.inkSecondary, height: 1.3)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
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
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 50,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? _AC.primary : const Color(0xFFDAD8CF),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1))],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: value
                  ? Icon(Icons.check_rounded, key: const ValueKey('on'), size: 15, color: _AC.primary)
                  : const SizedBox.shrink(key: ValueKey('off')),
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pengaturan', style: _t(21, FontWeight.w800, _AC.primary, height: 1.15)),
              const SizedBox(height: 2),
              Text(
                'Akun & Preferensi Admin',
                overflow: TextOverflow.ellipsis,
                style: _t(12, FontWeight.w500, _AC.inkSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: _AC.sage,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: _AC.primary.withOpacity(0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _AC.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: _AC.primary.withOpacity(0.35), blurRadius: 4, spreadRadius: 1),
                  ],
                ),
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
    final punyaHp = noHp != null && noHp!.trim().isNotEmpty;

    return _SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner gradient + avatar yang menimpa tepi bawah banner.
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 84,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_AC.primary, _AC.primarySoft],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -50,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.10), width: 1.5),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 24,
                      bottom: -30,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _AC.gold.withOpacity(0.10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 18,
                bottom: -34,
                child: Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _AC.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: _AC.surface, width: 4),
                    boxShadow: const [
                      BoxShadow(color: Color(0x290F3A2E), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Text(_inisial, style: _t(28, FontWeight.w800, _AC.gold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 42),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(19, FontWeight.w800, _AC.primary, height: 1.2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: _AC.sage,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_outlined, size: 12, color: _AC.primary),
                          const SizedBox(width: 4),
                          Text(_roleLabel, style: _t(10.5, FontWeight.w800, _AC.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoTile(icon: Icons.mail_outline_rounded, label: 'Email', text: email),
                if (punyaHp) ...[
                  const SizedBox(height: 8),
                  _InfoTile(icon: Icons.phone_outlined, label: 'No. HP', text: noHp!),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Edit Profil',
                        filled: true,
                        onPressed: onEditProfil,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.key_outlined,
                        label: 'Ubah Sandi',
                        filled: false,
                        onPressed: onUbahPassword,
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
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.text});

  final IconData icon;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _AC.surfaceDim,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(color: _AC.surface, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: _AC.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _t(10, FontWeight.w700, _AC.inkSecondary)),
                const SizedBox(height: 1),
                Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(12.5, FontWeight.w700, _AC.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : _AC.primary;
    return Material(
      color: filled ? _AC.primary : _AC.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: filled ? null : Border.all(color: _AC.primary.withOpacity(0.35), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: fg),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: _t(13, FontWeight.w800, fg),
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

  int _int(dynamic v) => v is num ? v.toInt() : 0;

  @override
  Widget build(BuildContext context) {
    final p = paket;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_AC.primary, _AC.primarySoft],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: _AC.primary.withOpacity(0.28), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Dekorasi lingkaran halus di pojok kartu.
          Positioned(right: -40, top: -40, child: _ring(160)),
          Positioned(right: 10, top: 10, child: _ring(80)),
          Positioned(
            left: -36,
            bottom: -46,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _AC.gold.withOpacity(0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: p == null ? _kosong() : _isi(p),
          ),
        ],
      ),
    );
  }

  Widget _ring(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
      ),
    );
  }

  Widget _kosong() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                shape: BoxShape.circle,
                border: Border.all(color: _AC.gold.withOpacity(0.55)),
              ),
              child: const Icon(Icons.workspace_premium_outlined, size: 22, color: _AC.gold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Paket Langganan', style: _t(18, FontWeight.w800, Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Belum ada paket aktif untuk pondok ini. Ajukan paket untuk mulai memakai seluruh modul.',
          style: _t(12, FontWeight.w500, Colors.white70, height: 1.45),
        ),
        const SizedBox(height: 18),
        _upgradeButton(),
      ],
    );
  }

  Widget _isi(Map<String, dynamic> p) {
    final periode = ((p['periode'] ?? '') as String).toUpperCase();
    final akhir = _tgl(p['tanggalAkhir']);
    final sisaHari = p['sisaHari'] is num ? (p['sisaHari'] as num).toInt() : null;
    final hampirHabis = sisaHari != null && sisaHari <= 30;

    final aktif = _int(p['santriAktif']);
    final limit = _int(p['limitSantri']);
    final persen = _int(p['persenSantri']).clamp(0, 100);
    final sisaKuota = (limit - aktif).clamp(0, limit > 0 ? limit : 0);
    final hampirPenuh = limit > 0 && persen >= 90;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baris atas: label periode + lencana paket
        Row(
          children: [
            if (periode.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                decoration: BoxDecoration(
                  color: _AC.gold,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(periode, style: _t(10, FontWeight.w800, _AC.primary)),
              ),
            const Spacer(),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                shape: BoxShape.circle,
                border: Border.all(color: _AC.gold.withOpacity(0.55)),
              ),
              child: const Icon(Icons.workspace_premium_outlined, size: 23, color: _AC.gold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          (p['nama'] ?? 'Paket') as String,
          style: _t(24, FontWeight.w800, Colors.white, height: 1.15),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (akhir != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_available_outlined, size: 14, color: Colors.white60),
                  const SizedBox(width: 5),
                  Text('Aktif s.d. $akhir', style: _t(12, FontWeight.w600, Colors.white70)),
                ],
              ),
            if (sisaHari != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: hampirHabis ? _AC.gold : Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'Sisa $sisaHari Hari',
                  style: _t(10.5, FontWeight.w800, hampirHabis ? _AC.primary : _AC.mint),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        // Panel kuota santri
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.groups_outlined, size: 17, color: Colors.white70),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text('Kuota Santri Aktif', style: _t(12, FontWeight.w700, Colors.white70)),
                  ),
                  if (limit > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: hampirPenuh ? _AC.gold : _AC.mint,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text('$persen%', style: _t(11, FontWeight.w800, _AC.primary)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$aktif', style: _t(34, FontWeight.w800, Colors.white, height: 1)),
                  const SizedBox(width: 6),
                  Text(
                    limit > 0 ? '/ $limit santri' : 'santri aktif',
                    style: _t(13, FontWeight.w600, Colors.white60),
                  ),
                ],
              ),
              if (limit > 0) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: LinearProgressIndicator(
                    value: persen / 100,
                    minHeight: 10,
                    backgroundColor: Colors.white.withOpacity(0.14),
                    valueColor: AlwaysStoppedAnimation<Color>(hampirPenuh ? _AC.gold : _AC.mint),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      hampirPenuh ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      size: 14,
                      color: hampirPenuh ? _AC.gold : Colors.white60,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        hampirPenuh
                            ? 'Kuota hampir penuh, pertimbangkan upgrade.'
                            : 'Masih tersedia $sisaKuota slot santri.',
                        style: _t(11.5, FontWeight.w600, hampirPenuh ? _AC.gold : Colors.white60),
                      ),
                    ),
                  ],
                ),
              ],
            ],
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onUpgrade,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.rocket_launch_outlined, size: 19, color: _AC.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Ajukan Upgrade Kuota Santri', style: _t(14, FontWeight.w800, _AC.primary)),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _AC.primary.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_rounded, size: 17, color: _AC.primary),
              ),
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
    final aktifCount = _notifItems.where((n) => values[n.key] ?? false).length;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.notifications_none_rounded,
            title: 'Notifikasi & Peringatan Admin',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: _AC.surfaceDim,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: _AC.line),
              ),
              child: Text(
                '$aktifCount/${_notifItems.length}',
                style: _t(11, FontWeight.w800, _AC.primary),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pilih notifikasi otomatis yang ingin Anda terima di aplikasi dan WhatsApp dinas.',
            style: _t(12, FontWeight.w500, _AC.inkSecondary, height: 1.4),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _notifItems.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _AC.line),
            _NotifRow(
              icon: _notifIcon(_notifItems[i].key),
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
    required this.icon,
    required this.title,
    required this.desc,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String desc;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: value ? _AC.sage : _AC.surfaceDim,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 19,
              color: value ? _AC.primary : _AC.inkSecondary.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _t(13, FontWeight.w800, _AC.primary, height: 1.25)),
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
          const _SectionHeader(
            icon: Icons.help_outline_rounded,
            title: 'Panduan & Bantuan',
            subtitle: 'Dokumen resmi dan dukungan teknis',
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: _AC.line, indent: 52),
            _PanduanRow(item: items[i]),
          ],
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
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.highlight ? _AC.primary : _AC.surfaceDim,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.icon,
                size: 20,
                color: item.highlight ? _AC.gold : _AC.primary,
              ),
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
                  const SizedBox(height: 1),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(11.5, FontWeight.w500, _AC.inkSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: item.highlight ? _AC.sage : _AC.surfaceDim,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.external ? Icons.open_in_new_rounded : Icons.chevron_right_rounded,
                size: 17,
                color: item.highlight ? _AC.primary : _AC.inkSecondary,
              ),
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
        color: _AC.errorBg.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Container(
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _AC.errorText.withOpacity(0.25), width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout_rounded, size: 19, color: _AC.errorText),
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