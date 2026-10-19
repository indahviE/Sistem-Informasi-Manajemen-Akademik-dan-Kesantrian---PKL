// pengaturan_mudir_screen.dart  ->  simpan di lib/screens/mudir/
//
// Pengaturan — Pimpinan / Mudir.
//
// Sama seperti Pengaturan Admin & Ustadz: TIDAK punya Scaffold/AppBar sendiri,
// nempel di dalam ShellScreen (MudirHeader + bottom nav dibawa shell).
//
// Isi: profil (edit nama/email), ubah sandi, keluar.
// TIDAK butuh endpoint baru. Memakai yang sudah ada:
//   PATCH /pengaturan/profil, PATCH /pengaturan/ubah-password
// Data awal diambil dari AppScope.of(context).user (tanpa GET tambahan).
//
// Import mengikuti pengaturan_admin_screen.dart (folder sedalam lib/screens/<role>/).

import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../santri/santri_ui.dart';
import '../super_admin/pengaturan_dialogs.dart';

// ============================================================================
// Token warna lokal (private, nilai sama dengan _AC di pengaturan_admin_screen)
// ============================================================================

class _MC {
  static Color get primary => SC.primary;
  static Color get primarySoft => SC.primaryEnd;
  static Color get sage => SC.sage;
  static const gold = Color(0xFFF9D77E);
  static const goldSurface = Color(0xFFFAF5EC);
  static const goldBorder = Color(0xFFE7D2A7);
  static const goldDark = Color(0xFF7A5B10);
  static const background = Color(0xFFFAF9F5);
  static const surface = Colors.white;
  static const surfaceDim = Color(0xFFF5F4EE);
  static const line = Color(0xFFEAE6DC);
  static const inkSecondary = Color(0xFF475569);
  static const errorBg = Color(0xFFFEE2E2);
  static const errorText = Color(0xFF991B1B);
}

TextStyle _t(double size, FontWeight w, Color c, {double? height}) =>
    TextStyle(fontFamily: 'Nunito', fontSize: size, fontWeight: w, color: c, height: height);

// ============================================================================
// Screen
// ============================================================================

class PengaturanMudirScreen extends StatefulWidget {
  const PengaturanMudirScreen({super.key});

  @override
  State<PengaturanMudirScreen> createState() => _PengaturanMudirScreenState();
}

class _PengaturanMudirScreenState extends State<PengaturanMudirScreen> {
  bool _initialized = false;
  String _nama = '';
  String _email = '';
  String _pondok = 'Pondok';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final u = AppScope.of(context).user;
      _nama = (u?.nama ?? '') as String;
      _email = (u?.email ?? '') as String;
      final tn = u?.tenantNama;
      if (tn != null && tn.isNotEmpty) _pondok = tn;
    }
  }

  ApiClient get _api => AppScope.of(context).api;

  // ---------------------------------------------------------------- profil

  Future<void> _editProfil() async {
    final scope = AppScope.of(context);
    final api = _api;

    final saved = await showEditProfilSheet(
      context,
      nama: _nama,
      email: _email,
      onSubmit: (nama, email) async {
        await api.patch(ApiUrl.pengaturanProfil, {'nama': nama, 'email': email});
        await scope.updateProfil(nama: nama, email: email);
        if (mounted) {
          setState(() {
            _nama = nama;
            _email = email;
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

  // ----------------------------------------------------------------- logout

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _MC.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(color: _MC.errorBg, shape: BoxShape.circle),
          child: const Icon(Icons.logout_rounded, size: 24, color: _MC.errorText),
        ),
        title: Text(
          'Keluar dari Akun Mudir?',
          textAlign: TextAlign.center,
          style: _t(17, FontWeight.w800, _MC.primary),
        ),
        content: Text(
          'Kamu perlu login kembali untuk memantau data pondok.',
          textAlign: TextAlign.center,
          style: _t(13, FontWeight.w500, _MC.inkSecondary, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: _t(13, FontWeight.w700, _MC.inkSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AppScope.of(context).logout();
            },
            style: TextButton.styleFrom(foregroundColor: _MC.errorText),
            child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _MC.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              const _Reveal(index: 0, child: _TitleRow()),
              const SizedBox(height: 16),
              _Reveal(
                index: 1,
                child: _ProfileCard(
                  nama: _nama.isEmpty ? '-' : _nama,
                  email: _email.isEmpty ? '-' : _email,
                  onEditProfil: _editProfil,
                  onUbahPassword: _ubahPassword,
                ),
              ),
              const SizedBox(height: 16),
              _Reveal(
                index: 2,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _MC.goldSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _MC.goldBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lock_outline, size: 16, color: _MC.goldDark),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Data santri, kelas, paket langganan, dan pengaturan pondok dikelola oleh admin pondok.',
                          style: _t(11.5, FontWeight.w500, _MC.goldDark, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Reveal(index: 3, child: _LogoutButton(onPressed: _confirmLogout)),
              const SizedBox(height: 18),
              _Reveal(
                index: 4,
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 3,
                        decoration: BoxDecoration(
                          color: _MC.line,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Panel Pimpinan $_pondok',
                        textAlign: TextAlign.center,
                        style: _t(11, FontWeight.w600, _MC.inkSecondary),
                      ),
                    ],
                  ),
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
// Animasi masuk
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _MC.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _MC.line.withOpacity(0.7)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F0F3A2E), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: child,
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
              Text('Pengaturan', style: _t(21, FontWeight.w800, _MC.primary, height: 1.15)),
              const SizedBox(height: 2),
              Text(
                'Akun Pimpinan',
                overflow: TextOverflow.ellipsis,
                style: _t(12, FontWeight.w500, _MC.inkSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: _MC.sage,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: _MC.primary.withOpacity(0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _MC.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: _MC.primary.withOpacity(0.35), blurRadius: 4, spreadRadius: 1),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text('Mudir Aktif', style: _t(11, FontWeight.w800, _MC.primary)),
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
    required this.onEditProfil,
    required this.onUbahPassword,
  });

  final String nama;
  final String email;
  final VoidCallback onEditProfil;
  final VoidCallback onUbahPassword;

  String get _inisial {
    final t = nama.trim();
    return t.isEmpty ? '?' : t.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    colors: [_MC.primary, _MC.primarySoft],
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
                          color: _MC.gold.withOpacity(0.10),
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
                    color: _MC.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: _MC.surface, width: 4),
                    boxShadow: const [
                      BoxShadow(color: Color(0x290F3A2E), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Text(_inisial, style: _t(28, FontWeight.w800, _MC.gold)),
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
                        style: _t(19, FontWeight.w800, _MC.primary, height: 1.2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: _MC.sage,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_balance_outlined, size: 12, color: _MC.primary),
                          const SizedBox(width: 4),
                          Text('Pimpinan / Mudir', style: _t(10.5, FontWeight.w800, _MC.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoTile(icon: Icons.mail_outline_rounded, label: 'Email', text: email),
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
      decoration: BoxDecoration(color: _MC.surfaceDim, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(color: _MC.surface, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: _MC.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _t(10, FontWeight.w700, _MC.inkSecondary)),
                const SizedBox(height: 1),
                Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(12.5, FontWeight.w700, _MC.primary),
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
    final fg = filled ? Colors.white : _MC.primary;
    return Material(
      color: filled ? _MC.primary : _MC.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: filled ? null : Border.all(color: _MC.primary.withOpacity(0.35), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: fg),
              const SizedBox(width: 7),
              Flexible(
                child: Text(label, overflow: TextOverflow.ellipsis, style: _t(13, FontWeight.w800, fg)),
              ),
            ],
          ),
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
        color: _MC.errorBg.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Container(
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _MC.errorText.withOpacity(0.25), width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout_rounded, size: 19, color: _MC.errorText),
                const SizedBox(width: 8),
                Text('Keluar dari Akun Mudir', style: _t(14, FontWeight.w800, _MC.errorText)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}