// musyrif_header.dart
//
// Header (bar atas) untuk Musyrif, disamakan dengan header Wali & Admin:
//   SIMEdu [MUSYRIF]                             (lonceng)  (avatar)
//   (ikon) Panel Musyrif • Beranda
//
// Klik avatar -> membuka kartu profil bertema branding pondok (logo, nama, warna)
// dengan tombol Keluar (+ Pengaturan kalau onPengaturan diisi).
//
// Taruh di lib/screens/musyrif/musyrif_header.dart

import 'package:flutter/material.dart';
import '../santri/santri_ui.dart' show SC;
import '../../services/app_scope.dart';
import '../super_admin/tenants_screen.dart' show PColors;
import '../ui_utils.dart';

class MusyrifHeader extends StatelessWidget implements PreferredSizeWidget {
  const MusyrifHeader({
    super.key,
    required this.subtitle,
    required this.nama,
    required this.email,
    required this.onNotifikasi,
    required this.onLogout,
    this.onPengaturan,
    this.roleLabel = 'MUSYRIF',
    this.hasUnread = false,
  });

  /// Nama produk global (bukan nama pondok/sekolah tenant).
  static const String brandName = 'SIMEdu';

  /// Baris kedua (nama menu aktif, mis. "Beranda").
  final String subtitle;

  final String nama;
  final String email;

  final VoidCallback onNotifikasi;
  final VoidCallback onLogout;

  /// Opsional. Kalau null, tombol Pengaturan di kartu profil disembunyikan.
  final VoidCallback? onPengaturan;

  /// Label pill di sebelah nama brand.
  final String roleLabel;

  /// Titik merah di lonceng.
  final bool hasUnread;

  static const double _maxWidth = 480;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PColors.surface,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 10, 0),
              child: Row(
                children: [
                  Expanded(child: _buildBrand()),
                  _buildBell(),
                  const SizedBox(width: 2),
                  _buildAvatarButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Kiri: brand + pill role + menu aktif
  // -------------------------------------------------------------------

  Widget _buildBrand() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Flexible(
              child: Text(
                brandName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: PColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: SC.primary,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                roleLabel,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            const Icon(Icons.supervisor_account_outlined, size: 13, color: PColors.inkSecondary),
            const SizedBox(width: 4),
            const Text(
              'Panel Musyrif',
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: PColors.inkSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: SC.primary, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SC.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // Kanan: lonceng + avatar
  // -------------------------------------------------------------------

  Widget _buildBell() {
    return IconButton(
      tooltip: 'Notifikasi',
      onPressed: onNotifikasi,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none_rounded, size: 26, color: PColors.ink),
          if (hasUnread)
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  shape: BoxShape.circle,
                  border: Border.all(color: PColors.surface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarButton(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => _showProfileSheet(context),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: _InitialAvatar(nama: nama, size: 40),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Kartu profil (dibuka dari avatar)
  // -------------------------------------------------------------------

  void _showProfileSheet(BuildContext context) {
    final scope = AppScope.of(context);
    final logo = scope.brandingLogo;
    final tn = scope.user?.tenantNama;
    final pondok = (tn != null && tn.isNotEmpty) ? tn : brandName;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PColors.surface,
      constraints: const BoxConstraints(maxWidth: _maxWidth),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: PColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Banner branding pondok
              Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [SC.primary, SC.primaryEnd],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -24,
                      top: -28,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 30,
                      bottom: -34,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: (logo != null && logo.isNotEmpty)
                                ? brandLogo(logo, width: 54, height: 54, radius: 16)
                                : Icon(Icons.mosque, size: 28, color: SC.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pondok,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: const Text(
                                    'Musyrif / Pembina Asrama',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Info akun
              Row(
                children: [
                  _InitialAvatar(nama: nama, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: PColors.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.mail_outline, size: 14, color: PColors.inkSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 12,
                                  color: PColors.inkSecondary,
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

              const SizedBox(height: 18),
              Row(
                children: [
                  if (onPengaturan != null) ...[
                    Expanded(
                      child: _SheetButton(
                        icon: Icons.tune,
                        label: 'Pengaturan',
                        background: SC.mint,
                        foreground: SC.primary,
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          onPengaturan!();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: _SheetButton(
                      icon: Icons.logout,
                      label: 'Keluar',
                      background: PColors.errorBg,
                      foreground: PColors.errorText,
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        onLogout();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Avatar inisial (warna ikut branding pondok)
// ============================================================================

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.nama, required this.size});

  final String nama;
  final double size;

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SC.primary, SC.primaryEnd],
        ),
      ),
      child: Text(
        _initials(nama),
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 46,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}