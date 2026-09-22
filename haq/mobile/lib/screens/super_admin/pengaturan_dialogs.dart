// pengaturan_dialogs.dart
//
// Taruh di folder yang sama dengan pengaturan_screen.dart.
//
// Isi:
//  - AppToast            : notifikasi sukses / gagal (pengganti SnackBar polos)
//  - showEditProfilSheet : bottom sheet Edit Profil
//  - showUbahPasswordSheet : bottom sheet Ubah Password
//
// Error dari server (mis. "Password saat ini salah.") ditampilkan langsung
// di dalam sheet, jadi form tidak tertutup dan isian tidak hilang.

import 'package:flutter/material.dart';
import 'tenants_screen.dart' show PColors, PText;
import '../../services/api_client.dart' show ApiException;

// ============================================================================
// Toast
// ============================================================================

class AppToast {
  AppToast._();

  static void success(BuildContext context, String message) =>
      _show(context, message, isError: false);

  static void error(BuildContext context, String message) =>
      _show(context, message, isError: true);

  static void _show(BuildContext context, String message, {required bool isError}) {
    final messenger = ScaffoldMessenger.of(context);
    final width = MediaQuery.of(context).size.width;
    // Di layar lebar (web/tablet) toast dibatasi 480px dan ditaruh di tengah.
    final side = width > 512 ? (width - 480) / 2 : 16.0;

    final Color bg = isError ? PColors.errorBg : PColors.primary;
    final Color fg = isError ? PColors.errorText : Colors.white;
    final IconData icon =
        isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.fromLTRB(side, 0, side, 16),
          duration: Duration(seconds: isError ? 5 : 3),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: isError
                  ? Border.all(color: PColors.errorText.withOpacity(0.25))
                  : null,
              boxShadow: const [
                BoxShadow(color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: PText.labelMd.copyWith(color: fg, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

// ============================================================================
// Public API
// ============================================================================

/// Menampilkan sheet Edit Profil.
///
/// [onSubmit] dipanggil saat tombol simpan ditekan. Lempar exception
/// (mis. ApiException) kalau gagal: pesannya tampil di dalam sheet.
/// Mengembalikan `true` kalau tersimpan, `false`/`null` kalau dibatalkan
/// atau tidak ada yang berubah.
Future<bool?> showEditProfilSheet(
  BuildContext context, {
  required String nama,
  required String email,
  required Future<void> Function(String nama, String email) onSubmit,
}) {
  return _showSheet(
    context,
    (_) => _EditProfilSheet(nama: nama, email: email, onSubmit: onSubmit),
  );
}

/// Menampilkan sheet Ubah Password. Aturan sama seperti [showEditProfilSheet].
Future<bool?> showUbahPasswordSheet(
  BuildContext context, {
  required Future<void> Function(String passwordLama, String passwordBaru) onSubmit,
}) {
  return _showSheet(context, (_) => _UbahPasswordSheet(onSubmit: onSubmit));
}

Future<bool?> _showSheet(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: PColors.surface,
    barrierColor: const Color(0x66000000),
    constraints: const BoxConstraints(maxWidth: 480),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: builder,
  );
}

// ============================================================================
// Edit Profil
// ============================================================================

class _EditProfilSheet extends StatefulWidget {
  const _EditProfilSheet({
    required this.nama,
    required this.email,
    required this.onSubmit,
  });

  final String nama;
  final String email;
  final Future<void> Function(String nama, String email) onSubmit;

  @override
  State<_EditProfilSheet> createState() => _EditProfilSheetState();
}

class _EditProfilSheetState extends State<_EditProfilSheet> {
  late final TextEditingController _namaCtrl = TextEditingController(text: widget.nama);
  late final TextEditingController _emailCtrl = TextEditingController(text: widget.email);
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final nama = _namaCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    // Tidak ada perubahan: tutup saja, tidak perlu request.
    if (nama == widget.nama.trim() && email == widget.email.trim()) {
      Navigator.pop(context, false);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(nama, email);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e is ApiException
            ? e.message
            : 'Perubahan belum tersimpan. Periksa koneksi lalu coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      icon: Icons.badge_outlined,
      title: 'Edit profil',
      subtitle: 'Perbarui nama dan email akun Super Admin.',
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _namaCtrl,
              autofocus: true,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                label: 'Nama lengkap',
                icon: Icons.person_outline_rounded,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama lengkap wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              enabled: !_saving,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: _inputDecoration(
                label: 'Email',
                icon: Icons.mail_outline_rounded,
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'Email wajib diisi';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) {
                  return 'Format email belum benar';
                }
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _InlineError(message: _error!),
            ],
            const SizedBox(height: 20),
            _SheetActions(
              label: 'Simpan perubahan',
              saving: _saving,
              onSubmit: _submit,
              onCancel: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Ubah Password
// ============================================================================

class _UbahPasswordSheet extends StatefulWidget {
  const _UbahPasswordSheet({required this.onSubmit});

  final Future<void> Function(String passwordLama, String passwordBaru) onSubmit;

  @override
  State<_UbahPasswordSheet> createState() => _UbahPasswordSheetState();
}

class _UbahPasswordSheetState extends State<_UbahPasswordSheet> {
  final _lamaCtrl = TextEditingController();
  final _baruCtrl = TextEditingController();
  final _konfirmasiCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _lamaCtrl.dispose();
    _baruCtrl.dispose();
    _konfirmasiCtrl.dispose();
    super.dispose();
  }

  /// 0 = kosong, 1 = lemah ... 4 = sangat kuat.
  int get _score {
    final p = _baruCtrl.text;
    if (p.isEmpty) return 0;
    var s = 1;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) s++;
    if (RegExp(r'\d').hasMatch(p) || RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    return s;
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_lamaCtrl.text, _baruCtrl.text);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e is ApiException
            ? e.message
            : 'Password belum berubah. Periksa koneksi lalu coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      icon: Icons.lock_reset_rounded,
      title: 'Ubah password',
      subtitle: 'Gunakan password yang belum pernah kamu pakai di tempat lain.',
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PasswordField(
              controller: _lamaCtrl,
              label: 'Password saat ini',
              enabled: !_saving,
              autofocus: true,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Masukkan password saat ini' : null,
            ),
            const SizedBox(height: 12),
            _PasswordField(
              controller: _baruCtrl,
              label: 'Password baru',
              enabled: !_saving,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.length < 6) return 'Minimal 6 karakter';
                if (v == _lamaCtrl.text) return 'Harus berbeda dari password saat ini';
                return null;
              },
            ),
            _StrengthMeter(score: _score),
            const SizedBox(height: 12),
            _PasswordField(
              controller: _konfirmasiCtrl,
              label: 'Ulangi password baru',
              enabled: !_saving,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (v) =>
                  v != _baruCtrl.text ? 'Belum sama dengan password baru' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _InlineError(message: _error!),
            ],
            const SizedBox(height: 20),
            _SheetActions(
              label: 'Ubah password',
              saving: _saving,
              onSubmit: _submit,
              onCancel: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.validator,
    required this.textInputAction,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String> validator;
  final TextInputAction textInputAction;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      obscureText: _hidden,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      decoration: _inputDecoration(
        label: widget.label,
        icon: Icons.lock_outline_rounded,
        suffix: IconButton(
          tooltip: _hidden ? 'Tampilkan password' : 'Sembunyikan password',
          onPressed: () => setState(() => _hidden = !_hidden),
          icon: Icon(
            _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
            color: PColors.inkSecondary,
          ),
        ),
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    if (score == 0) return const SizedBox(height: 0);

    const labels = ['', 'Lemah', 'Cukup', 'Kuat', 'Sangat kuat'];
    final color = score <= 1
        ? PColors.errorText
        : score == 2
            ? PColors.goldDark
            : PColors.primary;

    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 2, right: 2),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: List.generate(4, (i) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
                    decoration: BoxDecoration(
                      color: i < score ? color : PColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 10),
          Text(labels[score], style: PText.labelSm.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ============================================================================
// Shared pieces
// ============================================================================

class _SheetShell extends StatelessWidget {
  const _SheetShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Naikkan isi sheet saat keyboard muncul.
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: PColors.sage, shape: BoxShape.circle),
                  child: Icon(icon, color: PColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: PText.headlineSm),
                      const SizedBox(height: 2),
                      Text(subtitle, style: PText.bodySm),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _SheetActions extends StatelessWidget {
  const _SheetActions({
    required this.label,
    required this.saving,
    required this.onSubmit,
    required this.onCancel,
  });

  final String label;
  final bool saving;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: TextButton(
              onPressed: saving ? null : onCancel,
              style: TextButton.styleFrom(
                backgroundColor: PColors.surfaceDim,
                foregroundColor: PColors.inkSecondary,
                shape: shape,
              ),
              child: Text('Batal', style: PText.labelMd.copyWith(color: PColors.inkSecondary)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: saving ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: PColors.primary,
                disabledBackgroundColor: PColors.primary.withOpacity(0.7),
                shape: shape,
              ),
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : Text(label, style: PText.labelMd.copyWith(color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PColors.errorBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: PColors.errorText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: PText.bodySm.copyWith(color: PColors.errorText)),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String label,
  required IconData icon,
  Widget? suffix,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    labelText: label,
    floatingLabelStyle: const TextStyle(color: PColors.primary, fontWeight: FontWeight.w700),
    prefixIcon: Icon(icon, size: 20, color: PColors.inkSecondary),
    suffixIcon: suffix,
    filled: true,
    fillColor: PColors.surfaceDim,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    border: border(Colors.transparent),
    enabledBorder: border(Colors.transparent),
    disabledBorder: border(Colors.transparent),
    focusedBorder: border(PColors.primary, 1.5),
    errorBorder: border(PColors.errorText),
    focusedErrorBorder: border(PColors.errorText, 1.5),
  );
}