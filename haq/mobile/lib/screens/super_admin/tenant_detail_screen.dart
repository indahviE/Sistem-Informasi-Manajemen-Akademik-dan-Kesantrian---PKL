// tenant_detail_screen.dart
//
// Detail Tenant — Platform Control Panel (Super Admin)
//
// Memakai token warna & tipografi yang sama dengan tenants_screen.dart
// (PColors/PText). Banyak field di sini (admin, alamat kampus, kategori
// lembaga, dokumen legalitas, warna brand, statistik pengguna, langganan,
// audit log) BELUM ada di response API tenant saat ini — ditandai dengan
// komentar "TODO: backend" di setiap tempat yang memakai nilai fallback/mock.
// Begitu field-field itu tersedia di DTO tenant, tinggal ganti fallback-nya.

import 'package:flutter/material.dart';
import 'tenants_screen.dart' show PColors, PText;

enum _DetailTab { informasi, pengguna, langganan, aktivitas }

class TenantDetailScreen extends StatefulWidget {
  const TenantDetailScreen({
    super.key,
    required this.tenant,
    this.onApprove,
    this.onSuspend,
    this.onRestore,
  });

  final Map<String, dynamic> tenant;
  final VoidCallback? onApprove;
  final VoidCallback? onSuspend;
  final VoidCallback? onRestore;

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  _DetailTab _tab = _DetailTab.informasi;

  Map<String, dynamic> get t => widget.tenant;
  String get _status => (t['status'] ?? 'AKTIF').toString().toUpperCase();

  String _fmt(num? n) {
    if (n == null) return '-';
    final s = n.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i != 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                _DetailHeader(onMore: () => _openMoreMenu(context)),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _ProfileCard(tenant: t),
                      const SizedBox(height: 14),
                      _TabPills(
                        selected: _tab,
                        onSelected: (v) => setState(() => _tab = v),
                      ),
                      const SizedBox(height: 14),
                      switch (_tab) {
                        _DetailTab.informasi => _InformasiTab(tenant: t),
                        _DetailTab.pengguna => _PenggunaTab(tenant: t),
                        _DetailTab.langganan => _LangganaTab(tenant: t),
                        _DetailTab.aktivitas => const _AktivitasTab(),
                      },
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _BottomActionBar(
          status: _status,
          onImpersonate: () => _showSnack(context, 'Beralih sebagai admin tenant ini.'),
          onSuspend: () => _confirmSuspend(context),
          onApprove: widget.onApprove,
          onRestore: widget.onRestore,
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _confirmSuspend(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: PColors.errorBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.block, color: PColors.errorText),
            ),
            const SizedBox(height: 12),
            const Text('Tangguhkan Tenant?',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: PColors.ink)),
            const SizedBox(height: 6),
            Text(
              'Akses untuk ${_fmt(t['jumlahUser'] as num?)} pengguna pondok ini '
              'akan dihentikan sementara hingga status diaktifkan kembali.',
              textAlign: TextAlign.center,
              style: PText.bodySm,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PColors.ink,
                    side: const BorderSide(color: PColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999)),
                  ),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    widget.onSuspend?.call();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: PColors.errorText,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999)),
                  ),
                  child: const Text('Ya, Suspend'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Opsi Platform',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: PColors.ink)),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                const Divider(color: PColors.border, height: 1),
                const SizedBox(height: 8),
                _MoreMenuTile(
                  icon: Icons.cloud_sync,
                  label: 'Sinkronkan Cache & Indeks DB',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showSnack(context, 'Sinkronisasi database dimulai.');
                  },
                ),
                _MoreMenuTile(
                  icon: Icons.download_outlined,
                  label: 'Ekspor Data Metadata Tenant',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showSnack(context, 'Ekspor data sedang diproses.');
                  },
                ),
                _MoreMenuTile(
                  icon: Icons.delete_forever,
                  label: 'Hapus Tenant Permanen',
                  danger: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDelete(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: PColors.errorBg, shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded, color: PColors.errorText),
            ),
            const SizedBox(height: 12),
            const Text('Hapus Tenant Permanen?',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: PColors.errorText)),
            const SizedBox(height: 6),
            Text(
              'Tindakan ini menghapus seluruh database, berkas legalitas, dan '
              'riwayat mutaba\'ah. Tindakan tidak dapat dibatalkan!',
              textAlign: TextAlign.center,
              style: PText.bodySm,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PColors.ink,
                    side: const BorderSide(color: PColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999)),
                  ),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    // TODO: backend — panggil endpoint hapus tenant permanen di sini.
                    Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB91C1C),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999)),
                  ),
                  child: const Text('Hapus Selamanya'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Header
// ============================================================================

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.onMore});

  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.chevron_left, size: 26, color: PColors.ink),
          ),
          const Expanded(
            child: Text('Detail Tenant',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: PColors.ink)),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: PColors.sage,
              shape: BoxShape.circle,
              border: Border.all(color: PColors.goldBorder),
            ),
            child: const Icon(Icons.person, size: 16, color: PColors.primary),
          ),
          IconButton(
            onPressed: onMore,
            icon: const Icon(Icons.more_vert, color: PColors.inkSecondary),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Profile card
// ============================================================================

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.tenant});

  final Map<String, dynamic> tenant;

  @override
  Widget build(BuildContext context) {
    final namaPondok = (tenant['namaPondok'] ?? '-').toString();
    final kodeTenant = (tenant['kodeTenant'] ?? '-').toString();
    final wilayah = (tenant['wilayah'] ?? tenant['lokasi'] ?? '-').toString();
    final subdomain =
        (tenant['subdomain'] ?? '$kodeTenant.sistempesantren.com').toString();
    final tanggal =
        (tenant['tanggalGabung'] ?? tenant['createdAt'] ?? '-').toString();
    final status = (tenant['status'] ?? 'AKTIF').toString().toUpperCase();
    final paket = (tenant['paket'] ?? 'Basic').toString();
    final logoUrl = tenant['logoUrl'] as String?; // TODO: backend

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0F3A2E), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: PColors.surfaceDim,
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: logoUrl != null
                    ? Image.network(logoUrl, fit: BoxFit.cover)
                    : const Icon(Icons.mosque, color: PColors.primary, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _MiniStatusBadge(status: status),
                        _MiniPackageBadge(paket: paket),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(namaPondok,
                        style: PText.headlineSm.copyWith(fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: PColors.surfaceDim,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('slug: $kodeTenant', style: PText.mono),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              // TODO: buka https://$subdomain lewat url_launcher jika paket itu ditambahkan.
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: PColors.surfaceDim,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.dns_outlined, size: 17, color: PColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(subdomain,
                        style: PText.mono.copyWith(fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const Icon(Icons.open_in_new, size: 15, color: PColors.outline),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: PColors.surfaceDim.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 15, color: PColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(wilayah,
                            style: PText.bodySm, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.verified, size: 14, color: PColors.goldDark),
                    const SizedBox(width: 3),
                    Text(tanggal, style: PText.labelSm),
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

class _MiniStatusBadge extends StatelessWidget {
  const _MiniStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      'SUSPENDED' => (PColors.errorBg, PColors.errorText, 'Suspended'),
      'PENDING' => (PColors.pendingBg, PColors.pendingText, 'Pending'),
      _ => (PColors.successBg, PColors.successText, 'Aktif'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 5, height: 5, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 9, fontWeight: FontWeight.w800, color: fg)),
        ],
      ),
    );
  }
}

class _MiniPackageBadge extends StatelessWidget {
  const _MiniPackageBadge({required this.paket});

  final String paket;

  @override
  Widget build(BuildContext context) {
    final isEnterprise = paket.toLowerCase() == 'enterprise';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: PColors.goldSurface,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEnterprise) ...[
            Icon(Icons.workspace_premium, size: 11, color: PColors.goldDark),
            const SizedBox(width: 3),
          ],
          Text(paket,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: PColors.goldDark)),
        ],
      ),
    );
  }
}

// ============================================================================
// Tab pills
// ============================================================================

class _TabPills extends StatelessWidget {
  const _TabPills({required this.selected, required this.onSelected});

  final _DetailTab selected;
  final ValueChanged<_DetailTab> onSelected;

  static const _tabs = {
    _DetailTab.informasi: (Icons.info_outline, 'Informasi'),
    _DetailTab.pengguna: (Icons.groups_outlined, 'Pengguna'),
    _DetailTab.langganan: (Icons.credit_card, 'Langganan'),
    _DetailTab.aktivitas: (Icons.history, 'Aktivitas'),
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tabs.entries.map((e) {
          final isSelected = selected == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? PColors.primaryContainer : PColors.surfaceDim,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(e.value.$1,
                        size: 16, color: isSelected ? Colors.white : PColors.inkSecondary),
                    const SizedBox(width: 6),
                    Text(
                      e.value.$2,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : PColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================================
// Shared card shell
// ============================================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    this.trailing,
    required this.children,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0F3A2E), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, size: 19, color: PColors.primaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(title,
                          style: PText.headlineSm, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

// ============================================================================
// Tab: Informasi
// ============================================================================

class _InformasiTab extends StatelessWidget {
  const _InformasiTab({required this.tenant});

  final Map<String, dynamic> tenant;

  @override
  Widget build(BuildContext context) {
    // TODO: backend — field admin/alamat/kategori/legalitas/warna brand di
    // bawah ini belum ada di DTO tenant; masih memakai nilai fallback.
    final adminNama = (tenant['adminNama'] ?? '-').toString();
    final adminRole =
        (tenant['adminRole'] ?? 'Ketua Yayasan / Pendaftar Pertama').toString();
    final adminEmail = (tenant['adminEmail'] ?? '-').toString();
    final adminPhone = (tenant['adminPhone'] ?? '-').toString();
    final alamatKampus = (tenant['alamatKampus'] ?? '-').toString();
    final kategoriLembaga = (tenant['kategoriLembaga'] ?? '-').toString();
    final estimasiSantri = (tenant['estimasiSantri'] ?? '-').toString();
    final legalDocs = (tenant['legalDocs'] as List?) ??
        const [
          {'title': 'SK NSPP Kemenag RI', 'ref': 'NSPP: -', 'icon': 'description'},
          {'title': 'Akta & SK Kemenkumham', 'ref': '-', 'icon': 'article'},
          {'title': 'Surat Domisili Lembaga', 'ref': '-', 'icon': 'domain_verification'},
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          icon: Icons.badge_outlined,
          title: 'Data Admin Utama',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: PColors.goldSurface,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text("Mudir 'Am",
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: PColors.goldDark)),
          ),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: PColors.surfaceDim, shape: BoxShape.circle),
                  child: const Icon(Icons.account_circle_outlined,
                      color: PColors.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(adminNama,
                          style: PText.headlineSm.copyWith(fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(adminRole, style: PText.bodySm),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PColors.surfaceDim,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.mail_outline, size: 16, color: PColors.inkSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(adminEmail,
                              style: PText.bodySm, overflow: TextOverflow.ellipsis)),
                      const Icon(Icons.copy, size: 14, color: PColors.outline),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.call_outlined, size: 16, color: PColors.inkSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(adminPhone,
                              style: PText.bodySm.copyWith(
                                  fontWeight: FontWeight.w600, color: PColors.ink))),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: PColors.successBg,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chat_bubble_outline,
                                size: 11, color: PColors.successText),
                            const SizedBox(width: 3),
                            Text('WhatsApp',
                                style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: PColors.successText)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('ALAMAT KAMPUS', style: PText.labelSm),
            const SizedBox(height: 3),
            Text(alamatKampus, style: PText.bodyMd.copyWith(color: PColors.ink)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatBox(label: 'Kategori Lembaga', value: kategoriLembaga),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatBox(label: 'Estimasi Awal Santri', value: estimasiSantri),
                ),
              ],
            ),
          ],
        ),
        _SectionCard(
          icon: Icons.palette_outlined,
          title: 'Identitas & Branding',
          trailing: TextButton.icon(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: PColors.surfaceContainerHigh,
              foregroundColor: PColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
            ),
            icon: const Icon(Icons.brush_outlined, size: 14),
            label: const Text('Edit Tema',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PColors.surfaceDim,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: PColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_outlined, color: PColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Logo Lembaga (High-Res SVG)', style: PText.labelMd),
                        Text('Terpasang di Web Portal & Aplikasi Mobile',
                            style: PText.bodySm),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Palet Warna Pesantren', style: PText.bodySm),
            const SizedBox(height: 8),
            Row(
              children: const [
                Expanded(
                    child: _ColorSwatch(
                        color: PColors.primary, hex: '#0F3A2E', label: 'Utama')),
                SizedBox(width: 8),
                Expanded(
                    child: _ColorSwatch(
                        color: PColors.gold, hex: '#C5A059', label: 'Sekunder')),
                SizedBox(width: 8),
                Expanded(
                    child: _ColorSwatch(
                        color: PColors.background,
                        hex: '#FAF9F5',
                        label: 'Canvas',
                        bordered: true)),
              ],
            ),
          ],
        ),
        _SectionCard(
          icon: Icons.verified_user_outlined,
          title: 'Legalitas & Berkas Kemenag',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: PColors.successBg,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 12, color: PColors.successText),
                const SizedBox(width: 3),
                Text('${legalDocs.length} Valid',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: PColors.successText)),
              ],
            ),
          ),
          children: [
            for (int i = 0; i < legalDocs.length; i++) ...[
              _LegalDocRow(doc: legalDocs[i] as Map),
              if (i != legalDocs.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

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
          Text(label, style: PText.labelSm),
          const SizedBox(height: 3),
          Text(value,
              style: PText.bodySm.copyWith(
                  color: PColors.primary, fontWeight: FontWeight.w700)),
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
    this.bordered = false,
  });

  final Color color;
  final String hex;
  final String label;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: PColors.surfaceDim,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: bordered ? Border.all(color: PColors.border) : null,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hex, style: PText.mono.copyWith(fontSize: 10)),
                Text(label,
                    style: PText.labelSm.copyWith(fontSize: 9),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalDocRow extends StatelessWidget {
  const _LegalDocRow({required this.doc});

  final Map doc;

  static const _icons = {
    'description': Icons.description_outlined,
    'article': Icons.article_outlined,
    'domain_verification': Icons.domain_verification_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _icons[doc['icon']] ?? Icons.description_outlined;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PColors.surfaceDim,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: PColors.primaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((doc['title'] ?? '-').toString(),
                    style: PText.bodySm.copyWith(
                        fontWeight: FontWeight.w600, color: PColors.ink)),
                Text((doc['ref'] ?? '-').toString(),
                    style: PText.mono.copyWith(fontSize: 10, color: PColors.inkSecondary)),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () {
              // TODO: backend — buka pratinjau dokumen.
            },
            icon: const Icon(Icons.visibility_outlined, size: 18, color: PColors.primary),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () {
              // TODO: backend — unduh dokumen.
            },
            icon: const Icon(Icons.download_outlined, size: 18, color: PColors.primary),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Tab: Pengguna
// ============================================================================

class _PenggunaTab extends StatelessWidget {
  const _PenggunaTab({required this.tenant});

  final Map<String, dynamic> tenant;

  @override
  Widget build(BuildContext context) {
    // TODO: backend — breakdown peran pengguna belum ada di DTO tenant;
    // sementara hanya total pengguna (jumlahUser) yang berasal dari API.
    final total = tenant['jumlahUser'] ?? 0;
    final stats = <(IconData, Color, String, String)>[
      (Icons.manage_accounts_outlined, PColors.primaryFixed, '${tenant['jumlahAdmin'] ?? '-'}', 'Admin Pondok'),
      (Icons.school_outlined, PColors.goldSurface, '${tenant['jumlahUstadz'] ?? '-'}', 'Ustadz & Guru'),
      (Icons.home_work_outlined, PColors.sage, '${tenant['jumlahMusyrif'] ?? '-'}', 'Musyrif Pembina'),
      (Icons.family_restroom_outlined, PColors.surfaceContainerHigh, '${tenant['jumlahWali'] ?? '-'}', 'Wali Santri'),
      (Icons.person_outline, PColors.primaryContainer, '${tenant['jumlahSantri'] ?? '-'}', 'Santri Aktif'),
    ];

    return _SectionCard(
      icon: Icons.groups_outlined,
      title: 'Distribusi Akun & Peran',
      trailing: null,
      children: [
        Text('Total $total Pengguna Terdaftar', style: PText.bodySm),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stats.map((s) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 32 - 32 - 8) / 2,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PColors.surfaceDim,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration:
                          BoxDecoration(color: s.$2, borderRadius: BorderRadius.circular(8)),
                      child: Icon(s.$1, size: 17, color: PColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.$3,
                              style: PText.headlineSm.copyWith(fontSize: 15)),
                          Text(s.$4, style: PText.bodySm, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Text('PENGGUNA TERBARU DITAMBAHKAN', style: PText.labelSm),
        const SizedBox(height: 8),
        const _EmptyRecentUsers(), // TODO: backend — hubungkan ke endpoint aktivitas user terbaru
      ],
    );
  }
}

class _EmptyRecentUsers extends StatelessWidget {
  const _EmptyRecentUsers();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: PColors.surfaceDim,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('Belum ada data pengguna terbaru.', style: PText.bodySm),
    );
  }
}

// ============================================================================
// Tab: Langganan
// ============================================================================

class _LangganaTab extends StatelessWidget {
  const _LangganaTab({required this.tenant});

  final Map<String, dynamic> tenant;

  @override
  Widget build(BuildContext context) {
    // TODO: backend — seluruh data langganan (harga, kuota, periode, billing)
    // belum ada di DTO tenant; masih memakai fallback.
    final paket = (tenant['paket'] ?? 'Basic').toString();
    final harga = (tenant['hargaLangganan'] ?? '-').toString();
    final kuotaTerpakai = tenant['jumlahSantri'] as num? ?? 0;
    final kuotaMaks = tenant['kuotaSantri'] as num? ?? 0;
    final persen = kuotaMaks > 0 ? (kuotaTerpakai / kuotaMaks * 100).clamp(0, 100) : 0;

    return _SectionCard(
      icon: Icons.credit_card,
      title: 'Paket Langganan',
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: PColors.goldSurface,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Text(paket,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: PColors.goldDark)),
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            style: PText.headlineLg.copyWith(fontSize: 18, color: PColors.primary),
            children: [
              TextSpan(text: harga),
              TextSpan(
                  text: '/bln',
                  style: PText.bodySm.copyWith(fontWeight: FontWeight.w400)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PColors.surfaceDim,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Kapasitas Santri Terdaftar',
                      style: PText.labelMd.copyWith(fontSize: 11)),
                  Text('$kuotaTerpakai / $kuotaMaks (${persen.toStringAsFixed(0)}%)',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: PColors.primary)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(9999),
                child: LinearProgressIndicator(
                  value: persen / 100,
                  minHeight: 8,
                  backgroundColor: PColors.surfaceContainerHigh,
                  valueColor: const AlwaysStoppedAnimation(PColors.primaryContainer),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _KvRow('Periode Aktif', (tenant['periodeLangganan'] ?? '-').toString()),
        _KvRow('Metode Pembayaran', (tenant['metodePembayaran'] ?? '-').toString()),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Status Billing', style: PText.bodySm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: PColors.successBg,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text('Lancar',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: PColors.successText)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: PColors.primaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999)),
                ),
                icon: const Icon(Icons.upgrade, size: 16),
                label: const Text('Ubah Paket', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: PColors.primary,
                  side: const BorderSide(color: PColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999)),
                ),
                icon: const Icon(Icons.receipt_long, size: 16),
                label: const Text('Riwayat Faktur', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KvRow extends StatelessWidget {
  const _KvRow(this.k, this.v);

  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: PText.bodySm),
          Text(v,
              style: PText.bodySm.copyWith(
                  color: PColors.ink, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ============================================================================
// Tab: Aktivitas
// ============================================================================

class _AktivitasTab extends StatelessWidget {
  const _AktivitasTab();

  @override
  Widget build(BuildContext context) {
    // TODO: backend — hubungkan ke endpoint audit log tenant; ini masih placeholder.
    return _SectionCard(
      icon: Icons.history,
      title: 'Audit Log Platform',
      children: const [
        _EmptyRecentUsers(),
      ],
    );
  }
}

// ============================================================================
// Bottom action bar
// ============================================================================

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.status,
    required this.onImpersonate,
    required this.onSuspend,
    this.onApprove,
    this.onRestore,
  });

  final String status;
  final VoidCallback onImpersonate;
  final VoidCallback onSuspend;
  final VoidCallback? onApprove;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    Widget primaryButton;
    Widget secondaryButton;

    switch (status) {
      case 'PENDING':
        secondaryButton = OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: PColors.ink,
            side: const BorderSide(color: PColors.border),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
          ),
          child: const Text('Tinjau Berkas'),
        );
        primaryButton = FilledButton(
          onPressed: onApprove,
          style: FilledButton.styleFrom(
            backgroundColor: PColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
          ),
          child: const Text('Setujui & Aktifkan'),
        );
      case 'SUSPENDED':
        secondaryButton = OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: PColors.ink,
            side: const BorderSide(color: PColors.border),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
          ),
          child: const Text('Hubungi PIC'),
        );
        primaryButton = FilledButton.icon(
          onPressed: onRestore,
          style: FilledButton.styleFrom(
            backgroundColor: PColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
          ),
          icon: const Icon(Icons.lock_open, size: 16),
          label: const Text('Pulihkan Akses'),
        );
      default: // AKTIF
        secondaryButton = OutlinedButton.icon(
          onPressed: onImpersonate,
          style: OutlinedButton.styleFrom(
            foregroundColor: PColors.primary,
            side: const BorderSide(color: PColors.border),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
          ),
          icon: const Icon(Icons.switch_account, size: 16),
          label: const Text('Impersonate', style: TextStyle(fontSize: 12)),
        );
        primaryButton = FilledButton.icon(
          onPressed: onSuspend,
          style: FilledButton.styleFrom(
            backgroundColor: PColors.errorBg,
            foregroundColor: PColors.errorText,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
            elevation: 0,
          ),
          icon: const Icon(Icons.pause_circle_outline, size: 16),
          label: const Text('Suspend', style: TextStyle(fontSize: 12)),
        );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: PColors.surface,
            border: Border(top: BorderSide(color: PColors.border)),
          ),
          child: Row(
            children: [
              Expanded(child: secondaryButton),
              const SizedBox(width: 8),
              Expanded(child: primaryButton),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// More-menu tile
// ============================================================================

class _MoreMenuTile extends StatelessWidget {
  const _MoreMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? PColors.errorText : PColors.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: danger ? PColors.errorText : PColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: PText.bodyMd.copyWith(color: color),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}