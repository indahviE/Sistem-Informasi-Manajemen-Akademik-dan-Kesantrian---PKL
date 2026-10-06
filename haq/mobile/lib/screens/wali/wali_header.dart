import 'package:flutter/material.dart';
import '../../services/app_scope.dart';
import '../santri/santri_ui.dart' show SC;
import '../ui_utils.dart';

/// Header khusus Wali Santri: logo + nama pondok, lonceng notifikasi,
/// dan avatar dengan menu keluar. Warna ikut identitas pondok (SC).
class WaliHeader extends StatelessWidget implements PreferredSizeWidget {
  final String subtitle;
  final String nama;
  final String email;
  final bool hasUnread;
  final VoidCallback onNotifikasi;
  final VoidCallback onLogout;

  const WaliHeader({
    super.key,
    required this.subtitle,
    required this.nama,
    required this.email,
    required this.onNotifikasi,
    required this.onLogout,
    this.hasUnread = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final logo = scope.brandingLogo;
    final tn = scope.user?.tenantNama;
    final judul = (tn != null && tn.isNotEmpty) ? tn : 'SIMEdu';

    return Material(
      color: Colors.white,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEAE6DC))),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SizedBox(
                height: 64,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: SC.mint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: (logo != null && logo.isNotEmpty)
                            ? brandLogo(logo, width: 40, height: 40, radius: 10)
                            : Icon(Icons.mosque, size: 22, color: SC.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(judul,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                            Text(subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Notifikasi',
                        onPressed: onNotifikasi,
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(Icons.notifications_outlined, color: SC.primary),
                            if (hasUnread)
                              Positioned(
                                right: -1,
                                top: -1,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC5A059),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Akun',
                        offset: const Offset(0, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        onSelected: (v) {
                          if (v == 'logout') onLogout();
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem<String>(
                            enabled: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nama,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A))),
                                Text(email,
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, size: 18, color: Color(0xFF991B1B)),
                                SizedBox(width: 10),
                                Text('Keluar', style: TextStyle(color: Color(0xFF991B1B))),
                              ],
                            ),
                          ),
                        ],
                        child: CircleAvatar(
                          radius: 17,
                          backgroundColor: SC.primary,
                          child: Text(_initials(nama),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}