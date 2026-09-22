// super_admin_header.dart
//
// Header (bar atas) khusus Super Admin, sesuai desain:
//   SIMPesantren [ROOT]                         (lonceng)  (avatar)
//   ap-southeast-1 (Jakarta DC) • Semua Node Sehat
//
// Avatar memakai gaya yang sama dengan kartu profil di Pengaturan
// (lingkaran hijau muda + ikon orang + lencana verified).
// Klik avatar -> membuka kartu profil dengan tombol Pengaturan & Keluar.
//
// Taruh di folder yang sama dengan pengaturan_screen.dart.

import 'package:flutter/material.dart';
import 'tenants_screen.dart' show PColors;

class SuperAdminHeader extends StatelessWidget implements PreferredSizeWidget {
  const SuperAdminHeader({
    super.key,
    required this.nama,
    required this.email,
    required this.onNotifikasi,
    required this.onPengaturan,
    required this.onLogout,
    this.hasUnread = true,
  });

  final String nama;
  final String email;
  final VoidCallback onNotifikasi;
  final VoidCallback onPengaturan;
  final VoidCallback onLogout;

  /// Titik merah di lonceng. Sementara selalu aktif sesuai desain;
  /// nanti bisa disambungkan ke jumlah notifikasi yang belum dibaca.
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
  // Kiri: nama aplikasi + status cluster
  // -------------------------------------------------------------------

  Widget _buildBrand() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'SIMPesantren',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: PColors.ink,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: PColors.primary,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: const Text(
                'ROOT',
                style: TextStyle(
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
            const Icon(Icons.cloud_done_outlined, size: 13, color: PColors.inkSecondary),
            const SizedBox(width: 4),
            const Flexible(
              child: Text(
                'ap-southeast-1 (Jakarta DC)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: PColors.inkSecondary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: PColors.primary, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            const Text(
              'Semua Node Sehat',
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: PColors.primary,
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
                  _ProfileAvatar(size: 64, badge: 12),
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
                            'ROOT Super Admin',
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
              Row(
                children: [
                  Expanded(
                    child: _SheetButton(
                      icon: Icons.tune,
                      label: 'Pengaturan',
                      background: PColors.surfaceDim,
                      foreground: PColors.primary,
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        onPengaturan();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
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
// Avatar (gaya sama dengan kartu profil di Pengaturan)
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