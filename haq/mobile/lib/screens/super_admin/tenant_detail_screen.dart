// tenant_detail_screen.dart
//
// Detail Tenant — Platform Control Panel (Super Admin)
//
// VERSI 4 — fix: background header & bottom bar sekarang full width,
// konten di dalamnya tetap di-center & di-constrain (maxWidth: 480).
// Pattern: tiap section yang punya warna sendiri (Container dengan
// decoration) dibuat width: double.infinity, lalu isinya dibungkus
// Center > ConstrainedBox(480). Body (scroll area) juga sama, ConstrainedBox
// dipindah ke dalam SingleChildScrollView, bukan membungkus semuanya.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'tenants_screen.dart' show PColors, PText;

const Map<String, IconData> kLogoIconOptions = {
  'mosque': Icons.mosque,
  'school': Icons.school,
  'book': Icons.auto_stories,
  'library': Icons.local_library,
  'award': Icons.emoji_events,
  'institution': Icons.account_balance,
};

IconData resolveLogoIcon(String? key) =>
    kLogoIconOptions[key] ?? Icons.mosque;

const List<String> kThemePresetColors = [
  '#0F3A2E', '#114232', '#1B4D3E', '#0F172A',
  '#7C2D12', '#991B1B', '#B45309', '#C5A059',
  '#0369A1', '#1B5E20', '#4C1D95', '#FAF9F5',
];

class TenantDetailScreen extends StatefulWidget {
  const TenantDetailScreen({
    super.key,
    required this.tenant,
    this.onApprove,
    this.onSuspend,
    this.onRestore,
    this.onArchive,
    this.onUnarchive,
    this.onDelete,
  });

  final Map<String, dynamic> tenant;
  final VoidCallback? onApprove;
  final VoidCallback? onSuspend;
  final VoidCallback? onRestore;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;
  final VoidCallback? onDelete;

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

enum _Tab { informasi, pengguna, langganan }

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  _Tab _tab = _Tab.informasi;

  Map<String, dynamic> get t => widget.tenant;

  String _s(dynamic v, [String fallback = '-']) =>
      v == null || v.toString().trim().isEmpty ? fallback : v.toString();

  Color _hexColor(dynamic v, Color fallback) {
    final raw = v?.toString().trim();
    if (raw == null || raw.isEmpty) return fallback;
    var hex = raw.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final value = int.tryParse(hex, radix: 16);
    return value == null ? fallback : Color(value);
  }


  String _status() => _s(t['status'], 'AKTIF').toUpperCase();

  Future<void> _hubungiPIC(BuildContext context) async {
    final raw = _s(t['adminPhone'], '');
    if (raw.isEmpty || raw == '-') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor PIC belum tersedia untuk tenant ini')),
      );
      return;
    }

    var nomor = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (nomor.startsWith('+')) {
      nomor = nomor.substring(1);
    } else if (nomor.startsWith('0')) {
      nomor = '62${nomor.substring(1)}';
    }

    final url = Uri.parse('https://wa.me/$nomor');
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildProfileCard(),
                          const SizedBox(height: 16),
                          _buildTabBar(),
                          const SizedBox(height: 16),
                          _buildTabContent(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------
  // Profile card
  // --------------------------------------------------------------------
  Widget _buildProfileCard() {
    final status = _status();
    final statusColor = switch (status) {
      'SUSPENDED' => PColors.errorText,
      'PENDING' => PColors.pendingText,
      'ARCHIVED' => PColors.inkSecondary,
      _ => PColors.successText,
    };
    final statusBg = switch (status) {
      'SUSPENDED' => PColors.errorBg,
      'PENDING' => PColors.pendingBg,
      'ARCHIVED' => PColors.surfaceDim,
      _ => PColors.successBg,
    };
    final paket = _s(t['paket'], 'Basic');
    final subdomain = _s(t['subdomain'] ??
        '${_s(t['kodeTenant'] ?? t['slug'], 'tenant')}.sistempesantren.com');
    final lokasi = _s(t['lokasi'] ?? t['kota'] ?? t['alamatSingkat'] ?? t['alamat']);
    final tanggal =
        _s(t['tanggalDaftar'] ?? t['createdAt'] ?? t['tanggalGabung']);
    final logo = t['logoUrl']?.toString();

    return _Card(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LogoAvatar(logo: logo, size: 52, iconKey: t['logoIcon']?.toString()),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _StatusBadge(
                          label: status, bg: statusBg, fg: statusColor),
                      _StatusBadge(
                          icon: Icons.workspace_premium_outlined,
                          label: paket,
                          bg: PColors.goldSurface,
                          fg: PColors.gold),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_s(t['namaPondok'] ?? t['nama']),
                      style: PText.headlineSm.copyWith(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('slug: ${_s(t['kodeTenant'] ?? t['slug'])}',
                      style: PText.bodySm),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: PColors.surfaceDim,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.dns_outlined, size: 16, color: PColors.inkSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(subdomain,
                    style: PText.bodySm.copyWith(color: PColors.ink),
                    overflow: TextOverflow.ellipsis),
              ),
              const Icon(Icons.open_in_new, size: 15, color: PColors.inkSecondary),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.place_outlined, size: 14, color: PColors.inkSecondary),
            const SizedBox(width: 4),
            Expanded(child: Text(lokasi, style: PText.bodySm)),
            const Icon(Icons.event_outlined, size: 14, color: PColors.inkSecondary),
            const SizedBox(width: 4),
            Text(tanggal, style: PText.bodySm),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(color: PColors.border, height: 1),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
                child: _MetricBox(
                    label: 'Total User', value: _s(t['jumlahUser'], '0'))),
            const SizedBox(width: 8),
            Expanded(
                child: _MetricBox(
                    label: 'Santri Aktif',
                    value: _s(t['jumlahSantri'], '0'))),
            const SizedBox(width: 8),
            Expanded(
                child: _MetricBox(
                    label: 'Kelas', value: _s(t['jumlahKelas'], '0'))),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------------
  // Tabs
  // --------------------------------------------------------------------
  Widget _buildTabBar() {
    Widget pill(_Tab tab, String label, IconData icon) {
      final selected = _tab == tab;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = tab),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? PColors.primary : PColors.surfaceDim,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 16,
                    color: selected ? Colors.white : PColors.inkSecondary),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color:
                            selected ? Colors.white : PColors.inkSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pill(_Tab.informasi, 'Informasi', Icons.info_outline),
        const SizedBox(width: 8),
        pill(_Tab.pengguna, 'Pengguna', Icons.groups_outlined),
        const SizedBox(width: 8),
        pill(_Tab.langganan, 'Langganan', Icons.credit_card),
      ],
    );
  }

  Widget _buildTabContent() {
    switch (_tab) {
      case _Tab.informasi:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAdminCard(),
            const SizedBox(height: 16),
            _buildBrandingCard(),
          ],
        );
      case _Tab.pengguna:
        return _card(
          title: 'Distribusi Pengguna',
          icon: Icons.groups_outlined,
          rows: [
            ('Total User', _s(t['jumlahUser'], '0')),
            ('Santri Aktif', _s(t['jumlahSantri'], '0')),
            ('Jumlah Kelas', _s(t['jumlahKelas'], '0')),
            ('Admin Pondok', _s(t['jumlahAdmin'])),
            ('Ustadz & Guru', _s(t['jumlahUstadz'])),
          ],
        );
      case _Tab.langganan:
        return _card(
          title: 'Paket Langganan',
          icon: Icons.credit_card,
          rows: [
            ('Paket Aktif', _s(t['paket'], 'Basic')),
            ('Harga', _s(t['hargaLangganan'])),
            ('Periode Aktif', _s(t['periodeLangganan'])),
            ('Metode Pembayaran', _s(t['metodePembayaran'])),
            ('Status Gelombang PPDB', _s(t['statusGelombangPpdb'])),
            ('Kuota Santri PPDB', _s(t['kuotaSantriPpdb'])),
          ],
        );
    }
  }

  // --------------------------------------------------------------------
  // Informasi tab — sub cards mirip referensi
  // --------------------------------------------------------------------
  Widget _buildAdminCard() {
    final karakteristikList = (t['karakteristik'] is List)
        ? (t['karakteristik'] as List).map((e) => e.toString()).toList()
        : <String>[];

    return _Card(
      children: [
        Row(
          children: [
            const Icon(Icons.badge_outlined, size: 18, color: PColors.primary),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Data Admin Utama', style: PText.headlineSm.copyWith(fontSize: 15))),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                  color: PColors.surfaceDim, shape: BoxShape.circle),
              child: const Icon(Icons.person_outline,
                  color: PColors.inkSecondary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_s(t['adminNama']),
                      style: PText.bodyMd.copyWith(
                          color: PColors.ink, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Admin Awal Pondok', style: PText.bodySm),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ContactRow(
          icon: Icons.mail_outline,
          text: _s(t['adminEmail']),
          trailingIcon: Icons.copy,
        ),
        const SizedBox(height: 8),
        _ContactRow(
          icon: Icons.chat_outlined,
          text: _s(t['adminPhone']),
          trailingIcon: Icons.copy,
        ),
        const SizedBox(height: 16),
        Text('ALAMAT PONDOK',
            style: PText.labelSm.copyWith(color: PColors.inkSecondary)),
        const SizedBox(height: 6),
        Text(_s(t['alamat']), style: PText.bodyMd.copyWith(color: PColors.ink)),
        const SizedBox(height: 14),
        Text('KARAKTERISTIK & KURIKULUM',
            style: PText.labelSm.copyWith(color: PColors.inkSecondary)),
        const SizedBox(height: 6),
        if (karakteristikList.isEmpty)
          Text('-', style: PText.bodyMd.copyWith(color: PColors.ink))
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: karakteristikList
                .map((label) => _StatusBadge(
                      label: label,
                      bg: PColors.sage,
                      fg: PColors.primary,
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildBrandingCard() {
    final logo = t['logoUrl']?.toString();
    final warnaPrimer = _hexColor(t['warnaPrimer'], PColors.primary);
    final warnaSekunder = _hexColor(t['warnaSekunder'], PColors.gold);
    final warnaCanvas = _hexColor(t['warnaCanvas'], PColors.background);
    final hexPrimer = _s(t['warnaPrimer'], '#0F3A2E').toUpperCase();
    final hexSekunder = _s(t['warnaSekunder'], '#C5A059').toUpperCase();
    final hexCanvas = _s(t['warnaCanvas'], '#FAF9F5').toUpperCase();
    return _Card(
      children: [
        Row(
          children: [
            const Icon(Icons.palette_outlined, size: 18, color: PColors.primary),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Identitas & Branding',
                    style: PText.headlineSm.copyWith(fontSize: 15))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: PColors.surfaceDim,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 12, color: PColors.inkSecondary),
                  const SizedBox(width: 4),
                  Text('Dikelola Pondok',
                      style: PText.labelSm.copyWith(color: PColors.inkSecondary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _LogoAvatar(logo: logo, size: 48, radius: 10, iconKey: t['logoIcon']?.toString()),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Logo Lembaga',
                      style: PText.bodyMd.copyWith(
                          color: PColors.ink, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Terpasang di Web Portal & Aplikasi Mobile',
                      style: PText.bodySm),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('PALET WARNA PESANTREN',
            style: PText.labelSm.copyWith(color: PColors.inkSecondary)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _ColorSwatch(
                    color: warnaPrimer, hex: hexPrimer, label: 'Utama')),
            const SizedBox(width: 8),
            Expanded(
                child: _ColorSwatch(
                    color: warnaSekunder, hex: hexSekunder, label: 'Sekunder')),
            const SizedBox(width: 8),
            Expanded(
                child: _ColorSwatch(
                    color: warnaCanvas,
                    hex: hexCanvas,
                    label: 'Canvas',
                    border: true)),
          ],
        ),
      ],
    );
  }


  Widget _card(
      {required String title,
      required IconData icon,
      required List<(String, String)> rows}) {
    return _Card(
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: PColors.primary),
            const SizedBox(width: 8),
            Text(title, style: PText.headlineSm.copyWith(fontSize: 15)),
          ],
        ),
        const SizedBox(height: 12),
        for (final r in rows) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 140, child: Text(r.$1, style: PText.bodySm)),
                Expanded(
                  child: Text(r.$2,
                      style: PText.bodySm.copyWith(
                          color: PColors.ink, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const Divider(color: PColors.border, height: 1),
        ],
      ],
    );
  }

  // --------------------------------------------------------------------
  // Bottom bar — background full width, konten di-center & di-constrain
  // --------------------------------------------------------------------
  Widget _buildBottomBar(BuildContext context) {
    final status = _status();

    Widget leftBtn;
    Widget rightBtn;

    if (status == 'PENDING') {
      leftBtn = OutlinedButton(
        onPressed: () {},
        child: const Text('Tinjau Berkas'),
      );
      rightBtn = FilledButton(
        onPressed: widget.onApprove,
        child: const Text('Setujui & Aktifkan'),
      );
    } else if (status == 'SUSPENDED') {
      leftBtn = OutlinedButton.icon(
        onPressed: () => _hubungiPIC(context),
        icon: const Icon(Icons.chat_outlined, size: 16),
        label: const Text('Hubungi PIC'),
      );
      rightBtn = FilledButton.icon(
        onPressed: widget.onRestore,
        icon: const Icon(Icons.lock_open, size: 16),
        label: const Text('Pulihkan Akses'),
      );
    } else if (status == 'ARCHIVED') {
      leftBtn = OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.block, size: 16),
        label: const Text('Login Ditutup'),
      );
      rightBtn = FilledButton.icon(
        onPressed: () => _confirmUnarchive(context),
        icon: const Icon(Icons.unarchive_outlined, size: 16),
        label: const Text('Pulihkan dari Arsip'),
      );
    } else {
      leftBtn = OutlinedButton.icon(
        onPressed: () => _confirmArchive(context),
        icon: const Icon(Icons.archive_outlined, size: 16),
        label: const Text('Arsipkan'),
      );
      rightBtn = FilledButton.icon(
        onPressed: () => _confirmSuspend(context),
        style: FilledButton.styleFrom(
          backgroundColor: PColors.errorBg,
          foregroundColor: PColors.errorText,
        ),
        icon: const Icon(Icons.pause_circle_outline, size: 16),
        label: const Text('Suspend'),
      );
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: PColors.background,
        border: Border(top: BorderSide(color: PColors.border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: leftBtn),
                    const SizedBox(width: 8),
                    Expanded(child: rightBtn),
                  ],
                ),
                if (status == 'PENDING') ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => _confirmDelete(context),
                      style: TextButton.styleFrom(foregroundColor: PColors.errorText),
                      child: const Text('Hapus Pendaftaran Ini',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmSuspend(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tangguhkan Tenant?', style: PText.headlineSm),
        content: const Text(
            'Akses tenant ini akan dihentikan sementara sampai diaktifkan kembali.',
            style: PText.bodyMd),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: PText.labelMd.copyWith(color: PColors.inkSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onSuspend?.call();
            },
            style: TextButton.styleFrom(foregroundColor: PColors.errorText),
            child: const Text('Ya, Suspend',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmArchive(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Arsipkan Tenant?', style: PText.headlineSm),
        content: const Text(
            'Tenant ini akan diarsipkan. Seluruh user (admin, ustadz, wali santri, dst) '
            'tidak akan bisa login sampai tenant dipulihkan kembali dari arsip. '
            'Data tidak dihapus dan bisa dipulihkan sewaktu-waktu.',
            style: PText.bodyMd),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: PText.labelMd.copyWith(color: PColors.inkSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onArchive?.call();
            },
            style: TextButton.styleFrom(foregroundColor: PColors.errorText),
            child: const Text('Ya, Arsipkan',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmUnarchive(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Pulihkan Tenant dari Arsip?', style: PText.headlineSm),
        content: const Text(
            'Tenant ini akan diaktifkan kembali dan seluruh usernya bisa login seperti biasa.',
            style: PText.bodyMd),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: PText.labelMd.copyWith(color: PColors.inkSecondary)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onUnarchive?.call();
            },
            style: FilledButton.styleFrom(backgroundColor: PColors.primary),
            child: const Text('Ya, Pulihkan'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Pendaftaran Ini?', style: PText.headlineSm),
        content: const Text(
            'Pendaftaran tenant ini akan dihapus permanen dan TIDAK BISA dikembalikan. '
            'Gunakan ini hanya untuk pendaftaran yang tidak valid atau tidak jadi diproses.',
            style: PText.bodyMd),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: PText.labelMd.copyWith(color: PColors.inkSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).maybePop();
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: PColors.errorText),
            child: const Text('Ya, Hapus Permanen',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Header — background full width, konten di-center & di-constrain (480)
// ===========================================================================
class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: PColors.surface,
        border: Border(bottom: BorderSide(color: PColors.border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.chevron_left, color: PColors.ink, size: 26),
                ),
                Expanded(
                  child: Text('Detail Tenant', style: PText.headlineSm.copyWith(fontSize: 17)),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: PColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.person, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert, color: PColors.inkSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Building blocks
// ===========================================================================
class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F3A2E),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: fg)),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PColors.surfaceDim,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: PText.headlineSm
                  .copyWith(fontSize: 15, color: PColors.primary)),
          const SizedBox(height: 2),
          Text(label, style: PText.bodySm, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PColors.surfaceDim,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: PText.labelSm.copyWith(color: PColors.inkSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: PText.bodyMd.copyWith(
                  color: PColors.ink, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.text,
    this.trailingIcon,
    this.chipLabel,
  });

  final IconData icon;
  final String text;
  final IconData? trailingIcon;
  final String? chipLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: PColors.surfaceDim,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: PColors.inkSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: PText.bodySm.copyWith(color: PColors.ink),
                overflow: TextOverflow.ellipsis),
          ),
          if (chipLabel != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: PColors.successBg,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(chipLabel!,
                  style: PText.labelSm.copyWith(color: PColors.successText)),
            )
          else if (trailingIcon != null)
            Icon(trailingIcon, size: 15, color: PColors.inkSecondary),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.hex,
    required this.label,
    this.border = false,
  });

  final Color color;
  final String hex;
  final String label;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PColors.surfaceDim,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: border ? Border.all(color: PColors.border) : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(hex,
              style: PText.bodySm.copyWith(
                  color: PColors.ink,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace')),
          Text(label, style: PText.bodySm),
        ],
      ),
    );
  }
}

class _LogoAvatar extends StatelessWidget {
  const _LogoAvatar({
    required this.logo,
    required this.size,
    this.radius = 12,
    this.iconKey,
  });

  final String? logo;
  final double size;
  final double radius;
  final String? iconKey;

  @override
  Widget build(BuildContext context) {
    final fallbackIcon = resolveLogoIcon(iconKey);
    Widget child = Icon(fallbackIcon, color: PColors.primary, size: size * 0.46);

    if (logo != null && logo!.trim().isNotEmpty) {
      try {
        if (logo!.startsWith('data:')) {
          final b64 = logo!.split(',').last;
          child = ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.memory(base64Decode(b64), fit: BoxFit.cover),
          );
        } else if (logo!.startsWith('http')) {
          child = ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.network(logo!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(fallbackIcon, color: PColors.primary, size: size * 0.46)),
          );
        }
      } catch (_) {
        // fallback ke ikon default kalau data logo rusak
      }
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: PColors.surfaceDim,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}