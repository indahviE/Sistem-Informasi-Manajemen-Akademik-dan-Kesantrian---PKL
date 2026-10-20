// pengaturan_mudir_screen.dart
//
// Pengaturan — Mudir (hanya notifikasi).
//
// Tidak punya Scaffold/AppBar sendiri, nempel di dalam ShellScreen
// (header + bottom nav dibawa shell).
//
// Warna utama mengikuti tema pondok (SC.primary dkk). Supaya tampilan ikut
// berubah saat tema diganti, widget yang memakai warna tema TIDAK dibuat
// const di titik pemanggilan.
//
// Data dari backend:
//   GET   /pengaturan/mudir
//   PATCH /pengaturan/mudir/notifikasi
//
// Bentuk response GET /pengaturan/mudir (yang dipakai layar ini):
//   {
//     notifikasi: { ringkasanHarian, laporanKesantrian, pendaftaranBaru, laporanKeuangan }
//   }

import 'package:flutter/material.dart';
import 'package:sim_pesantren/services/api_client.dart';
import 'package:sim_pesantren/services/app_scope.dart';
import 'package:sim_pesantren/screens/santri/santri_ui.dart';
import 'package:sim_pesantren/screens/mudir/pengaturan_mudir_dialogs.dart';

// ============================================================================
// Token warna lokal (private). Yang berbasis SC.* mengikuti tema pondok.
// ============================================================================

class _PM {
  // Dinamis: ikut tema pondok.
  static Color get primary => SC.primary;
  static Color get sage => SC.sage;

  static const background = Color(0xFFFAF9F5);
  static const surface = Colors.white;
  static const surfaceDim = Color(0xFFF5F4EE);
  static const line = Color(0xFFEAE6DC);
  static const inkSecondary = Color(0xFF475569);
  static const errorBg = Color(0xFFFEE2E2);
  static const errorText = Color(0xFF991B1B);
}

TextStyle _t(double size, FontWeight w, Color c, {double? height}) =>
    TextStyle(fontFamily: 'Nunito', fontSize: size, fontWeight: w, color: c, height: height);

// Toggle notifikasi mudir (key = nama field di backend / UserNotifSetting).
const List<({String key, String title, String desc})> _notifItems = [
  (
    key: 'ringkasanHarian',
    title: 'Ringkasan Harian',
    desc: 'Rekap singkat kehadiran santri dan aktivitas pondok setiap hari',
  ),
  (
    key: 'laporanKesantrian',
    title: 'Laporan Kesantrian',
    desc: 'Kabar pelanggaran, perizinan, dan kasus santri yang perlu perhatian',
  ),
  (
    key: 'pendaftaranBaru',
    title: 'Pendaftaran Santri Baru',
    desc: 'Pemberitahuan saat ada pendaftar PPDB baru atau berkas masuk',
  ),
  (
    key: 'laporanKeuangan',
    title: 'Ringkasan Keuangan',
    desc: 'Rekap pembayaran dan tunggakan yang perlu Anda pantau',
  ),
];

IconData _notifIcon(String key) {
  switch (key) {
    case 'ringkasanHarian':
      return Icons.today_outlined;
    case 'laporanKesantrian':
      return Icons.shield_outlined;
    case 'pendaftaranBaru':
      return Icons.person_add_alt_outlined;
    case 'laporanKeuangan':
      return Icons.account_balance_wallet_outlined;
    default:
      return Icons.notifications_none;
  }
}

// ============================================================================
// Screen
// ============================================================================

class PengaturanMudirScreen extends StatefulWidget {
  const PengaturanMudirScreen({super.key});

  @override
  State<PengaturanMudirScreen> createState() => _PengaturanMudirScreenState();
}

class _PengaturanMudirScreenState extends State<PengaturanMudirScreen> {
  bool _loading = true;
  bool _initialized = false;
  String? _error;

  final Map<String, bool> _notif = {for (final n in _notifItems) n.key: true};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  ApiClient get _api => AppScope.of(context).api;

  String get _urlMudir => '${ApiUrl.pengaturan}/mudir';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get(_urlMudir) as Map<String, dynamic>;
      final notif = res['notifikasi'] as Map<String, dynamic>? ?? {};
      if (!mounted) return;
      setState(() {
        for (final n in _notifItems) {
          final v = notif[n.key];
          if (v is bool) _notif[n.key] = v;
        }
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

  // ------------------------------------------------------------- notifikasi
  // Optimistic update, rollback kalau gagal.

  Future<void> _toggleNotif(String key, bool value) async {
    final prev = _notif[key] ?? true;
    setState(() => _notif[key] = value);
    try {
      await _api.patch('$_urlMudir/notifikasi', {key: value});
    } catch (e) {
      if (!mounted) return;
      setState(() => _notif[key] = prev);
      _showError(e is ApiException ? e.message : 'Gagal menyimpan pengaturan notifikasi');
    }
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _PM.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: _PM.primary));
    }
    if (_error != null) {
      return _LoadErrorState(message: _error!, onRetry: _load);
    }

    // CATATAN: sengaja tanpa `const` supaya widget ikut rebuild saat tema
    // pondok berubah (widget const dilewati oleh Flutter saat rebuild).
    return RefreshIndicator(
      color: _PM.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _Reveal(index: 0, child: _TitleRow()),
          const SizedBox(height: 16),
          _Reveal(index: 1, child: _NotifCard(values: _notif, onChanged: _toggleNotif)),
        ],
      ),
    );
  }
}

// ============================================================================
// Animasi masuk
// ============================================================================

class _Reveal extends StatelessWidget {
  const _Reveal({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 16), child: c),
      ),
      child: child,
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
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: _PM.errorBg, shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off_rounded, color: _PM.errorText, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: _t(13, FontWeight.w500, _PM.inkSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              style: FilledButton.styleFrom(
                backgroundColor: _PM.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Shared
// ============================================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _PM.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _PM.line.withOpacity(0.7)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F0F3A2E), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title, this.subtitle, this.trailing});

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: _PM.sage, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: _PM.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _t(15.5, FontWeight.w800, _PM.primary, height: 1.2)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: _t(11.5, FontWeight.w500, _PM.inkSecondary, height: 1.3)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 50,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? _PM.primary : const Color(0xFFDAD8CF),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1))],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: value
                  ? Icon(Icons.check_rounded, key: const ValueKey('on'), size: 15, color: _PM.primary)
                  : const SizedBox.shrink(key: ValueKey('off')),
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  // Konstruktor const dipertahankan, tapi pemanggilnya tidak memakai `const`.
  const _TitleRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pengaturan', style: _t(21, FontWeight.w800, _PM.primary, height: 1.15)),
        const SizedBox(height: 2),
        Text(
          'Notifikasi Mudir',
          overflow: TextOverflow.ellipsis,
          style: _t(12, FontWeight.w500, _PM.inkSecondary),
        ),
      ],
    );
  }
}

// ============================================================================
// Notifikasi
// ============================================================================

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.values, required this.onChanged});

  final Map<String, bool> values;
  final void Function(String key, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final aktifCount = _notifItems.where((n) => values[n.key] ?? true).length;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.notifications_none_rounded,
            title: 'Notifikasi & Laporan',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: _PM.surfaceDim,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: _PM.line),
              ),
              child: Text('$aktifCount/${_notifItems.length}',
                  style: _t(11, FontWeight.w800, _PM.primary)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pilih ringkasan dan kabar pondok yang ingin Anda terima.',
            style: _t(12, FontWeight.w500, _PM.inkSecondary, height: 1.4),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _notifItems.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _PM.line),
            _NotifRow(
              icon: _notifIcon(_notifItems[i].key),
              title: _notifItems[i].title,
              desc: _notifItems[i].desc,
              value: values[_notifItems[i].key] ?? true,
              onChanged: (v) => onChanged(_notifItems[i].key, v),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotifRow extends StatelessWidget {
  const _NotifRow({
    required this.icon,
    required this.title,
    required this.desc,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String desc;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: value ? _PM.sage : _PM.surfaceDim,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 19, color: value ? _PM.primary : _PM.inkSecondary.withOpacity(0.7)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _t(13, FontWeight.w800, _PM.primary, height: 1.25)),
                const SizedBox(height: 2),
                Text(desc, style: _t(11.5, FontWeight.w500, _PM.inkSecondary, height: 1.35)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Toggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}