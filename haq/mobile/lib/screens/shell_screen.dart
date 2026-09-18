import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';
import 'ui_utils.dart';
import 'notifikasi/notifikasi_screen.dart';
import 'dashboard_screen.dart';
import 'santri/santri_list_screen.dart';
import 'master/kelas_list_screen.dart';
import 'master/ustadz_list_screen.dart';
import 'master/mapel_list_screen.dart';
import 'akademik/absensi_screen.dart';
import 'akademik/nilai_screen.dart';
import 'akademik/tahfidz_screen.dart';
import 'akademik/ujian_screen.dart';
import 'akademik/rapor_screen.dart';
import 'akademik/kelulusan_screen.dart';
import 'kesantrian/pelanggaran_screen.dart';
import 'kesantrian/perizinan_screen.dart';
import 'kesantrian/kesehatan_screen.dart';
import 'kesantrian/kunjungan_screen.dart';
import 'kesantrian/konseling_screen.dart';
import 'kesantrian/pembinaan_karakter_screen.dart';
import 'kesantrian/pembinaan_ibadah_screen.dart';
import 'kesantrian/keadaan_darurat_screen.dart';
import 'users/users_screen.dart';
import 'super_admin/tenants_screen.dart';
import 'wali/wali_screen.dart';
import 'ppdb/ppdb_list_screen.dart';
import 'kurikulum/kurikulum_screen.dart';
import 'kesantrian/rekam_medis_screen.dart';
import 'billing/billing_admin_screen.dart';
import 'billing/billing_tenant_screen.dart';
import 'branding/branding_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _MenuItem {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
  _MenuItem(this.label, this.icon, this.builder);
}

class _ShellScreenState extends State<ShellScreen> {
  static const _pinned = ['Dashboard', 'Santri', 'Absensi', 'Kurikulum'];

  int _navIndex = 0;
  late List<_MenuItem> _navItems;
  late List<_MenuItem> _moreItems;
  _MenuItem? _activeExtra;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = AppScope.of(context).user!;
    final all = _buildMenu(user);
    final chosen = <_MenuItem>[];
    for (final label in _pinned) {
      final i = all.indexWhere((e) => e.label == label);
      if (i >= 0) chosen.add(all[i]);
    }
    for (final e in all) {
      if (chosen.length >= 4) break;
      if (!chosen.contains(e)) chosen.add(e);
    }
    _navItems = chosen;
    _moreItems = all.where((e) => !chosen.contains(e)).toList();
    if (_navIndex >= _navItems.length) _navIndex = 0;
    _activeExtra = null;
  }

  List<_MenuItem> _buildMenu(UserData user) {
    final m = <_MenuItem>[];
    m.add(_MenuItem('Dashboard', Icons.dashboard, (_) => const DashboardScreen()));

    if (user.isSuperAdmin) {
      m.add(_MenuItem('Kelola Tenant', Icons.apartment, (_) => const TenantsScreen()));
      m.add(_MenuItem('Billing & Paket', Icons.payments, (_) => const BillingAdminScreen()));
      return m;
    }

    if (!user.isWali) {
      m.add(_MenuItem('Santri', Icons.groups, (_) => const SantriListScreen()));
    }

    if (user.isAdmin || user.isPimpinan) {
      m.add(_MenuItem('PPDB Online', Icons.app_registration, (_) => const PpdbListScreen()));
      m.add(_MenuItem('Kelas', Icons.class_, (_) => const KelasListScreen()));
      m.add(_MenuItem('Ustadz / Pembina', Icons.person_search, (_) => const UstadzListScreen()));
      m.add(_MenuItem('Mata Pelajaran', Icons.menu_book, (_) => const MapelListScreen()));
      m.add(_MenuItem('Kurikulum', Icons.folder_copy, (_) => const KurikulumScreen()));
      m.add(_MenuItem('Identitas Pondok', Icons.palette, (_) => const BrandingScreen()));
      m.add(_MenuItem('& Tagihan', Icons.receipt_long, (_) => const BillingTenantScreen()));
    }

    if (user.isAdmin || user.isUstadz || user.isMusyrif) {
      m.add(_MenuItem('Absensi', Icons.checklist, (_) => const AbsensiScreen()));
    }
    if (user.isAdmin || user.isUstadz || user.isPimpinan) {
      m.add(_MenuItem('Nilai', Icons.grade, (_) => const NilaiScreen()));
      m.add(_MenuItem('Tahfidz', Icons.auto_stories, (_) => const TahfidzScreen()));
      m.add(_MenuItem('Ujian & Remedial', Icons.fact_check, (_) => const UjianScreen()));
      m.add(_MenuItem('Rapor Digital', Icons.description, (_) => const RaporScreen()));
      m.add(_MenuItem('Kelulusan & Wisuda', Icons.military_tech, (_) => const KelulusanScreen()));
    }

    if (user.isAdmin || user.isMusyrif || user.isUstadz || user.isPimpinan) {
      m.add(_MenuItem('Konseling', Icons.support_agent, (_) => const KonselingScreen()));
    }

    if (user.isAdmin || user.isMusyrif || user.isUstadz || user.isPimpinan) {
      m.add(_MenuItem('Pembinaan Karakter', Icons.emoji_events, (_) => const PembinaanKarakterScreen()));
    }

    if (user.isAdmin || user.isMusyrif || user.isPimpinan) {
      m.add(_MenuItem('Pembinaan Ibadah', Icons.mosque, (_) => const PembinaanIbadahScreen()));
    }

    if (user.isAdmin || user.isMusyrif || user.isUstadz || user.isPimpinan) {
      m.add(_MenuItem('Keadaan Darurat', Icons.emergency, (_) => const KeadaanDaruratScreen()));
    }

    if (user.isAdmin || user.isMusyrif) {
      m.add(_MenuItem('Pelanggaran', Icons.gavel, (_) => const PelanggaranScreen()));
      m.add(_MenuItem('Perizinan', Icons.exit_to_app, (_) => const PerizinanScreen()));
      m.add(_MenuItem('Kesehatan', Icons.medical_services, (_) => const KesehatanScreen()));
      m.add(_MenuItem('Rekam Medis', Icons.health_and_safety, (_) => const RekamMedisScreen()));
      m.add(_MenuItem('Kunjungan Wali', Icons.people, (_) => const KunjunganScreen()));
    }

    if (user.isAdmin) {
      m.add(_MenuItem('Kelola User', Icons.admin_panel_settings, (_) => const UsersScreen()));
    }

    if (user.isWali) {
      m.add(_MenuItem('Anak Saya', Icons.family_restroom, (_) => const WaliScreen()));
      m.add(_MenuItem('Pelanggaran', Icons.gavel, (_) => const PelanggaranScreen()));
      m.add(_MenuItem('Perizinan', Icons.exit_to_app, (_) => const PerizinanScreen()));
      m.add(_MenuItem('Pembinaan Karakter', Icons.emoji_events, (_) => const PembinaanKarakterScreen()));
      m.add(_MenuItem('Pembinaan Ibadah', Icons.mosque, (_) => const PembinaanIbadahScreen()));

    }

    return m;
  }

  void _logout() async {
    await AppScope.of(context).logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).user!;
    final active = _activeExtra ?? _navItems[_navIndex];
    final title = active.label;
    final hasMore = _moreItems.isNotEmpty;
    final selectedIndex = _activeExtra != null ? _navItems.length : _navIndex;
    return Scaffold(
      appBar: AppBar(
        title: _appBarTitle(user, title),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotifikasiScreen())),
            tooltip: 'Notifikasi',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: _seed,
              child: Text(_initials(user.nama),
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') _logout();
            },
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout),
                  title: Text('Keluar (${user.nama})'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: active.builder(context),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) {
          if (i < _navItems.length) {
            setState(() {
              _navIndex = i;
              _activeExtra = null;
            });
          } else {
            _showMoreSheet();
          }
        },
        destinations: [
          for (final m in _navItems)
            NavigationDestination(
              icon: Icon(m.icon),
              selectedIcon: Icon(m.icon, color: _seed),
              label: m.label,
            ),
          if (hasMore)
            const NavigationDestination(
              icon: Icon(Icons.more_horiz),
              selectedIcon: Icon(Icons.apps),
              label: 'Lainnya',
            ),
        ],
      ),
    );
  }

  void _showMoreSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Tw.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Menu Lainnya',
                  style: const TextStyle(color: Tw.gray900, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: _moreItems.length,
                  itemBuilder: (_, i) => _moreItem(i),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _moreItem(int i) {
    final m = _moreItems[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.pop(context);
            setState(() {
              _activeExtra = m;
              _navIndex = _navItems.length;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: _activeExtra == m ? Tw.primarySoft : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(m.icon, size: 20, color: _activeExtra == m ? _seed : Tw.gray600),
                const SizedBox(width: 12),
                Text(
                  m.label,
                  style: TextStyle(
                    color: _activeExtra == m ? _seed : Tw.gray800,
                    fontWeight: _activeExtra == m ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color get _seed => AppScope.of(context).brandingColor ?? Tw.primary;

  Widget _appBarTitle(UserData user, String title) {
    final logo = AppScope.of(context).brandingLogo;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Tw.primarySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: logo != null && logo.isNotEmpty
              ? brandLogo(logo, width: 30, height: 30, radius: 8)
              : Icon(_navItems[_navIndex <= _navItems.length - 1 ? _navIndex : 0].icon,
                  size: 18, color: _seed),
        ),
        const SizedBox(width: 10),
        Flexible(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}