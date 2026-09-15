import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/app_scope.dart';
import 'signup_screen.dart'; // reuse PColors, PText, dan navigasi ke SignupScreen
import 'ppdb/ppdb_form_screen.dart';

// ============================================================================
// Data models (lokal untuk layar ini)
// ============================================================================

/// Preview info tenant yang tampil di header login.
/// TODO: ganti dengan hasil lookup API berdasarkan subdomain/kode tenant
/// (mis. GET /api/tenants/lookup?slug=...) sebelum form ini ditampilkan.
class _TenantPreview {
  const _TenantPreview({
    required this.namaPondok,
    required this.subdomain,
    required this.tahunAjaran,
    required this.semester,
  });

  final String namaPondok;
  final String subdomain;
  final String tahunAjaran;
  final String semester;
}

class _RoleOption {
  const _RoleOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
}

const List<_RoleOption> _kRoleOptions = [
  _RoleOption(
    id: 'admin',
    label: 'Admin Pondok',
    subtitle: 'Sekretariat & TU',
    icon: Icons.manage_accounts_outlined,
  ),
  _RoleOption(
    id: 'ustadz',
    label: 'Ustadz / Guru',
    subtitle: 'Akademik & Halaqah',
    icon: Icons.auto_stories_outlined,
  ),
  _RoleOption(
    id: 'musyrif',
    label: 'Musyrif Asrama',
    subtitle: 'Disiplin & Asrama',
    icon: Icons.hotel_outlined,
  ),
  _RoleOption(
    id: 'mudir',
    label: 'Pimpinan / Mudir',
    subtitle: 'Kebijakan & Monev',
    icon: Icons.account_balance_outlined,
  ),
  _RoleOption(
    id: 'wali',
    label: 'Wali Santri',
    subtitle: 'Pantau Nilai & Syahriah',
    icon: Icons.family_restroom_outlined,
  ),
  _RoleOption(
    id: 'santri',
    label: 'Santri',
    subtitle: "Jadwal & Mutaba'ah",
    icon: Icons.school_outlined,
  ),
];

// ============================================================================
// LandingScreen
// ============================================================================

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  // TODO: isi dari hasil deteksi subdomain / lookup API tenant
  final _tenant = const _TenantPreview(
    namaPondok: 'HAQ',
    subdomain: 'Halaqoh, Akademik dan Quran',
    tahunAjaran: '1445-1446 H',
    semester: 'Semester Genap',
  );

  String _selectedRole = 'ustadz';

  final _kodeTenant = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _kodeTenant.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Email dan kata sandi wajib diisi.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = AppScope.of(context);
      await auth.login(
          _kodeTenant.text.trim(), _email.text.trim(), _password.text);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Gagal masuk. Coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedRole = _kRoleOptions.firstWhere((r) => r.id == _selectedRole);
    return Scaffold(
      backgroundColor: PColors.background,
      body: SafeArea(
        child: Center(
          // Batasi lebar maksimum supaya di web pun tampilannya tetap
          // proporsional seperti mobile — sama seperti pola di SignupScreen.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TenantHeaderCard(tenant: _tenant),
                  const SizedBox(height: 16),
                  _RoleSelectorCard(
                    selectedId: _selectedRole,
                    onSelect: (id) => setState(() => _selectedRole = id),
                  ),
                  const SizedBox(height: 16),
                  _LoginFormCard(
                    tenant: _tenant,
                    roleLabel: selectedRole.label,
                    kodeTenantController: _kodeTenant,
                    emailController: _email,
                    passwordController: _password,
                    obscure: _obscure,
                    onToggleObscure: () => setState(() => _obscure = !_obscure),
                    rememberMe: _rememberMe,
                    onToggleRemember: (v) =>
                        setState(() => _rememberMe = v ?? true),
                    loading: _loading,
                    error: _error,
                    onSubmit: _submit,
                  ),
                  const SizedBox(height: 16),
                  _FooterLink(
                    icon: Icons.apartment_outlined,
                    title: 'Belum terdaftar sebagai pondok?',
                    subtitle: 'Daftarkan Pondok Baru Secara Mandiri',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _FooterLink(
                    icon: Icons.app_registration_outlined,
                    title: 'Calon santri baru?',
                    subtitle: 'Isi Formulir & Tes PPDB Online',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PpdbFormScreen()),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _FooterBrand(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 1. Header kartu tenant
// ============================================================================

class _TenantHeaderCard extends StatelessWidget {
  const _TenantHeaderCard({required this.tenant});

  final _TenantPreview tenant;

  @override
  Widget build(BuildContext context) {
    return _LCard(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [PColors.primary, PColors.primaryGradientEnd],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.menu_book_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'PLATFORM SIM PESANTREN',
                        style: PText.labelMd.copyWith(color: PColors.primary),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: PColors.successText,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tenant.namaPondok,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PText.headlineSm,
                  ),
                  const SizedBox(height: 2),
                  Text(tenant.subdomain, style: PText.bodySm),
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
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 15, color: PColors.inkSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${tenant.tahunAjaran} • ${tenant.semester}',
                  style: PText.bodySm,
                ),
              ),
              _LPill(
                icon: Icons.circle,
                iconSize: 8,
                label: 'AKTIF',
                bg: PColors.successBg,
                fg: PColors.successText,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 2. Pilihan peran / hak akses
// ============================================================================

class _RoleSelectorCard extends StatelessWidget {
  const _RoleSelectorCard({required this.selectedId, required this.onSelect});

  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return _LCard(
      children: [
        Row(
          children: [
            Text('Pilih Hak Akses Akun', style: PText.labelLg),
            const Spacer(),
            Text('${_kRoleOptions.length} Peran Pondok', style: PText.bodySm),
          ],
        ),
        const SizedBox(height: 12),
        // LayoutBuilder dipakai supaya lebar kartu dihitung dari lebar
        // KOLOM yang tersedia (constraints.maxWidth), bukan lebar layar
        // penuh (MediaQuery.size.width) — ini yang bikin kartu "kebesaran"
        // dan meluber saat dijalankan di web/desktop.
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 10.0;
            final itemWidth = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: _kRoleOptions.map((role) {
                final selected = role.id == selectedId;
                return SizedBox(
                  width: itemWidth,
                  child: _RoleTile(
                    role: role,
                    selected: selected,
                    onTap: () => onSelect(role.id),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final _RoleOption role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? PColors.primary : PColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? PColors.primary : PColors.border,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withOpacity(0.16)
                        : PColors.sage,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    role.icon,
                    size: 19,
                    color: selected ? Colors.white : PColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  role.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : PColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: selected
                        ? Colors.white.withOpacity(0.8)
                        : PColors.inkSecondary,
                  ),
                ),
              ],
            ),
            if (selected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: PColors.primary, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. Form login
// ============================================================================

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard({
    required this.tenant,
    required this.roleLabel,
    required this.kodeTenantController,
    required this.emailController,
    required this.passwordController,
    required this.obscure,
    required this.onToggleObscure,
    required this.rememberMe,
    required this.onToggleRemember,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  final _TenantPreview tenant;
  final String roleLabel;
  final TextEditingController kodeTenantController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool rememberMe;
  final ValueChanged<bool?> onToggleRemember;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return _LCard(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: PColors.sage,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.login, size: 18, color: PColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Masuk ke Portal', style: PText.headlineSm),
            ),
            _LPill(
              icon: Icons.workspace_premium_outlined,
              label: 'Akses Mandiri',
              bg: PColors.goldSurface,
              fg: PColors.gold,
            ),
          ],
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: PText.bodyMd,
            children: [
              const TextSpan(text: 'Masuk sebagai '),
              TextSpan(
                text: roleLabel,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: PColors.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PColors.successBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PColors.successBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle, size: 18, color: PColors.successText),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Subdomain Terdeteksi Otomatis',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: PColors.successText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: PColors.successText,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${tenant.subdomain} • Basis data pondok telah terhubung langsung.',
                      style: PText.bodySm,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Kode Tenant', style: PText.labelLg),
        const SizedBox(height: 8),
        _LInput(
          controller: kodeTenantController,
          hint: 'mahad-alquran',
          icon: Icons.apartment_outlined,
        ),
        const SizedBox(height: 6),
        Text(
          'Untuk Super Admin, biarkan Kode Tenant kosong.',
          style: PText.bodySm,
        ),
        const SizedBox(height: 16),
        Text('Alamat Email Terdaftar', style: PText.labelLg),
        const SizedBox(height: 8),
        _LInput(
          controller: emailController,
          hint: 'nama@pesantren.id',
          icon: Icons.alternate_email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        Text('Kata Sandi', style: PText.labelLg),
        const SizedBox(height: 8),
        _LInput(
          controller: passwordController,
          hint: '••••••••••••',
          icon: Icons.lock_outline,
          obscureText: obscure,
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: PColors.inkSecondary,
            ),
            onPressed: onToggleObscure,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: rememberMe,
                onChanged: onToggleRemember,
                activeColor: PColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Ingat saya di perangkat ini', style: PText.bodySm),
            ),
            GestureDetector(
              onTap: () {
                // TODO: arahkan ke kontak sekretariat / halaman lupa sandi
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.support_agent_outlined,
                      size: 14, color: PColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Lupa kata sandi?',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: PColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PColors.errorBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PColors.errorBorder),
            ),
            child: Text(
              error!,
              textAlign: TextAlign.center,
              style: PText.bodyMd.copyWith(color: PColors.errorText),
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: PColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999)),
            ),
            onPressed: loading ? null : onSubmit,
            child: loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Masuk ke Sistem Portal',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: PColors.gold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18, color: PColors.gold),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 4. Footer links & brand
// ============================================================================

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: PColors.sage,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: PColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: PText.labelLg),
                  const SizedBox(height: 2),
                  Text(subtitle, style: PText.bodySm),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: PColors.inkSecondary),
          ],
        ),
      ),
    );
  }
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user_outlined,
                size: 14, color: PColors.inkSecondary),
            const SizedBox(width: 6),
            Text('SIMPesantren Multi-Tenant Enterprise v2.4',
                style: PText.bodySm),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Menegakkan Adab, Menyempurnakan Amanah Ilmiah',
          style: PText.bodySm.copyWith(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

// ============================================================================
// Shared low-level widgets (replika style dari signup_screen.dart,
// dibuat lokal karena _Card/_PInput/_Pill di signup bersifat privat file)
// ============================================================================

class _LCard extends StatelessWidget {
  const _LCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _LInput extends StatelessWidget {
  const _LInput({
    required this.controller,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: PText.bodyMd.copyWith(color: PColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: PText.bodyMd,
        prefixIcon: icon == null
            ? null
            : Icon(icon, color: PColors.inkSecondary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: PColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PColors.primary, width: 2),
        ),
      ),
    );
  }
}

class _LPill extends StatelessWidget {
  const _LPill({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    this.iconSize = 14,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}