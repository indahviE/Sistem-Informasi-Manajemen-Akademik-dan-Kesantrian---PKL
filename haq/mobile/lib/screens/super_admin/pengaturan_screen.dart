// pengaturan_screen.dart
//
// Pengaturan — Platform Control Panel (Super Admin)
//
// Desain memakai token warna & tipografi PColors/PText yang sudah
// didefinisikan di tenants_screen.dart (satu folder yang sama), supaya
// tidak duplikat class dan bentrok "ambiguous import" saat kedua file ini
// sama-sama di-import bareng (mis. dari shell.dart).

import 'package:flutter/material.dart';
import 'tenants_screen.dart' show PColors, PText;
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import 'pengaturan_dialogs.dart';

// ============================================================================
// Model
// ============================================================================

class SubAdminData {
  SubAdminData({
    required this.id,
    required this.nama,
    required this.email,
    required this.roleType,
    required this.tanggal,
  });

  final String id;
  final String nama;
  final String email;
  final String? roleType; // 'OPERASIONAL' | 'KEUANGAN' | null

  final String tanggal;

  factory SubAdminData.fromJson(Map<String, dynamic> j) {
    return SubAdminData(
      id: j['id'].toString(),
      nama: (j['nama'] ?? '-').toString(),
      email: (j['email'] ?? '-').toString(),
      roleType: j['subRole']?.toString(),
      tanggal: _formatTanggal(j['createdAt']?.toString()),
    );
  }

  String get initials {
    final parts = nama.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String get roleLabel => switch (roleType) {
        'KEUANGAN' => 'Admin Keuangan & Billing',
        'OPERASIONAL' => 'Admin Operasional',
        _ => 'Sub-Admin',
      };
}

String _formatTanggal(String? iso) {
  if (iso == null) return '-';
  try {
    final d = DateTime.parse(iso).toLocal();
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${bulan[d.month - 1]} ${d.year}';
  } catch (_) {
    return '-';
  }
}

// ============================================================================
// Screen
// ============================================================================

class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  bool _loading = true;
  bool _initialized = false;
  String? _error;

  // Kebijakan onboarding
  bool _autoApprove = false;
  int _graceDays = 14;

  // Notifikasi
  bool _notifTenantBaru = true;
  bool _notifTagihan = true;
  bool _notifKeamanan = true;
  bool _notifLaporan = false;

  // Sub-admin
  List<SubAdminData> _subAdmins = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  ApiClient get _api => AppScope.of(context).api;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get(ApiUrl.pengaturan) as Map<String, dynamic>;
      final kebijakan = res['kebijakanOnboarding'] as Map<String, dynamic>? ?? {};
      final notifikasi = res['notifikasi'] as Map<String, dynamic>? ?? {};
      final subAdmins = (res['subAdmins'] as List? ?? [])
          .map((e) => SubAdminData.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _autoApprove = kebijakan['autoApproveTenant'] ?? false;
        _graceDays = kebijakan['graceDaysPending'] ?? 14;
        _notifTenantBaru = notifikasi['notifTenantBaru'] ?? true;
        _notifTagihan = notifikasi['notifTagihan'] ?? true;
        _notifKeamanan = notifikasi['notifKeamanan'] ?? true;
        _notifLaporan = notifikasi['notifLaporanMingguan'] ?? false;
        _subAdmins = subAdmins;
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

  // -------------------------------------------------------------------
  // Edit Profil
  // -------------------------------------------------------------------

  Future<void> _editProfil() async {
    final scope = AppScope.of(context);
    final api = _api;
    final user = scope.user;

    final saved = await showEditProfilSheet(
      context,
      nama: user?.nama ?? '',
      email: user?.email ?? '',
      onSubmit: (nama, email) async {
        await api.patch(ApiUrl.pengaturanProfil, {'nama': nama, 'email': email});
        await scope.updateProfil(nama: nama, email: email);
      },
    );

    if (saved == true && mounted) AppToast.success(context, 'Perubahan tersimpan');
  }

  Future<void> _editProfilLama() async {
    final user = AppScope.of(context).user;
    final namaCtrl = TextEditingController(text: user?.nama ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profil', style: PText.headlineSm),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: namaCtrl,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: PText.labelMd.copyWith(color: PColors.inkSecondary)),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            style: FilledButton.styleFrom(backgroundColor: PColors.primary),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      await _api.patch(ApiUrl.pengaturanProfil, {
        'nama': namaCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
      });
      if (!mounted) return;
      await AppScope.of(context).updateProfil(
        nama: namaCtrl.text.trim(),
        email: emailCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
    } on ApiException catch (e) {
      _showError(e.message);
    }
  }

  // -------------------------------------------------------------------
  // Ubah Password
  // -------------------------------------------------------------------

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

  Future<void> _ubahPasswordLama() async {
    final lamaCtrl = TextEditingController();
    final baruCtrl = TextEditingController();
    final konfirmasiCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ubah Password', style: PText.headlineSm),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: lamaCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password Saat Ini'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: baruCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password Baru'),
                  validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: konfirmasiCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Konfirmasi Password Baru'),
                  validator: (v) => (v != baruCtrl.text) ? 'Konfirmasi tidak cocok' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: PText.labelMd.copyWith(color: PColors.inkSecondary)),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            style: FilledButton.styleFrom(backgroundColor: PColors.primary),
            child: const Text('Ubah Password'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      await _api.patch(ApiUrl.pengaturanUbahPassword, {
        'passwordLama': lamaCtrl.text,
        'passwordBaru': baruCtrl.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil diubah')),
      );
    } on ApiException catch (e) {
      _showError(e.message);
    }
  }

  // -------------------------------------------------------------------
  // Kebijakan onboarding
  // -------------------------------------------------------------------

  Future<void> _updateKebijakan({bool? autoApprove, int? graceDays}) async {
    final prevAuto = _autoApprove;
    final prevGrace = _graceDays;
    setState(() {
      if (autoApprove != null) _autoApprove = autoApprove;
      if (graceDays != null) _graceDays = graceDays;
    });
    try {
      await _api.patch(ApiUrl.pengaturanKebijakanOnboarding, {
        if (autoApprove != null) 'autoApproveTenant': autoApprove,
        if (graceDays != null) 'graceDaysPending': graceDays,
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _autoApprove = prevAuto;
        _graceDays = prevGrace;
      });
      _showError(e.message);
    }
  }

  // -------------------------------------------------------------------
  // Notifikasi
  // -------------------------------------------------------------------

  Future<void> _updateNotifikasi({
    bool? tenantBaru,
    bool? tagihan,
    bool? keamanan,
    bool? laporan,
  }) async {
    final prev = (_notifTenantBaru, _notifTagihan, _notifKeamanan, _notifLaporan);
    setState(() {
      if (tenantBaru != null) _notifTenantBaru = tenantBaru;
      if (tagihan != null) _notifTagihan = tagihan;
      if (keamanan != null) _notifKeamanan = keamanan;
      if (laporan != null) _notifLaporan = laporan;
    });
    try {
      await _api.patch(ApiUrl.pengaturanNotifikasi, {
        if (tenantBaru != null) 'notifTenantBaru': tenantBaru,
        if (tagihan != null) 'notifTagihan': tagihan,
        if (keamanan != null) 'notifKeamanan': keamanan,
        if (laporan != null) 'notifLaporanMingguan': laporan,
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _notifTenantBaru = prev.$1;
        _notifTagihan = prev.$2;
        _notifKeamanan = prev.$3;
        _notifLaporan = prev.$4;
      });
      _showError(e.message);
    }
  }

  // -------------------------------------------------------------------
  // Sub-admin
  // -------------------------------------------------------------------

  Future<void> _removeSubAdmin(int index) async {
    final admin = _subAdmins[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cabut Akses Sub-Admin?', style: PText.headlineSm),
        content: Text('Akses ${admin.nama} akan langsung dicabut dan tidak dapat dibatalkan.', style: PText.bodyMd),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: PText.labelMd.copyWith(color: PColors.inkSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: PColors.errorText),
            child: const Text('Cabut Akses', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _api.delete(ApiUrl.pengaturanSubAdminDelete(admin.id));
      if (!mounted) return;
      setState(() => _subAdmins.removeAt(index));
      AppToast.success(context, 'Akses ${admin.nama} telah dicabut');
    } on ApiException catch (e) {
      _showError(e.message);
    }
  }

  Future<void> _inviteSubAdmin() async {
    final namaCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String subRole = 'OPERASIONAL';
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: PColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Undang Sub-Admin Baru', style: PText.headlineSm),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: namaCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password Awal'),
                    validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: subRole,
                    decoration: const InputDecoration(labelText: 'Peran'),
                    items: const [
                      DropdownMenuItem(value: 'OPERASIONAL', child: Text('Admin Operasional')),
                      DropdownMenuItem(value: 'KEUANGAN', child: Text('Admin Keuangan & Billing')),
                    ],
                    onChanged: (v) => setDialogState(() => subRole = v ?? 'OPERASIONAL'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Batal', style: PText.labelMd.copyWith(color: PColors.inkSecondary)),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              style: FilledButton.styleFrom(backgroundColor: PColors.primary),
              child: const Text('Kirim Undangan'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    try {
      final res = await _api.post(ApiUrl.pengaturanSubAdmin, {
        'nama': namaCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'password': passwordCtrl.text,
        'subRole': subRole,
      }) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _subAdmins.insert(0, SubAdminData.fromJson(res)));
      AppToast.success(context, 'Sub-admin baru berhasil ditambahkan');
    } on ApiException catch (e) {
      _showError(e.message);
    }
  }

  // -------------------------------------------------------------------
  // Logout
  // -------------------------------------------------------------------

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar dari Akun Super Admin?', style: PText.headlineSm),
        content: Text(
          'Kamu perlu login kembali untuk mengakses kontrol panel platform.',
          style: PText.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: PText.labelMd.copyWith(color: PColors.inkSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AppScope.of(context).logout();
            },
            style: TextButton.styleFrom(foregroundColor: PColors.errorText),
            child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: PColors.primary));
    }
    if (_error != null) {
      return _LoadErrorState(message: _error!, onRetry: _load);
    }

    final user = AppScope.of(context).user;

    return RefreshIndicator(
      color: PColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const _ClusterStatusBanner(),
          const SizedBox(height: 14),
          const _PengaturanTitleRow(),
          const SizedBox(height: 14),
          _ProfileCard(
            nama: user?.nama ?? '-',
            email: user?.email ?? '-',
            onEditProfil: _editProfil,
            onUbahPassword: _ubahPassword,
          ),
          const SizedBox(height: 14),
          _OnboardingPolicyCard(
            autoApprove: _autoApprove,
            onAutoApproveChanged: (v) => _updateKebijakan(autoApprove: v),
            graceDays: _graceDays,
            onDecrement: () {
              if (_graceDays > 1) _updateKebijakan(graceDays: _graceDays - 1);
            },
            onIncrement: () {
              if (_graceDays < 90) _updateKebijakan(graceDays: _graceDays + 1);
            },
          ),
          const SizedBox(height: 14),
          _SubAdminCard(
            subAdmins: _subAdmins,
            onDelete: _removeSubAdmin,
            onInvite: _inviteSubAdmin,
          ),
          const SizedBox(height: 14),
          _NotificationCard(
            tenantBaru: _notifTenantBaru,
            onTenantBaruChanged: (v) => _updateNotifikasi(tenantBaru: v),
            tagihan: _notifTagihan,
            onTagihanChanged: (v) => _updateNotifikasi(tagihan: v),
            keamanan: _notifKeamanan,
            onKeamananChanged: (v) => _updateNotifikasi(keamanan: v),
            laporan: _notifLaporan,
            onLaporanChanged: (v) => _updateNotifikasi(laporan: v),
          ),
          const SizedBox(height: 14),
          const _AboutPlatformCard(),
          const SizedBox(height: 14),
          _LogoutButton(onPressed: _confirmLogout),
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
            const Icon(Icons.error_outline, color: PColors.errorText, size: 32),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: PText.bodyMd),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: PColors.primary),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Shared section card shell
// ============================================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0F3A2E), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: PColors.primary),
        const SizedBox(width: 6),
        Expanded(child: Text(title, style: PText.headlineSm)),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ============================================================================
// Cluster status banner
// ============================================================================

class _ClusterStatusBanner extends StatelessWidget {
  const _ClusterStatusBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: PColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_done_outlined, size: 16, color: PColors.inkSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Cluster ap-southeast-1 (Jakarta DC)',
              style: PText.bodySm,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: PColors.surface,
              borderRadius: BorderRadius.circular(9999),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(color: PColors.primary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text('SEMUA NODE SEHAT', style: PText.labelSm.copyWith(color: PColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Page title row
// ============================================================================

class _PengaturanTitleRow extends StatelessWidget {
  const _PengaturanTitleRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(child: Text('Pengaturan', style: PText.headlineLg)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: PColors.primary,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: const Text(
                'ROOT ACCESS',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text('Konfigurasi akun, kebijakan platform & tata kelola Super Admin', style: PText.bodyMd),
      ],
    );
  }
}

// ============================================================================
// SECTION 1 — Profil Saya
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

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: PColors.sage, shape: BoxShape.circle),
                    child: const Icon(Icons.person, color: PColors.primary, size: 32),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: PColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.verified_user, size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nama, style: PText.headlineSm),
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
                        Icon(Icons.mail_outline, size: 14, color: PColors.inkSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(email, style: PText.bodySm, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _GhostButton(icon: Icons.badge_outlined, label: 'Edit Profil', onPressed: onEditProfil),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _GhostButton(icon: Icons.lock_reset, label: 'Ubah Password', onPressed: onUbahPassword),
              ),
            ],
          ),
        ],
      ),
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
      color: PColors.surfaceDim,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: PColors.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label, style: PText.labelMd.copyWith(color: PColors.primary), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION 2 — Kebijakan Onboarding Tenant
// ============================================================================

class _OnboardingPolicyCard extends StatelessWidget {
  const _OnboardingPolicyCard({
    required this.autoApprove,
    required this.onAutoApproveChanged,
    required this.graceDays,
    required this.onDecrement,
    required this.onIncrement,
  });

  final bool autoApprove;
  final ValueChanged<bool> onAutoApproveChanged;
  final int graceDays;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(icon: Icons.apartment_outlined, title: 'Kebijakan Onboarding Tenant'),
          const SizedBox(height: 4),
          Text('Pengaturan penerimaan instansi pondok pesantren baru pada platform.', style: PText.bodySm),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: PColors.surfaceDim, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Auto-Approve Pendaftaran Tenant', style: PText.labelMd),
                          const SizedBox(height: 2),
                          Text(
                            autoApprove ? 'Status: Aktif' : 'Status: Nonaktif (Direkomendasikan)',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: PColors.goldDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SettingsToggle(value: autoApprove, onChanged: onAutoApproveChanged),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: PColors.surface.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Jika nonaktif, setiap pondok yang mendaftar via self-service wajib '
                    'divalidasi berkas legalitasnya secara manual oleh tim Super Admin '
                    'sebelum dapat beroperasi.',
                    style: PText.bodySm,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: PColors.surfaceDim, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Masa Tenggang Berkas Pending', style: PText.labelMd),
                const SizedBox(height: 2),
                Text(
                  'Batas waktu verifikasi sebelum pendaftaran otomatis dibatalkan sistem cron.',
                  style: PText.bodySm,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: PColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0F000000), blurRadius: 3, offset: Offset(0, 1)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StepperButton(icon: Icons.remove, onPressed: onDecrement),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$graceDays',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: PColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text('Hari Kalender', style: PText.labelMd.copyWith(color: PColors.inkSecondary)),
                        ],
                      ),
                      _StepperButton(icon: Icons.add, onPressed: onIncrement),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PColors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          child: Icon(icon, size: 19, color: PColors.primary),
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION 3 — Sub-Admin Platform
// ============================================================================

class _SubAdminCard extends StatelessWidget {
  const _SubAdminCard({required this.subAdmins, required this.onDelete, required this.onInvite});

  final List<SubAdminData> subAdmins;
  final ValueChanged<int> onDelete;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Sub-Admin Platform',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: PColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text('${subAdmins.length} Akun Aktif', style: PText.labelSm.copyWith(color: PColors.primary)),
            ),
          ),
          const SizedBox(height: 4),
          Text('Staf internal dengan izin operasional kontrol panel platform.', style: PText.bodySm),
          const SizedBox(height: 12),
          if (subAdmins.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: PColors.surfaceDim, borderRadius: BorderRadius.circular(12)),
              child: Text('Belum ada sub-admin platform.', style: PText.bodySm),
            )
          else
            ...List.generate(subAdmins.length, (i) {
              final s = subAdmins[i];
              final isKeuangan = s.roleType == 'KEUANGAN';
              return Padding(
                padding: EdgeInsets.only(bottom: i == subAdmins.length - 1 ? 0 : 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: PColors.surfaceDim, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isKeuangan ? PColors.goldDark : PColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          s.initials,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.nama, style: PText.labelMd.copyWith(color: PColors.primary), overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 1),
                            Text(s.email, style: PText.bodySm, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 2,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isKeuangan ? PColors.goldSurface : PColors.primaryFixed,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    s.roleLabel,
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isKeuangan ? PColors.goldDark : PColors.primary,
                                    ),
                                  ),
                                ),
                                Text('• ${s.tanggal}', style: PText.labelSm),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: PColors.errorBg,
                        borderRadius: BorderRadius.circular(9),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(9),
                          onTap: () => onDelete(i),
                          child: Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            child: const Icon(Icons.delete_outline, size: 17, color: PColors.errorText),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: PColors.primary,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onInvite,
                child: Container(
                  height: 46,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.person_add_alt_1, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        '+ Undang Sub-Admin Baru',
                        style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SECTION 4 — Notifikasi Platform
// ============================================================================

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.tenantBaru,
    required this.onTenantBaruChanged,
    required this.tagihan,
    required this.onTagihanChanged,
    required this.keamanan,
    required this.onKeamananChanged,
    required this.laporan,
    required this.onLaporanChanged,
  });

  final bool tenantBaru;
  final ValueChanged<bool> onTenantBaruChanged;
  final bool tagihan;
  final ValueChanged<bool> onTagihanChanged;
  final bool keamanan;
  final ValueChanged<bool> onKeamananChanged;
  final bool laporan;
  final ValueChanged<bool> onLaporanChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(icon: Icons.notifications_active_outlined, title: 'Notifikasi Platform'),
          const SizedBox(height: 4),
          Text('Konfigurasi saluran peringatan otomatis ke konsol ROOT.', style: PText.bodySm),
          const SizedBox(height: 12),
          _NotifToggleItem(
            title: 'Pendaftaran Tenant Baru',
            description: 'Pemberitahuan instan saat pondok mengajukan onboarding self-service.',
            value: tenantBaru,
            onChanged: onTenantBaruChanged,
          ),
          const SizedBox(height: 8),
          _NotifToggleItem(
            title: 'Tagihan Menunggak & Grace Period',
            description: 'Peringatan invoice jatuh tempo atau tenant yang memasuki masa penangguhan.',
            value: tagihan,
            onChanged: onTagihanChanged,
          ),
          const SizedBox(height: 8),
          _NotifToggleItem(
            title: 'Peringatan Keamanan & Brute Force',
            description: 'Deteksi login anomali, serangan credential stuffing, atau suspensi otomatis.',
            value: keamanan,
            onChanged: onKeamananChanged,
          ),
          const SizedBox(height: 8),
          _NotifToggleItem(
            title: 'Laporan Ringkasan Mingguan',
            description: 'Digest performa MRR, churn rate, dan pertumbuhan kuota storage mingguan.',
            value: laporan,
            onChanged: onLaporanChanged,
          ),
        ],
      ),
    );
  }
}

class _NotifToggleItem extends StatelessWidget {
  const _NotifToggleItem({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: PColors.surfaceDim, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: PText.labelMd.copyWith(color: PColors.primary)),
                const SizedBox(height: 2),
                Text(description, style: PText.bodySm),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _SettingsToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ============================================================================
// SECTION 5 — Tentang Platform
// ============================================================================

class _AboutPlatformCard extends StatelessWidget {
  const _AboutPlatformCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(icon: Icons.info_outline, title: 'Tentang Platform'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: PColors.surfaceDim, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _SpecRow(
                  label: 'Versi SIMPesantren',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: PColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('v4.2.0-cloud-enterprise', style: PText.mono),
                  ),
                ),
                const SizedBox(height: 8),
                const _SpecRow(label: 'Lingkungan Node', value: 'Production (ap-southeast-1)'),
                const SizedBox(height: 8),
                const _SpecRow(label: 'Engine Database', value: 'MySQL Multi-Tenant'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const _PolicyLinkRow(icon: Icons.shield_outlined, label: 'Kebijakan Privasi Platform'),
          const _PolicyLinkRow(icon: Icons.description_outlined, label: 'Syarat & Ketentuan Layanan (SLA)'),
          const _PolicyLinkRow(icon: Icons.history_edu_outlined, label: 'Changelog & Pembaruan Sistem'),
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, this.value, this.child});

  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: PText.bodySm),
        child ??
            Text(
              value ?? '-',
              style: PText.labelSm.copyWith(color: PColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
            ),
      ],
    );
  }
}

class _PolicyLinkRow extends StatelessWidget {
  const _PolicyLinkRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: PColors.inkSecondary),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: PText.labelMd.copyWith(color: PColors.primary))),
              Icon(Icons.chevron_right, size: 18, color: PColors.inkSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION 6 — Keluar
// ============================================================================

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: PColors.errorBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            height: 46,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.logout, size: 18, color: PColors.errorText),
                SizedBox(width: 8),
                Text(
                  'Keluar dari Akun Super Admin',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700, color: PColors.errorText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Reusable toggle switch (dipakai di section 2 & 4)
// ============================================================================

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        width: 46,
        height: 27,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? PColors.primary : PColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 23,
            height: 23,
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