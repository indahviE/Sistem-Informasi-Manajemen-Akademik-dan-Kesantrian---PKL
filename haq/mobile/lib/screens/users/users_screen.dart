import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart';

/// Palet sama dengan dashboard wali & absensi.
class _UC {
  _UC._();

  static Color get primary => SC.primary;
  static Color get primaryGradientEnd => SC.primaryEnd;
  static const gold = Color(0xFFC5A059);
  static const goldLight = Color(0xFFE2C58A);
  static const goldBorder = Color(0xFFE7D2A7);
  static const goldSurface = Color(0xFFFAF5EC);
  static const goldDark = Color(0xFF7A5B10);
  static Color get mint => SC.mint;
  static Color get sage => SC.sage;

  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);

  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const inkMuted = Color(0xFF94A3B8);
  static const border = Color(0xFFEAE6DC);

  static const successBg = Color(0xFFE8F5E9);
  static const successText = Color(0xFF1B5E20);
  static const errorBg = Color(0xFFFEE2E2);
  static const errorText = Color(0xFF991B1B);
}

class _RoleInfo {
  final String value;
  final String label;
  final String chip; // label pendek untuk filter
  final IconData icon;
  const _RoleInfo(this.value, this.label, this.chip, this.icon);
}

const _kRoles = [
  _RoleInfo('ADMIN', 'Admin', 'Admin', Icons.admin_panel_settings_outlined),
  _RoleInfo('USTADZ', 'Ustadz / Guru', 'Ustadz', Icons.school_outlined),
  _RoleInfo('MUSYRIF', 'Musyrif / Pembina', 'Musyrif', Icons.night_shelter_outlined),
  _RoleInfo('PIMPINAN', 'Pimpinan / Mudir', 'Pimpinan', Icons.workspace_premium_outlined),
  _RoleInfo('WALI_SANTRI', 'Wali Santri', 'Wali', Icons.family_restroom_outlined),
];

_RoleInfo _roleOf(String value) {
  for (final r in _kRoles) {
    if (r.value == value) return r;
  }
  return _RoleInfo(value, value, value, Icons.person_outline_rounded);
}

/// Warna khas tiap peran (dipakai di pita kartu, avatar, bar komposisi).
Color _roleColor(String value) {
  switch (value) {
    case 'ADMIN':
      return _UC.primary;
    case 'USTADZ':
      return _UC.gold;
    case 'MUSYRIF':
      return _UC.goldDark;
    case 'PIMPINAN':
      return const Color(0xFF3F6AA0);
    case 'WALI_SANTRI':
      return const Color(0xFF5E8C7B);
    default:
      return _UC.inkSecondary;
  }
}

String _tanggalIndo(DateTime dt) {
  const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', "Jum'at", 'Sabtu'];
  const months = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  return '${days[dt.weekday % 7]}, ${dt.day} ${months[dt.month]} ${dt.year}';
}

/// Cincin progres melingkar.
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;
  final double stroke;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawArc(rect, 0, math.pi * 2, false, base..color = track);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress.clamp(0.0, 1.0),
        false,
        base..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track || old.stroke != stroke;
}

class UsersScreen extends StatefulWidget {
  /// true kalau dibuka lewat Navigator.push (tampil tombol kembali di header).
  final bool showBack;
  const UsersScreen({super.key, this.showBack = false});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _filter = 'SEMUA'; // 'SEMUA' atau nilai role
  String _q = '';
  bool _showAll = false;
  final _searchC = TextEditingController();
  static const int _batas = 6; // jumlah kartu yang tampil di awal

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------
  bool _isAktif(Map<String, dynamic> u) => (u['status'] ?? '').toString() == 'AKTIF';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AppScope.of(context).api;
      final res = await api.get(ApiUrl.users);
      if (!mounted) return;
      final raw = res is List ? res : (res is Map ? (res['items'] ?? res['data']) : null);
      setState(() {
        _items = (raw is List ? raw : const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat daftar pengguna.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _add() async {
    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _UC.surface,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _TambahSheet(api: AppScope.of(context).api),
    );
    if (res == null || !mounted) return;

    try {
      await AppScope.of(context).api.post(ApiUrl.users, res);
      if (!mounted) return;
      _toast('Pengguna ditambahkan', subtitle: '${res['nama']} • ${_roleOf('${res['role']}').label}');
      _load();
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Gagal menambahkan pengguna.', error: true);
    }
  }

  Future<void> _toggle(Map<String, dynamic> u) async {
    final nama = (u['nama'] ?? '-').toString();
    final lama = (u['status'] ?? '').toString();
    try {
      final res = await AppScope.of(context).api.patch('${ApiUrl.users}/${u['id']}/toggle');
      if (!mounted) return;
      final baru = (res is Map ? res['status'] : null)?.toString() ??
          (lama == 'AKTIF' ? 'NONAKTIF' : 'AKTIF');
      setState(() => u['status'] = baru);
      _toast(baru == 'AKTIF' ? 'Akun diaktifkan' : 'Akun dinonaktifkan', subtitle: nama);
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Gagal mengubah status akun.', error: true);
    }
  }

  Future<void> _hapus(Map<String, dynamic> u) async {
    final nama = (u['nama'] ?? '-').toString();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _UC.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(color: _UC.errorBg, shape: BoxShape.circle),
          child: const Icon(Icons.delete_outline_rounded, color: _UC.errorText, size: 26),
        ),
        title: const Text('Hapus pengguna?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _UC.ink)),
        content: Text(
          'Akun "$nama" akan dihapus dan tidak bisa masuk ke sistem lagi. Tindakan ini tidak bisa dibatalkan.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: _UC.inkSecondary, height: 1.45),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: _UC.inkSecondary,
              side: const BorderSide(color: _UC.border),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: const Text('Batal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: _UC.errorText,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: const Text('Ya, hapus', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await AppScope.of(context).api.delete('${ApiUrl.users}/${u['id']}');
      if (!mounted) return;
      setState(() => _items.removeWhere((x) => x['id'] == u['id']));
      _toast('Pengguna dihapus', subtitle: nama);
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } catch (_) {
      _toast('Gagal menghapus pengguna.', error: true);
    }
  }

  String _inisial(String nama) {
    final n = nama.trim();
    return n.isEmpty ? '?' : n.substring(0, 1).toUpperCase();
  }

  /// Notifikasi melayang bertema.
  void _toast(String title, {String? subtitle, bool error = false}) {
    if (!mounted) return;
    final w = MediaQuery.of(context).size.width;
    final side = w > 472 ? (w - 440) / 2 : 16.0;
    final fg = error ? _UC.errorText : Colors.white;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? _UC.errorBg : _UC.primary,
          elevation: 6,
          margin: EdgeInsets.fromLTRB(side, 0, side, 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          duration: Duration(seconds: error ? 4 : 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: error ? _UC.errorText.withOpacity(0.25) : _UC.gold.withOpacity(0.5)),
          ),
          content: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: error ? Colors.white : _UC.gold.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  error ? Icons.error_outline : Icons.check_rounded,
                  size: 18,
                  color: error ? _UC.errorText : _UC.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: fg)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 11.5, color: fg.withOpacity(0.75))),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ---------------------------------------------------------------------
  // Building blocks
  // ---------------------------------------------------------------------
  BoxDecoration get _cardDeco => BoxDecoration(
        color: _UC.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _UC.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      );

  /// Judul section dengan penanda emas.
  Widget _title(String t, {String? trailing}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(color: _UC.gold, borderRadius: BorderRadius.circular(999)),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            t,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: _UC.ink,
            ),
          ),
        ),
        if (trailing != null)
          Text(trailing, style: const TextStyle(fontSize: 11.5, color: _UC.inkSecondary)),
      ],
    );
  }

  Widget _heroPill(IconData icon, String text,
      {required Color bg, required Color fg, Color? border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border != null ? Border.all(color: border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label, {bool warn = false}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: warn ? _UC.goldLight : Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.72),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    final total = _items.length;
    final aktif = _items.where(_isAktif).length;
    final nonaktif = total - aktif;
    String v(int n) => _loading ? '–' : '$n';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_UC.primary, _UC.primaryGradientEnd],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _UC.primary.withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ornamen geometris
          Positioned(
            right: -26,
            top: -26,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: Colors.white.withOpacity(0.10), width: 1.5),
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _UC.gold.withOpacity(0.25), width: 1.2),
              ),
            ),
          ),
          Positioned(
            left: -44,
            bottom: -54,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(color: _UC.gold.withOpacity(0.12), shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (widget.showBack) ...[
                      InkWell(
                        onTap: () => Navigator.of(context).maybePop(),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.25)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 16, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.12),
                        border: Border.all(color: _UC.gold.withOpacity(0.7)),
                      ),
                      child: const Icon(Icons.manage_accounts_outlined,
                          size: 20, color: _UC.goldLight),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PUSAT AKUN',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: _UC.goldLight,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Manajemen Pengguna',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'Akses sistem pondok',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.72),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _loading ? 'Memuat...' : '$total Pengguna Terdaftar',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.3,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kelola siapa saja yang dapat masuk, beserta peran dan status akunnya.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.white.withOpacity(0.68),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _heroPill(
                      Icons.calendar_today_outlined,
                      _tanggalIndo(DateTime.now()),
                      bg: Colors.white.withOpacity(0.12),
                      fg: Colors.white,
                    ),
                    _heroPill(
                      Icons.verified_user_outlined,
                      'Akses Terkontrol',
                      bg: _UC.gold.withOpacity(0.18),
                      fg: _UC.goldLight,
                      border: _UC.gold.withOpacity(0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Strip kaca
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.16)),
                  ),
                  child: Row(
                    children: [
                      _heroStat(v(total), 'Total akun'),
                      Container(width: 1, height: 30, color: Colors.white.withOpacity(0.18)),
                      _heroStat(v(aktif), 'Aktif'),
                      Container(width: 1, height: 30, color: Colors.white.withOpacity(0.18)),
                      _heroStat(v(nonaktif), 'Nonaktif', warn: !_loading && nonaktif > 0),
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

  /// Kartu cincin: persentase akun aktif.
  Widget _ringCard() {
    final total = _items.length;
    final aktif = _items.where(_isAktif).length;
    final nonaktif = total - aktif;
    final pct = total > 0 ? aktif / total : 0.0;

    Widget legend(Color c, String label, int n) => Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600, color: _UC.inkSecondary)),
              ),
              Text('$n',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: _UC.ink)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco,
      child: Row(
        children: [
          SizedBox(
            width: 104,
            height: 104,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(104, 104),
                  painter: _RingPainter(
                    progress: pct,
                    color: _UC.primary,
                    track: _UC.surfaceDim,
                    stroke: 10,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      total == 0 ? '—' : '${(pct * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: _UC.ink,
                      ),
                    ),
                    const Text('akun aktif',
                        style: TextStyle(fontSize: 9, color: _UC.inkSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                legend(_UC.ink, 'Total akun', total),
                legend(_UC.primary, 'Aktif', aktif),
                legend(_UC.inkMuted, 'Nonaktif', nonaktif),
                Text(
                  nonaktif == 0
                      ? 'Semua akun dapat masuk.'
                      : '$nonaktif akun tidak dapat masuk.',
                  style: const TextStyle(fontSize: 10.5, color: _UC.inkSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _countRole(String r) => _items.where((u) => (u['role'] ?? '').toString() == r).length;

  /// Bar komposisi peran + legenda yang bisa diketuk untuk memfilter.
  Widget _komposisiCard() {
    final total = _items.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 12,
              child: total == 0
                  ? Container(color: _UC.surfaceDim)
                  : Row(
                      children: [
                        for (final r in _kRoles)
                          if (_countRole(r.value) > 0)
                            Expanded(
                              flex: _countRole(r.value),
                              child: Container(
                                margin: const EdgeInsets.only(right: 2),
                                color: _roleColor(r.value),
                              ),
                            ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in _kRoles)
                GestureDetector(
                  onTap: () => setState(() {
                    _filter = _filter == r.value ? 'SEMUA' : r.value;
                    _showAll = false;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: _filter == r.value
                          ? _roleColor(r.value).withOpacity(0.14)
                          : _UC.surfaceDim,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _filter == r.value
                            ? _roleColor(r.value).withOpacity(0.6)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _roleColor(r.value),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(r.chip,
                            style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: _UC.inkSecondary)),
                        const SizedBox(width: 6),
                        Text('${_countRole(r.value)}',
                            style: const TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.w800, color: _UC.ink)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchC,
      onChanged: (v) => setState(() {
        _q = v;
        _showAll = false;
      }),
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _UC.ink),
      decoration: InputDecoration(
        hintText: 'Cari nama atau email',
        hintStyle: const TextStyle(fontSize: 13.5, color: _UC.inkMuted),
        prefixIcon: Icon(Icons.search_rounded, size: 21, color: _UC.primary),
        suffixIcon: _q.isEmpty
            ? null
            : IconButton(
                tooltip: 'Hapus pencarian',
                icon: const Icon(Icons.close_rounded, size: 18, color: _UC.inkSecondary),
                onPressed: () {
                  _searchC.clear();
                  setState(() => _q = '');
                },
              ),
        filled: true,
        fillColor: _UC.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: _UC.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: _UC.primary, width: 1.4),
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label, int count) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() {
        _filter = value;
        _showAll = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _UC.primary : _UC.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? _UC.primary : _UC.border),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _UC.primary.withOpacity(0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _UC.inkSecondary,
                )),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withOpacity(0.2) : _UC.surfaceDim,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$count',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : _UC.inkSecondary,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('SEMUA', 'Semua', _items.length),
          for (final r in _kRoles) ...[
            const SizedBox(width: 8),
            _filterChip(r.value, r.chip, _countRole(r.value)),
          ],
        ],
      ),
    );
  }

  Widget _emptyCard(String judul, String pesan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: _cardDeco,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(color: _UC.goldSurface, shape: BoxShape.circle),
            child: const Icon(Icons.manage_accounts_outlined, color: _UC.gold, size: 30),
          ),
          const SizedBox(height: 12),
          Text(judul,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _UC.ink)),
          const SizedBox(height: 4),
          Text(pesan,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _UC.inkSecondary, height: 1.4)),
        ],
      ),
    );
  }

  Widget _toggleSemua(int total) {
    return Center(
      child: TextButton.icon(
        onPressed: () => setState(() => _showAll = !_showAll),
        icon: Icon(_showAll ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 20),
        label: Text(_showAll ? 'Tampilkan lebih sedikit' : 'Tampilkan semua ($total)'),
        style: TextButton.styleFrom(
          foregroundColor: _UC.primary,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  /// Kartu pengguna bergaya kartu identitas.
  Widget _userCard(Map<String, dynamic> u) {
    final nama = (u['nama'] ?? '-').toString().trim();
    final email = (u['email'] ?? '-').toString();
    final role = _roleOf((u['role'] ?? '').toString());
    final aktif = _isAktif(u);
    final warna = _roleColor(role.value);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _UC.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _UC.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pita warna peran
          Container(
            height: 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: aktif
                    ? [warna, warna.withOpacity(0.55), warna]
                    : [_UC.inkMuted, _UC.border, _UC.inkMuted],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: aktif ? warna : _UC.inkMuted, width: 1.6),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: aktif
                            ? [warna, warna.withOpacity(0.75)]
                            : [_UC.inkMuted, const Color(0xFFB8C0CC)],
                      ),
                    ),
                    child: Text(
                      _inisial(nama),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: _UC.ink,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.alternate_email_rounded,
                              size: 13, color: _UC.inkMuted),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.5, color: _UC.inkSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: aktif ? _UC.successBg : _UC.surfaceDim,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: aktif ? _UC.successText : _UC.inkMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        aktif ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: aktif ? _UC.successText : _UC.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Strip bawah: peran + kontrol
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            decoration: const BoxDecoration(
              color: _UC.surfaceDim,
              border: Border(top: BorderSide(color: _UC.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: warna.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(role.icon, size: 14, color: warna),
                      const SizedBox(width: 6),
                      Text(
                        role.label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: warna,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: aktif,
                    onChanged: (_) => _toggle(u),
                    activeColor: Colors.white,
                    activeTrackColor: _UC.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                IconButton(
                  onPressed: () => _hapus(u),
                  tooltip: 'Hapus',
                  visualDensity: VisualDensity.compact,
                  iconSize: 20,
                  color: _UC.errorText,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  List<Widget> _bodyChildren() {
    if (_loading) {
      return [SizedBox(height: 280, child: loadingView())];
    }
    if (_error != null) {
      return [SizedBox(height: 280, child: errorView(_error!, _load))];
    }

    final q = _q.trim().toLowerCase();
    final filtered = _items.where((u) {
      if (_filter != 'SEMUA' && (u['role'] ?? '').toString() != _filter) return false;
      if (q.isEmpty) return true;
      return (u['nama'] ?? '').toString().toLowerCase().contains(q) ||
          (u['email'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
    final tampil = _showAll ? filtered : filtered.take(_batas).toList();

    return [
      const SizedBox(height: 24),
      _title('Ringkasan Akun', trailing: 'Terkini'),
      const SizedBox(height: 12),
      _ringCard(),
      const SizedBox(height: 26),
      _title('Komposisi Peran', trailing: 'Ketuk untuk filter'),
      const SizedBox(height: 12),
      _komposisiCard(),
      const SizedBox(height: 26),
      _title('Daftar Pengguna', trailing: '${filtered.length} akun'),
      const SizedBox(height: 12),
      _searchField(),
      const SizedBox(height: 12),
      _filterRow(),
      const SizedBox(height: 14),
      if (filtered.isEmpty)
        _emptyCard(
          _items.isEmpty ? 'Belum ada pengguna' : 'Tidak ada hasil',
          _items.isEmpty
              ? 'Tambahkan akun pertama lewat tombol "Tambah User" di bawah.'
              : 'Tidak ada pengguna yang cocok dengan pencarian atau filter ini.',
        )
      else ...[
        for (final u in tampil) ...[
          _userCard(u),
          const SizedBox(height: 12),
        ],
        if (filtered.length > _batas) _toggleSemua(filtered.length),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _UC.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Stack(
            children: [
              Positioned.fill(
                child: RefreshIndicator(
                  color: _UC.primary,
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      _hero(),
                      ..._bodyChildren(),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.extended(
                  heroTag: null,
                  onPressed: _add,
                  backgroundColor: _UC.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(color: _UC.gold.withOpacity(0.6)),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: _UC.gold),
                  label: const Text('Tambah User',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Bottom sheet: tambah user
// ---------------------------------------------------------------------
class _TambahSheet extends StatefulWidget {
  final ApiClient api;
  const _TambahSheet({required this.api});

  @override
  State<_TambahSheet> createState() => _TambahSheetState();
}

class _TambahSheetState extends State<_TambahSheet> {
  static const TextStyle _label = TextStyle(
      fontSize: 10, letterSpacing: 0.6, fontWeight: FontWeight.w800, color: _UC.inkSecondary);

  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _hp = TextEditingController();
  String _role = 'USTADZ';
  bool _showPass = false;
  String? _err;

  // Khusus role Wali Santri
  String _hubungan = 'Ayah';
  String? _waliSantriId; // null = buat data wali baru
  List<Map<String, dynamic>> _waliTanpaAkun = [];
  bool _waliLoaded = false;
  final List<Map<String, dynamic>> _anak = [];

  bool get _isWali => _role == 'WALI_SANTRI';

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _pass.dispose();
    _hp.dispose();
    super.dispose();
  }

  void _pilihRole(String v) {
    setState(() => _role = v);
    if (v == 'WALI_SANTRI') _loadWali();
  }

  /// Ambil data wali yang belum punya akun (untuk opsi "tautkan ke wali yang sudah ada").
  Future<void> _loadWali() async {
    if (_waliLoaded) return;
    _waliLoaded = true;
    try {
      final res = await widget.api.get(ApiUrl.wali);
      final raw = res is List ? res : (res is Map ? (res['items'] ?? res['data']) : null);
      final list = (raw is List ? raw : const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((w) => w['user'] == null)
          .toList();
      if (mounted) setState(() => _waliTanpaAkun = list);
    } catch (_) {
      // Opsi tautan lama tidak tampil; membuat wali baru tetap bisa.
    }
  }

  void _pilihWali(String v) {
    setState(() => _waliSantriId = v.isEmpty ? null : v);
    if (v.isEmpty) return;
    final w = _waliTanpaAkun.firstWhere((e) => '${e['id']}' == v, orElse: () => <String, dynamic>{});
    if (_nama.text.trim().isEmpty && w['nama'] != null) _nama.text = '${w['nama']}';
    if (_hp.text.trim().isEmpty && w['noHp'] != null) _hp.text = '${w['noHp']}';
  }

  Future<void> _tambahAnak() async {
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _UC.surface,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SantriPicker(
        api: widget.api,
        excludeIds: {for (final a in _anak) '${a['id']}'},
      ),
    );
    if (picked != null && mounted) setState(() => _anak.add(picked));
  }

  void _submit() {
    final nama = _nama.text.trim();
    final email = _email.text.trim();
    final pass = _pass.text;

    if (nama.isEmpty) {
      setState(() => _err = 'Nama wajib diisi.');
      return;
    }
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _err = 'Format email tidak valid.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _err = 'Password minimal 6 karakter.');
      return;
    }

    final out = <String, dynamic>{
      'nama': nama,
      'email': email,
      'password': pass,
      'role': _role,
    };
    if (_isWali) {
      final hp = _hp.text.trim();
      if (hp.isNotEmpty) out['noHp'] = hp;
      if (_waliSantriId != null) {
        out['waliSantriId'] = _waliSantriId;
      } else {
        out['hubungan'] = _hubungan;
      }
      if (_anak.isNotEmpty) out['santriIds'] = [for (final a in _anak) '${a['id']}'];
    }
    Navigator.pop<Map<String, dynamic>>(context, out);
  }

  InputDecoration _dec(String label, {String? hint, Widget? suffix}) => InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffix,
        hintStyle: const TextStyle(fontSize: 13, color: _UC.inkMuted),
        labelStyle: const TextStyle(fontSize: 13, color: _UC.inkSecondary),
        filled: true,
        fillColor: _UC.surfaceDim,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _UC.primary, width: 1.4),
        ),
      );

  Widget _roleChip(_RoleInfo r) {
    final selected = _role == r.value;
    final warna = _roleColor(r.value);
    return GestureDetector(
      onTap: () => _pilihRole(r.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? warna : _UC.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? warna : _UC.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(r.icon, size: 15, color: selected ? Colors.white : _UC.inkSecondary),
            const SizedBox(width: 6),
            Text(r.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _UC.inkSecondary,
                )),
          ],
        ),
      ),
    );
  }

  Widget _hubChip(String h) {
    final selected = _hubungan == h;
    return GestureDetector(
      onTap: () => setState(() => _hubungan = h),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _UC.primary : _UC.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? _UC.primary : _UC.border),
        ),
        child: Text(h,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : _UC.inkSecondary,
            )),
      ),
    );
  }

  List<Widget> _waliSection() {
    return [
      const SizedBox(height: 18),
      const Text('DATA WALI', style: _label),
      const SizedBox(height: 8),
      TextField(
        controller: _hp,
        keyboardType: TextInputType.phone,
        style: const TextStyle(fontSize: 14, color: _UC.ink),
        decoration: _dec('No HP (opsional)', hint: '08xxxxxxxxxx'),
      ),
      const SizedBox(height: 12),
      if (_waliTanpaAkun.isNotEmpty) ...[
        DropdownButtonFormField<String>(
          value: _waliSantriId ?? '',
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: _UC.ink),
          decoration: _dec('Tautkan ke data wali yang sudah ada'),
          items: [
            const DropdownMenuItem<String>(value: '', child: Text('Buat data wali baru')),
            for (final w in _waliTanpaAkun)
              DropdownMenuItem<String>(
                value: '${w['id']}',
                child: Text('${w['nama']}', overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => _pilihWali(v ?? ''),
        ),
        const SizedBox(height: 12),
      ],
      if (_waliSantriId == null) ...[
        const Text('HUBUNGAN', style: _label),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final h in const ['Ayah', 'Ibu', 'Wali']) _hubChip(h)]),
        const SizedBox(height: 12),
      ],
      const Text('ANAK (OPSIONAL)', style: _label),
      const SizedBox(height: 8),
      if (_anak.isNotEmpty) ...[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in _anak)
              Chip(
                label: Text(
                  '${a['nama']}${a['kelas'] is Map ? ' • ${a['kelas']['namaKelas']}' : ''}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _UC.ink),
                ),
                backgroundColor: _UC.sage,
                side: BorderSide.none,
                deleteIconColor: _UC.inkSecondary,
                onDeleted: () => setState(() => _anak.remove(a)),
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
      OutlinedButton.icon(
        onPressed: _tambahAnak,
        icon: const Icon(Icons.person_add_alt_rounded, size: 18),
        label: Text(_anak.isEmpty ? 'Pilih anak' : 'Tambah anak lagi',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: _UC.primary,
          side: const BorderSide(color: _UC.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _UC.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _UC.goldSurface,
                      border: Border.all(color: _UC.gold.withOpacity(0.6)),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, size: 20, color: _UC.gold),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tambah Pengguna',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _UC.ink)),
                        Text('Buat akun baru untuk masuk ke sistem',
                            style: TextStyle(fontSize: 11.5, color: _UC.inkSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _nama,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 14, color: _UC.ink),
                decoration: _dec('Nama', hint: 'Nama lengkap'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: const TextStyle(fontSize: 14, color: _UC.ink),
                decoration: _dec('Email', hint: 'nama@pondok.id'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pass,
                obscureText: !_showPass,
                style: const TextStyle(fontSize: 14, color: _UC.ink),
                decoration: _dec(
                  'Password',
                  hint: 'Minimal 6 karakter',
                  suffix: IconButton(
                    onPressed: () => setState(() => _showPass = !_showPass),
                    tooltip: _showPass ? 'Sembunyikan' : 'Tampilkan',
                    icon: Icon(
                      _showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: _UC.inkSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text('PERAN', style: _label),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [for (final r in _kRoles) _roleChip(r)]),
              if (_isWali) ..._waliSection(),
              if (_err != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _UC.errorBg, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: _UC.errorText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_err!,
                            style: const TextStyle(fontSize: 12.5, color: _UC.errorText)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _UC.inkSecondary,
                      side: const BorderSide(color: _UC.border),
                      minimumSize: const Size(0, 50),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: const Text('Batal',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: _UC.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        icon: const Icon(Icons.verified_outlined, size: 18, color: Colors.white),
                        label: const Text('Simpan Pengguna',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
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

// ---------------------------------------------------------------------
// Bottom sheet: pilih santri (anak) dengan pencarian nama / NIS
// ---------------------------------------------------------------------
class _SantriPicker extends StatefulWidget {
  final ApiClient api;
  final Set<String> excludeIds;
  const _SantriPicker({required this.api, required this.excludeIds});

  @override
  State<_SantriPicker> createState() => _SantriPickerState();
}

class _SantriPickerState extends State<_SantriPicker> {
  final _q = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _err;
  int _seq = 0; // supaya hasil pencarian lama tidak menimpa yang baru

  @override
  void initState() {
    super.initState();
    _cari('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _cari(v.trim()));
  }

  Future<void> _cari(String q) async {
    final my = ++_seq;
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final res = await widget.api.get(ApiUrl.santri, query: {'search': q});
      if (!mounted || my != _seq) return;
      final raw = res is Map ? res['items'] : res;
      setState(() {
        _items = (raw is List ? raw : const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted && my == _seq) {
        setState(() {
          _err = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted && my == _seq) {
        setState(() {
          _err = 'Gagal memuat daftar santri.';
          _loading = false;
        });
      }
    }
  }

  Widget _tile(Map<String, dynamic> s) {
    final id = '${s['id']}';
    final kelas = s['kelas'] is Map ? '${s['kelas']['namaKelas']}' : '-';
    final waliLama = s['wali'] is Map ? '${s['wali']['nama']}' : null;
    final dipilih = widget.excludeIds.contains(id);
    final disabled = dipilih || waliLama != null;

    String sub = '${s['nis'] ?? '-'} • $kelas';
    if (dipilih) {
      sub = 'Sudah dipilih';
    } else if (waliLama != null) {
      sub = 'Sudah punya wali: $waliLama';
    }

    return ListTile(
      enabled: !disabled,
      onTap: () => Navigator.pop(context, s),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        backgroundColor: _UC.sage,
        child: Text(
          '${s['nama'] ?? '?'}'.trim().isEmpty ? '?' : '${s['nama']}'.trim().substring(0, 1).toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.w800, color: _UC.primary),
        ),
      ),
      title: Text('${s['nama'] ?? '-'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _UC.ink)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11.5, color: _UC.inkSecondary)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.7;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: h,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _UC.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Pilih Anak',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _UC.ink)),
              const SizedBox(height: 2),
              const Text('Cari berdasarkan nama atau NIS santri',
                  style: TextStyle(fontSize: 11.5, color: _UC.inkSecondary)),
              const SizedBox(height: 12),
              TextField(
                controller: _q,
                onChanged: _onChanged,
                style: const TextStyle(fontSize: 14, color: _UC.ink),
                decoration: InputDecoration(
                  hintText: 'Cari santri',
                  hintStyle: const TextStyle(fontSize: 13, color: _UC.inkMuted),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _UC.inkSecondary),
                  filled: true,
                  fillColor: _UC.surfaceDim,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _err != null
                        ? Center(
                            child: Text(_err!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12.5, color: _UC.errorText)))
                        : _items.isEmpty
                            ? const Center(
                                child: Text('Santri tidak ditemukan.',
                                    style: TextStyle(fontSize: 12.5, color: _UC.inkSecondary)))
                            : ListView.separated(
                                itemCount: _items.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, color: _UC.border),
                                itemBuilder: (_, i) => _tile(_items[i]),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}