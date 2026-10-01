// ustadz_header.dart
//
// Header (bar atas) untuk Ustadz/Guru, disamakan dengan AdminHeader:
//   SIMEdu [USTADZ]                                        (avatar)
//   (ikon) Panel Ustadz / Guru • Beranda
//
// Klik avatar -> membuka kartu profil dengan tombol Keluar.
// Lonceng notifikasi sengaja belum ada (belum ada pemicu notifikasi untuk
// ustadz di backend/PRD). Kalau nanti dibutuhkan, tambahkan lagi parameter
// onNotifikasi + hasUnread seperti di AdminHeader.

import 'package:flutter/material.dart';
import '../../super_admin/tenants_screen.dart' show PColors;

class UstadzHeader extends StatelessWidget implements PreferredSizeWidget {
  const UstadzHeader({
    super.key,
    required this.subtitle,
    required this.nama,
    required this.email,
    required this.onLogout,
    this.roleLabel = 'USTADZ',
  });

  /// Sama dengan AdminHeader.brandName supaya nama produknya konsisten.
  static const String brandName = 'SIMEdu';

  /// Baris kedua (nama menu aktif, mis. "Beranda").
  final String subtitle;

  final String nama;
  final String email;

  final VoidCallback onLogout;

  /// Label pill di sebelah nama produk.
  final String roleLabel;

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
  // Kiri: nama produk + pill role + menu aktif
  // -------------------------------------------------------------------

  Widget _buildBrand() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                brandName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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
                color: PColors.primary,
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
            const Icon(Icons.school_outlined, size: 13, color: PColors.inkSecondary),
            const SizedBox(width: 4),
            const Text(
              'Panel Ustadz / Guru',
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
              decoration: const BoxDecoration(color: PColors.primary, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: PColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // Kanan: avatar
  // -------------------------------------------------------------------

  Widget _buildAvatarButton(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => _showProfileSheet(context),
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: _ProfileAvatar(size: 40, badge: 10),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Kartu profil (dibuka dari avatar)
  // -------------------------------------------------------------------

  void _showProfileSheet(BuildContext context) {
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
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ProfileAvatar(size: 64, badge: 12),
                  const SizedBox(width: 14),
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
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: PColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: PColors.primary,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: const Text(
                            'Ustadz / Guru',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
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
              _SheetButton(
                icon: Icons.logout,
                label: 'Keluar',
                background: PColors.errorBg,
                foreground: PColors.errorText,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  onLogout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Avatar (gaya sama dengan AdminHeader)
// ============================================================================

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.size, required this.badge});

  final double size;
  final double badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(color: PColors.sage, shape: BoxShape.circle),
            child: Icon(Icons.person, color: PColors.primary, size: size * 0.5),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: PColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: PColors.surface, width: 1.5),
              ),
              child: Icon(Icons.verified_user, size: badge, color: Colors.white),
            ),
          ),
        ],
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
          width: double.infinity,
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