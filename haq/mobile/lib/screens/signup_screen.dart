// signup_screen.dart
//
// Pastikan font "Nunito" sudah didaftarkan lewat package google_fonts
// (tidak perlu asset lokal), atau jika ingin embed manual, daftarkan
// di pubspec.yaml, contoh:
//
// flutter:
//   fonts:
//     - family: Nunito
//       fonts:
//         - asset: assets/fonts/Nunito-Regular.ttf
//         - asset: assets/fonts/Nunito-SemiBold.ttf
//           weight: 600
//         - asset: assets/fonts/Nunito-Bold.ttf
//           weight: 700

import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/app_scope.dart';

/// Design tokens diambil langsung dari DESIGN.md
/// (Islamic Academic & Kesantrian Experience).
class PColors {
  PColors._();

  // Primary — Deep Emerald Forest
  static const primary = Color(0xFF0F3A2E);
  static const primaryShade = Color(0xFF114232);
  static const primaryContainer = Color(0xFF1B4D3E);
  static const primaryGradientEnd = Color(0xFF164E3D);

  // Secondary — Antique Gold
  static const gold = Color(0xFFC5A059);
  static const goldSurface = Color(0xFFFAF5EC);
  static const goldBorder = Color(0xFFE7D2A7);

  // Tertiary / surface accents
  static const mint = Color(0xFFD2E4DC);
  static const sage = Color(0xFFE2ECE9);

  // Neutrals — warm ivory canvas
  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);

  // Ink
  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);

  // Borders
  static const border = Color(0xFFEAE6DC);
  static const inputBorder = Color(0xFFE2E8F0);

  // Status tokens
  static const successBg = Color(0xFFE8F5E9);
  static const successText = Color(0xFF1B5E20);
  static const successBorder = Color(0xFFC8E6C9);

  static const pendingBg = Color(0xFFFFF8E1);
  static const pendingText = Color(0xFFB78103);
  static const pendingBorder = Color(0xFFFFE082);

  static const errorBg = Color(0xFFFEE2E2);
  static const errorText = Color(0xFF991B1B);
  static const errorBorder = Color(0xFFFECACA);

  static const infoBg = Color(0xFFE0F2FE);
  static const infoText = Color(0xFF0369A1);
  static const infoBorder = Color(0xFFBAE6FD);
}

class PText {
  PText._();

  static const _jakarta = 'Nunito';
  static const _inter = 'Nunito';

  static const headlineLgMobile = TextStyle(
    fontFamily: _jakarta,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 28 / 22,
    letterSpacing: -0.01,
    color: PColors.ink,
  );

  static const headlineSm = TextStyle(
    fontFamily: _jakarta,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    color: PColors.ink,
  );

  static const bodyLg = TextStyle(
    fontFamily: _jakarta,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: PColors.ink,
  );

  static const bodyMd = TextStyle(
    fontFamily: _jakarta,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: PColors.inkSecondary,
  );

  static const bodySm = TextStyle(
    fontFamily: _jakarta,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 18 / 12,
    color: PColors.inkSecondary,
  );

  static const labelLg = TextStyle(
    fontFamily: _inter,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0.01,
    color: PColors.ink,
  );

  static const labelMd = TextStyle(
    fontFamily: _inter,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.02,
  );

  static const labelSm = TextStyle(
    fontFamily: _inter,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 14 / 10,
    letterSpacing: 0.04,
  );
}

const List<String> _kKarakteristikOptions = [
  'Tahfidz Quran',
  'Modern/Terpadu',
  'Salafiyah',
  'Salaf-Modern',
];

const List<String> _kStepTitles = [
  'Profil & Tenant',
  'Admin Awal',
  'Ringkasan & Konfirmasi',
];

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Step 1 — Profil Pondok & Kode Tenant
  final _nama = TextEditingController();
  final _alamat = TextEditingController();
  final _kode = TextEditingController();
  final _logo = TextEditingController();
  final Set<String> _karakteristik = {'Tahfidz Quran'};

  // Step 2 — Admin Awal
  final _adminNama = TextEditingController();
  final _adminEmail = TextEditingController();
  final _adminPassword = TextEditingController();

  int _step = 0;
  bool _loading = false;
  String? _error;
  String? _success;

  static const _slugPattern = r'^[a-z0-9]+(-[a-z0-9]+)*$';

  bool get _slugValid =>
      _kode.text.trim().isNotEmpty &&
      RegExp(_slugPattern).hasMatch(_kode.text.trim());

  String get _slugSlugified {
    final raw = _kode.text.trim().isEmpty ? 'kode-tenant' : _kode.text.trim();
    return raw;
  }

  bool _validateStep1() {
    if (_nama.text.trim().isEmpty) {
      setState(() => _error = 'Nama Pondok Pesantren wajib diisi.');
      return false;
    }
    if (_alamat.text.trim().isEmpty) {
      setState(() => _error = 'Alamat Lengkap & Wilayah wajib diisi.');
      return false;
    }
    if (!_slugValid) {
      setState(() => _error =
          'Kode Tenant wajib diisi (huruf kecil, angka, dan strip saja).');
      return false;
    }
    setState(() => _error = null);
    return true;
  }

  bool _validateStep2() {
    if (_adminNama.text.trim().isEmpty ||
        _adminEmail.text.trim().isEmpty ||
        _adminPassword.text.length < 6) {
      setState(() =>
          _error = 'Lengkapi semua kolom. Password minimal 6 karakter.');
      return false;
    }
    setState(() => _error = null);
    return true;
  }

  void _goNext() {
    if (_step == 0 && !_validateStep1()) return;
    if (_step == 1 && !_validateStep2()) return;
    if (_step < 2) {
      setState(() => _step += 1);
    } else {
      _submit();
    }
  }

  void _goBack() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else {
      setState(() {
        _error = null;
        _step -= 1;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      await api.postPublic(ApiUrl.tenantSignup, {
        'namaPondok': _nama.text.trim(),
        'kodeTenant': _kode.text.trim(),
        'logoUrl': _logo.text.trim().isEmpty ? null : _logo.text.trim(),
        'adminNama': _adminNama.text.trim(),
        'adminEmail': _adminEmail.text.trim(),
        'adminPassword': _adminPassword.text,
        // TODO: tambahkan ke DTO backend bila field ini sudah didukung:
        'alamat': _alamat.text.trim(),
        'karakteristik': _karakteristik.toList(),
      });
      setState(() {
        _success = 'Pendaftaran berhasil. Menunggu persetujuan Super Admin.';
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Gagal mendaftar. Coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _alamat.dispose();
    _kode.dispose();
    _logo.dispose();
    _adminNama.dispose();
    _adminEmail.dispose();
    _adminPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SafeArea(
            child: Column(
              children: [
                _Header(step: _step, onBack: _goBack),
                _ProgressBar(step: _step),
                _StepIndicator(step: _step),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StepIntroCard(step: _step),
                        const SizedBox(height: 16),
                        if (_step == 0) _buildStep1(),
                        if (_step == 1) _buildStep2(),
                        if (_step == 2) _buildStep3(),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          _MessageBanner(
                            text: _error!,
                            bg: PColors.errorBg,
                            text_: PColors.errorText,
                            border: PColors.errorBorder,
                          ),
                        ],
                        if (_success != null) ...[
                          const SizedBox(height: 16),
                          _MessageBanner(
                            text: _success!,
                            bg: PColors.successBg,
                            text_: PColors.successText,
                            border: PColors.successBorder,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                _BottomBar(
                  step: _step,
                  loading: _loading,
                  disabled: _success != null,
                  onPressed: _goNext,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // STEP 1 — Profil Pondok & Kode Tenant
  // ---------------------------------------------------------------------
  Widget _buildStep1() {
    return _Card(
      children: [
        _FieldLabel('Nama Pondok Pesantren', required: true),
        const SizedBox(height: 8),
        _PInput(
          controller: _nama,
          hint: 'Contoh: Pondok Pesantren Tahfidz Darul Hikmah',
        ),
        const SizedBox(height: 6),
        Text(
          'Gunakan nama resmi yang tercantum di izin operasional Kemenag.',
          style: PText.bodySm,
        ),
        const SizedBox(height: 20),
        _FieldLabel('Alamat Lengkap & Wilayah', required: true),
        const SizedBox(height: 8),
        _PInput(
          controller: _alamat,
          hint: 'Jl. Pesantren No. 12, Cisarua, Bogor, Jawa Barat',
          maxLines: 2,
        ),
        const SizedBox(height: 20),
        Text('Karakteristik & Kurikulum Utama', style: PText.labelLg),
        const SizedBox(height: 10),
        _KarakteristikGrid(
          selected: _karakteristik,
          onToggle: (value) => setState(() {
            if (_karakteristik.contains(value)) {
              _karakteristik.remove(value);
            } else {
              _karakteristik.add(value);
            }
          }),
        ),
        const SizedBox(height: 20),
        Text('Lambang / Logo Resmi Pondok', style: PText.labelLg),
        const SizedBox(height: 10),
        _LogoUploadBox(controller: _logo),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _FieldLabel('Kode Tenant & Subdomain Slug', required: true)),
            Text('Huruf kecil, angka, strip', style: PText.bodySm),
          ],
        ),
        const SizedBox(height: 8),
        _PInput(
          controller: _kode,
          hint: 'mahad-alquran',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        if (_kode.text.trim().isNotEmpty)
          _AvailabilityPill(available: _slugValid, slug: _slugSlugified),
        const SizedBox(height: 8),
        Text(
          'Kode unik ini digunakan untuk subdomain portal web dan identifikasi '
          'saat login di aplikasi mobile (APK).',
          style: PText.bodySm,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // STEP 2 — Admin Awal
  // ---------------------------------------------------------------------
  Widget _buildStep2() {
    return _Card(
      children: [
        _FieldLabel('Nama Admin Awal', required: true),
        const SizedBox(height: 8),
        _PInput(controller: _adminNama, hint: 'Nama lengkap admin', icon: Icons.person_outline),
        const SizedBox(height: 20),
        _FieldLabel('Email Admin', required: true),
        const SizedBox(height: 8),
        _PInput(
          controller: _adminEmail,
          hint: 'admin@pondok.sch.id',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _FieldLabel('Password Admin', required: true),
        const SizedBox(height: 8),
        _PInput(
          controller: _adminPassword,
          hint: 'Minimal 6 karakter',
          icon: Icons.lock_outline,
          obscureText: true,
        ),
        const SizedBox(height: 6),
        Text(
          'Akun ini akan menjadi Admin pertama yang mengelola data pondok setelah disetujui.',
          style: PText.bodySm,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // STEP 3 — Ringkasan & Konfirmasi
  // ---------------------------------------------------------------------
  Widget _buildStep3() {
    return _Card(
      children: [
        Text('Profil Pondok', style: PText.labelLg),
        const SizedBox(height: 10),
        _SummaryRow('Nama Pondok', _nama.text.trim()),
        _SummaryRow('Alamat', _alamat.text.trim()),
        _SummaryRow('Karakteristik', _karakteristik.join(', ')),
        _SummaryRow('Kode Tenant', _kode.text.trim()),
        const SizedBox(height: 16),
        Divider(color: PColors.border, height: 1),
        const SizedBox(height: 16),
        Text('Admin Awal', style: PText.labelLg),
        const SizedBox(height: 10),
        _SummaryRow('Nama Admin', _adminNama.text.trim()),
        _SummaryRow('Email Admin', _adminEmail.text.trim()),
        _SummaryRow('Password', '•' * _adminPassword.text.length),
        const SizedBox(height: 16),
        _MessageBanner(
          text:
              'Pastikan seluruh data sudah benar. Setelah didaftarkan, permohonan '
              'akan menunggu persetujuan Super Admin.',
          bg: PColors.pendingBg,
          text_: PColors.pendingText,
          border: PColors.pendingBorder,
        ),
      ],
    );
  }
}

// ===========================================================================
// Shared building blocks
// ===========================================================================

class _Header extends StatelessWidget {
  const _Header({required this.step, required this.onBack});

  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.chevron_left, color: PColors.ink, size: 26),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIMPesantren',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.01,
                    color: PColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Informasi Institusi', style: PText.bodySm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: PColors.mint,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: const Text(
                        'Registrasi Tenant Baru',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: PColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.help_outline, color: PColors.inkSecondary, size: 22),
          ),
          const SizedBox(width: 6),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: PColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final fraction = (step + 1) / _kStepTitles.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9999),
        child: LinearProgressIndicator(
          value: fraction,
          minHeight: 4,
          backgroundColor: PColors.surfaceDim,
          valueColor: const AlwaysStoppedAnimation(PColors.primary),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: List.generate(_kStepTitles.length * 2 - 1, (i) {
          if (i.isOdd) {
            final leftDone = (i - 1) ~/ 2 < step;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: leftDone ? PColors.primary : PColors.border,
              ),
            );
          }
          final idx = i ~/ 2;
          final active = idx == step;
          final done = idx < step;
          return Column(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (active || done) ? PColors.primary : PColors.surfaceDim,
                  shape: BoxShape.circle,
                ),
                child: done
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${idx + 1}',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: active ? Colors.white : PColors.inkSecondary,
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 76,
                child: Text(
                  _kStepTitles[idx],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active ? PColors.ink : PColors.inkSecondary,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _StepIntroCard extends StatelessWidget {
  const _StepIntroCard({required this.step});

  final int step;

  static const _icons = [Icons.apartment, Icons.badge_outlined, Icons.fact_check_outlined];
  static const _descriptions = [
    'Lengkapi identitas resmi lembaga pondok pesantren untuk database registrasi nasional SIMPesantren.',
    'Buat akun Admin pertama yang akan mengelola data pondok setelah pendaftaran disetujui.',
    'Periksa kembali seluruh data sebelum mengirimkan permohonan pendaftaran tenant.',
  ];

  @override
  Widget build(BuildContext context) {
    return _Card(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: PColors.sage,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icons[step], color: PColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Langkah ${step + 1} dari 3: ${_stepHeadline(step)}',
                style: PText.headlineSm,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(_descriptions[step], style: PText.bodyMd),
      ],
    );
  }

  String _stepHeadline(int step) {
    switch (step) {
      case 0:
        return 'Profil Pondok & Kode Tenant';
      case 1:
        return 'Data Admin Awal';
      default:
        return 'Ringkasan & Konfirmasi';
    }
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: PText.labelLg,
        children: [
          TextSpan(text: label),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: PColors.errorText),
            ),
        ],
      ),
    );
  }
}

class _PInput extends StatelessWidget {
  const _PInput({
    required this.controller,
    this.hint,
    this.icon,
    this.maxLines = 1,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final int maxLines;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: obscureText ? 1 : maxLines,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: PText.bodyMd.copyWith(color: PColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: PText.bodyMd,
        prefixIcon: icon == null ? null : Icon(icon, color: PColors.inkSecondary, size: 20),
        filled: true,
        fillColor: PColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

class _KarakteristikGrid extends StatelessWidget {
  const _KarakteristikGrid({required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  static const _icons = {
    'Tahfidz Quran': Icons.menu_book_outlined,
    'Modern/Terpadu': Icons.school_outlined,
    'Salafiyah': Icons.import_contacts_outlined,
    'Salaf-Modern': Icons.balance_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _kKarakteristikOptions.map((option) {
        final isSelected = selected.contains(option);
        return GestureDetector(
          onTap: () => onToggle(option),
          child: Container(
            width: (MediaQuery.of(context).size.width - 32 - 42) / 2,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? PColors.primary : PColors.surfaceDim,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? PColors.primary : PColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _icons[option],
                  size: 18,
                  color: isSelected ? Colors.white : PColors.inkSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : PColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LogoUploadBox extends StatelessWidget {
  const _LogoUploadBox({required this.controller});

  final TextEditingController controller;

  Future<void> _pickLogo(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final tempController = TextEditingController(text: controller.text);
        return AlertDialog(
          backgroundColor: PColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('URL Logo Pondok', style: PText.headlineSm),
          content: _PInput(
            controller: tempController,
            hint: 'https://...',
            icon: Icons.image_outlined,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(foregroundColor: PColors.inkSecondary),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, tempController.text),
              style: FilledButton.styleFrom(
                backgroundColor: PColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
    if (result != null) controller.text = result;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasLogo = value.text.trim().isNotEmpty;
        return GestureDetector(
          onTap: () => _pickLogo(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: PColors.surfaceDim,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: PColors.border,
                width: 1.2,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: PColors.sage,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_upload_outlined, color: PColors.primary),
                ),
                const SizedBox(height: 12),
                Text('Klik untuk unggah logo pondok', style: PText.labelLg.copyWith(color: PColors.primary)),
                const SizedBox(height: 4),
                Text('PNG atau JPG transparan (maks. 2MB)', style: PText.bodySm, textAlign: TextAlign.center),
                const SizedBox(height: 10),
                if (hasLogo)
                  _Pill(
                    icon: Icons.check_circle,
                    label: 'Logo Kustom Siap',
                    bg: PColors.successBg,
                    fg: PColors.successText,
                  )
                else
                  _Pill(
                    icon: Icons.verified_outlined,
                    label: 'Logo Standar Sistem Siap',
                    bg: PColors.surface,
                    fg: PColors.inkSecondary,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.available, required this.slug});

  final bool available;
  final String slug;

  @override
  Widget build(BuildContext context) {
    if (available) {
      return _Pill(
        icon: Icons.check,
        label: 'Tersedia ($slug siap didaftarkan)',
        bg: PColors.successBg,
        fg: PColors.successText,
        fullWidth: true,
      );
    }
    return _Pill(
      icon: Icons.error_outline,
      label: 'Hanya huruf kecil, angka, dan strip yang diperbolehkan',
      bg: PColors.errorBg,
      fg: PColors.errorText,
      fullWidth: true,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9999)),
      child: content,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: PText.bodySm)),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: PText.bodyMd.copyWith(color: PColors.ink, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.text,
    required this.bg,
    required this.text_,
    required this.border,
  });

  final String text;
  final Color bg;
  final Color text_;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(text, style: PText.bodyMd.copyWith(color: text_)),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.step,
    required this.loading,
    required this.disabled,
    required this.onPressed,
  });

  final int step;
  final bool loading;
  final bool disabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final labels = [
      'Daftarkan Pondok',
      'Daftarkan Pondok',
      'Daftarkan Pondok',
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: PColors.background,
        border: Border(top: BorderSide(color: PColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: PColors.primary,
            disabledBackgroundColor: PColors.primary.withOpacity(0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
          ),
          onPressed: (loading || disabled) ? null : onPressed,
          child: loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      labels[step],
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: PColors.gold,
                      ),
                    ),
                    if (step < 2) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18, color: PColors.gold),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}