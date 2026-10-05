import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import '../santri/santri_ui.dart' show SC;

// ============================================================================
// Token warna lokal (disamakan dengan pengaturan_admin_screen.dart)
// ============================================================================

class _RC {
  static Color get primary => SC.primary;
  static Color get primarySoft => SC.primaryEnd;
  static Color get mint => SC.mint;
  static Color get sage => SC.sage;
  static const gold = Color(0xFFF9D77E);
  static const background = Color(0xFFFAF9F5);
  static const surface = Colors.white;
  static const surfaceDim = Color(0xFFF5F4EE);
  static const line = Color(0xFFEAE6DC);
  static const inkSecondary = Color(0xFF475569);

  static const greenFg = Color(0xFF166534);
  static const greenBg = Color(0xFFDCFCE7);
  static const redFg = Color(0xFF991B1B);
  static const redBg = Color(0xFFFEE2E2);

  // Batas nilai lulus (KKM). Ubah di sini kalau KKM berubah.
  static const double kkm = 75;
}

TextStyle _t(double size, FontWeight w, Color c, {double? height}) => TextStyle(
  fontFamily: 'Nunito',
  fontSize: size,
  fontWeight: w,
  color: c,
  height: height,
);

BoxDecoration _cardDeco() => BoxDecoration(
  color: _RC.surface,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: _RC.line.withOpacity(0.7)),
  boxShadow: const [
    BoxShadow(color: Color(0x0F0F3A2E), blurRadius: 14, offset: Offset(0, 5)),
  ],
);

/// Notifikasi melayang bertema (sukses = warna tema, gagal = merah lembut).
/// Sama dengan toast di halaman Users / Ustadz / Kesehatan.
void _toast(
  BuildContext context,
  String title, {
  String? subtitle,
  bool error = false,
}) {
  final w = MediaQuery.of(context).size.width;
  final side = w > 472 ? (w - 440) / 2 : 16.0;
  final fg = error ? _RC.redFg : Colors.white;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.fromLTRB(side, 0, side, 16),
        duration: Duration(seconds: error ? 4 : 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: error ? _RC.redBg : _RC.primary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: error
                  ? _RC.redFg.withOpacity(0.25)
                  : _RC.gold.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: (error ? _RC.redFg : _RC.primary).withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: error ? Colors.white : _RC.gold.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  error ? Icons.error_outline : Icons.check_rounded,
                  size: 18,
                  color: error ? _RC.redFg : _RC.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: _t(13.5, FontWeight.w800, fg),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: _t(11.5, FontWeight.w500, fg.withOpacity(0.75)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

// ============================================================================
// Daftar santri
// ============================================================================

class RaporScreen extends StatefulWidget {
  const RaporScreen({super.key});

  @override
  State<RaporScreen> createState() => _RaporScreenState();
}

class _RaporScreenState extends State<RaporScreen> {
  List<dynamic> _santri = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AppScope.of(context).api.get(ApiUrl.santri);
      final items = (res as Map<String, dynamic>)['items'] as List;
      if (!mounted) return;
      setState(() {
        _santri = items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _loading = false;
        });
    }
  }

  String _periodeSekarang() {
    final n = DateTime.now();
    if (n.month >= 7) return '${n.year}/${n.year + 1} - Ganjil';
    return '${n.year - 1}/${n.year} - Genap';
  }

  Future<void> _generate(Map<String, dynamic> santri) async {
    final periode = TextEditingController(text: _periodeSekarang());
    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _RC.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: _RC.sage, shape: BoxShape.circle),
          child: Icon(Icons.description_outlined, size: 24, color: _RC.primary),
        ),
        title: Text(
          'Generate Rapor',
          textAlign: TextAlign.center,
          style: _t(17, FontWeight.w800, _RC.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _RC.surfaceDim,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    '${santri['nama']}',
                    textAlign: TextAlign.center,
                    style: _t(14, FontWeight.w800, _RC.primary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'NIS ${santri['nis']}',
                    style: _t(12, FontWeight.w600, _RC.inkSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: periode,
              style: _t(14, FontWeight.w700, _RC.primary),
              decoration: InputDecoration(
                labelText: 'Periode',
                hintText: 'Contoh: 2026/2027 - Ganjil',
                labelStyle: _t(13, FontWeight.w600, _RC.inkSecondary),
                hintStyle: _t(
                  13,
                  FontWeight.w500,
                  _RC.inkSecondary.withOpacity(0.6),
                ),
                filled: true,
                fillColor: _RC.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _RC.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _RC.primary, width: 1.6),
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Batal',
              style: _t(13, FontWeight.w700, _RC.inkSecondary),
            ),
          ),
          FilledButton(
            onPressed: () {
              if (periode.text.trim().isEmpty) return;
              Navigator.of(ctx).pop(periode.text.trim());
            },
            style: FilledButton.styleFrom(
              backgroundColor: _RC.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            child: Text(
              'Generate',
              style: _t(13, FontWeight.w800, Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == null) return;
    try {
      await AppScope.of(context).api.post(ApiUrl.raporGenerate, {
        'santriId': santri['id'],
        'periode': confirmed.trim(),
      });
      if (!mounted) return;
      _toast(
        context,
        'Rapor berhasil digenerate',
        subtitle: '${santri['nama']} • $confirmed',
      );
    } on ApiException catch (e) {
      if (mounted) _toast(context, e.message, error: true);
    } catch (_) {
      if (mounted) _toast(context, 'Gagal generate rapor.', error: true);
    }
  }

  void _bukaDetail(Map<String, dynamic> s) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => RaporDetailScreen(santri: s)));
  }

  String _inisial(String nama) {
    final t = nama.trim();
    return t.isEmpty ? '?' : t.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _RC.background,
      body: _loading
          ? loadingView()
          : _error != null
          ? errorView(_error!, _load)
          : _santri.isEmpty
          ? emptyView('Belum ada santri.')
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: RefreshIndicator(
                  color: _RC.primary,
                  onRefresh: _load,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    itemCount: _santri.length + 1,
                    itemBuilder: (ctx, i) {
                      if (i == 0) return _header();
                      final s = _santri[i - 1] as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _santriCard(s),
                      );
                    },
                  ),
                ),
              ),
            ),
    );
  }

    Widget _header() {
    final jumlahKelas = _santri
        .map((s) => (s as Map<String, dynamic>)['kelas']?['namaKelas'])
        .where((k) => k != null)
        .toSet()
        .length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_RC.primary, _RC.primarySoft],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _RC.primary.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -36,
              top: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -44,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _RC.gold.withOpacity(0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _RC.gold.withOpacity(0.55),
                          ),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          size: 23,
                          color: _RC.gold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rapor Digital',
                              style: _t(
                                21,
                                FontWeight.w800,
                                Colors.white,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Generate dan terbitkan rapor santri',
                              style: _t(12, FontWeight.w500, Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _headerStat(
                          Icons.groups_outlined,
                          '${_santri.length}',
                          'Santri',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _headerStat(
                          Icons.class_outlined,
                          '$jumlahKelas',
                          'Kelas',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerStat(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 8),
          Text(value, style: _t(18, FontWeight.w800, Colors.white, height: 1)),
          const SizedBox(width: 6),
          Text(label, style: _t(12, FontWeight.w600, Colors.white70)),
        ],
      ),
    );
  }

  Widget _santriCard(Map<String, dynamic> s) {
    final nama = (s['nama'] ?? '-') as String;
    final kelas = s['kelas']?['namaKelas'] ?? '-';

    return Container(
      decoration: _cardDeco(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _bukaDetail(s),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _RC.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _inisial(nama),
                    style: _t(18, FontWeight.w800, _RC.gold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(14, FontWeight.w800, _RC.primary),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'NIS ${s['nis']} • $kelas',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(11.5, FontWeight.w500, _RC.inkSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Material(
                            color: _RC.sage,
                            borderRadius: BorderRadius.circular(9999),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(9999),
                              onTap: () => _generate(s),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_outlined,
                                      size: 14,
                                      color: _RC.primary,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Generate',
                                      style: _t(
                                        11.5,
                                        FontWeight.w800,
                                        _RC.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: _RC.surfaceDim,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.visibility_outlined,
                    size: 17,
                    color: _RC.primary,
                  ),
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
// Detail rapor
// ============================================================================

class RaporDetailScreen extends StatefulWidget {
  final Map<String, dynamic> santri;
  const RaporDetailScreen({super.key, required this.santri});

  @override
  State<RaporDetailScreen> createState() => _RaporDetailScreenState();
}

class _RaporDetailScreenState extends State<RaporDetailScreen> {
  List<dynamic> _rapors = [];
  String? _busy; // 'terbit:<id>' atau 'perbarui:<id>' saat proses berjalan
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AppScope.of(context).api.get(
        ApiUrl.rapor,
        query: {'santriId': widget.santri['id'] as String},
      );
      final items = res is List
          ? res
          : ((res as Map<String, dynamic>)['data'] as List? ?? []);
      if (!mounted) return;
      setState(() {
        _rapors = items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _loading = false;
        });
    }
  }

  Future<void> _terbit(Map<String, dynamic> r) async {
    if (_busy != null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _RC.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: _RC.sage, shape: BoxShape.circle),
          child: Icon(Icons.send_outlined, size: 24, color: _RC.primary),
        ),
        title: Text(
          'Terbitkan rapor?',
          textAlign: TextAlign.center,
          style: _t(17, FontWeight.w800, _RC.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _RC.surfaceDim,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    '${widget.santri['nama']}',
                    textAlign: TextAlign.center,
                    style: _t(14, FontWeight.w800, _RC.primary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${r['periode']}',
                    style: _t(12, FontWeight.w600, _RC.inkSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Pastikan nilai dan kehadiran sudah benar. '
              'Rapor yang sudah diterbitkan tidak dapat diubah lagi.',
              textAlign: TextAlign.center,
              style: _t(12.5, FontWeight.w500, _RC.inkSecondary, height: 1.45),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Batal',
              style: _t(13, FontWeight.w700, _RC.inkSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: _RC.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            child: Text(
              'Terbitkan',
              style: _t(13, FontWeight.w800, Colors.white),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = 'terbit:${r['id']}');
    try {
      await AppScope.of(context).api.patch('${ApiUrl.rapor}/${r['id']}/terbit');
      if (!mounted) return;
      // Ubah status langsung di list (tanpa _load) supaya layar tidak berkedip.
      setState(() => r['status'] = 'TERBIT');
      _toast(
        context,
        'Rapor diterbitkan',
        subtitle: '${r['periode']} • Status: TERBIT',
      );
    } on ApiException catch (e) {
      if (mounted) _toast(context, e.message, error: true);
    } catch (_) {
      if (mounted) _toast(context, 'Gagal menerbitkan rapor.', error: true);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  /// Tarik ulang nilai & kehadiran untuk rapor yang masih draft.
  Future<void> _perbarui(Map<String, dynamic> r) async {
    if (_busy != null) return;
    setState(() => _busy = 'perbarui:${r['id']}');
    try {
      await AppScope.of(context).api.post(ApiUrl.raporGenerate, {
        'santriId': widget.santri['id'],
        'periode': r['periode'],
      });
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      _toast(
        context,
        'Rapor diperbarui',
        subtitle: 'Nilai & kehadiran ditarik ulang',
      );
    } on ApiException catch (e) {
      if (mounted) _toast(context, e.message, error: true);
    } catch (_) {
      if (mounted) _toast(context, 'Gagal memperbarui rapor.', error: true);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  /// Panel status: jelas beda antara draft dan sudah terbit.
  Widget _statusPanel(bool terbit) {
    final bg = terbit ? _RC.sage : const Color(0xFFFAF5EC);
    final fg = terbit ? _RC.primary : const Color(0xFF7A5B10);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(
            terbit ? Icons.verified_rounded : Icons.edit_note_rounded,
            size: 24,
            color: fg,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  terbit ? 'Rapor sudah diterbitkan' : 'Masih berstatus draft',
                  style: _t(13, FontWeight.w800, fg),
                ),
                const SizedBox(height: 2),
                Text(
                  terbit
                      ? 'Rapor ini sudah final dan tidak dapat diubah.'
                      : 'Periksa nilai dan kehadiran, perbarui jika perlu, lalu terbitkan.',
                  style: _t(11.5, FontWeight.w500, fg.withOpacity(0.85), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tombol aksi untuk rapor draft: Perbarui + Terbitkan.
  Widget _aksiDraft(Map<String, dynamic> r) {
    final id = r['id']?.toString();
    final sibuk = _busy != null;
    final loadingTerbit = _busy == 'terbit:$id';
    final loadingPerbarui = _busy == 'perbarui:$id';

    Widget spinner(Color c) => SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: c),
        );

    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: sibuk ? null : () => _perbarui(r),
          icon: loadingPerbarui
              ? spinner(_RC.primary)
              : const Icon(Icons.refresh_rounded, size: 18),
          label: Text('Perbarui', style: _t(13, FontWeight.w800, _RC.primary)),
          style: OutlinedButton.styleFrom(
            foregroundColor: _RC.primary,
            side: BorderSide(color: _RC.primary.withOpacity(0.4)),
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: sibuk ? null : () => _terbit(r),
              icon: loadingTerbit
                  ? spinner(Colors.white)
                  : const Icon(Icons.send_outlined, size: 18, color: Colors.white),
              label: Text('Terbitkan', style: _t(14, FontWeight.w800, Colors.white)),
              style: FilledButton.styleFrom(
                backgroundColor: _RC.primary,
                disabledBackgroundColor: _RC.primary.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _RC.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                _topBar(),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Material(
            color: _RC.surface,
            shape: CircleBorder(side: BorderSide(color: _RC.line)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: _RC.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.santri['nama'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(19, FontWeight.w800, _RC.primary, height: 1.15),
                ),
                const SizedBox(height: 2),
                Text(
                  'NIS ${widget.santri['nis']} • Rapor Digital',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(12, FontWeight.w500, _RC.inkSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return loadingView();
    if (_error != null) return errorView(_error!, _load);
    if (_rapors.isEmpty) return _emptyState();

    return RefreshIndicator(
      color: _RC.primary,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        itemCount: _rapors.length,
        itemBuilder: (ctx, i) {
          final r = _rapors[i] as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _raporCard(r),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikon berlapis
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: _RC.sage.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: _RC.surface,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x140F3A2E),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    size: 40,
                    color: _RC.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Belum Ada Rapor',
              textAlign: TextAlign.center,
              style: _t(19, FontWeight.w800, _RC.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Rapor untuk ${widget.santri['nama']} belum dibuat. '
              'Kembali ke daftar santri, lalu tekan tombol Generate '
              'pada kartu santri ini.',
              textAlign: TextAlign.center,
              style: _t(13, FontWeight.w500, _RC.inkSecondary, height: 1.5),
            ),
            const SizedBox(height: 22),
            Material(
              color: _RC.primary,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).maybePop(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 13,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kembali ke Daftar Santri',
                        style: _t(13.5, FontWeight.w800, Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _raporCard(Map<String, dynamic> r) {
    final ringkasan = (r['ringkasan'] as Map<String, dynamic>?) ?? {};
    final mapelList = (ringkasan['mapel'] as List? ?? []);
    final ujianList = (ringkasan['ujian'] as List? ?? []);
    final kehadiran = (ringkasan['kehadiran'] as Map<String, dynamic>?) ?? {};
    final terbit = r['status'] == 'TERBIT';

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: _cardDeco().copyWith(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: terbit ? _RC.primary.withOpacity(0.35) : _RC.line.withOpacity(0.7),
          width: terbit ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner periode + rata-rata
          Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_RC.primary, _RC.primarySoft],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(right: -36, top: -46, child: _ring(150)),
                Positioned(right: 16, top: 16, child: _ring(70)),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r['periode'] as String,
                              style: _t(14, FontWeight.w800, Colors.white70),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: terbit ? _RC.mint : _RC.gold,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  terbit
                                      ? Icons.check_circle_rounded
                                      : Icons.edit_note_rounded,
                                  size: 13,
                                  color: _RC.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  terbit ? 'Diterbitkan' : 'Draft',
                                  style: _t(10.5, FontWeight.w800, _RC.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (r['rataRata'] != null) ...[
                        Text(
                          'Rata-rata',
                          style: _t(11.5, FontWeight.w600, Colors.white60),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (r['rataRata'] as num).toStringAsFixed(1),
                          style: _t(
                            40,
                            FontWeight.w800,
                            Colors.white,
                            height: 1,
                          ),
                        ),
                      ] else
                        Text(
                          'Belum ada nilai rata-rata',
                          style: _t(13, FontWeight.w600, Colors.white70),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mapelList.isNotEmpty) ...[
                  _sectionLabel(Icons.menu_book_outlined, 'Nilai Mapel'),
                  const SizedBox(height: 10),
                  ...mapelList.map((m) {
                    final mm = m as Map<String, dynamic>;
                    return _nilaiBar(
                      mm['mapel'].toString(),
                      (mm['rataRata'] as num).toDouble(),
                    );
                  }),
                ],
                if (ujianList.isNotEmpty) ...[
                  if (mapelList.isNotEmpty) const SizedBox(height: 14),
                  _sectionLabel(Icons.fact_check_outlined, 'Nilai Ujian'),
                  const SizedBox(height: 10),
                  ...ujianList.map((m) {
                    final mm = m as Map<String, dynamic>;
                    return _nilaiBar(
                      mm['ujian'].toString(),
                      (mm['rataRata'] as num).toDouble(),
                    );
                  }),
                ],
                if (kehadiran['total'] != null) ...[
                  if (mapelList.isNotEmpty || ujianList.isNotEmpty)
                    const SizedBox(height: 14),
                  _kehadiranPanel(kehadiran),
                ],
                const SizedBox(height: 16),
                _statusPanel(terbit),
                if (!terbit) ...[
                  const SizedBox(height: 12),
                  _aksiDraft(r),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
      ),
    );
  }

  Widget _sectionLabel(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _RC.sage,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: _RC.primary),
        ),
        const SizedBox(width: 10),
        Text(text, style: _t(14, FontWeight.w800, _RC.primary)),
      ],
    );
  }

  Widget _kehadiranPanel(Map<String, dynamic> k) {
    final hadir = (k['hadir'] as num?)?.toDouble() ?? 0;
    final total = (k['total'] as num?)?.toDouble() ?? 0;
    final persen = total > 0 ? (hadir / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _RC.surfaceDim,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.how_to_reg_outlined, size: 18, color: _RC.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kehadiran',
                  style: _t(13, FontWeight.w800, _RC.primary),
                ),
              ),
              Text(
                '${k['hadir'] ?? 0}/${k['total'] ?? 0} hadir',
                style: _t(12, FontWeight.w700, _RC.inkSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: persen,
              minHeight: 8,
              backgroundColor: _RC.line,
              valueColor: AlwaysStoppedAnimation<Color>(_RC.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nilaiBar(String label, double nilai) {
    final lulus = nilai >= _RC.kkm;
    final fg = lulus ? _RC.greenFg : _RC.redFg;
    final bg = lulus ? _RC.greenBg : _RC.redBg;
    final bar = lulus ? _RC.primary : const Color(0xFFDC2626);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(13, FontWeight.w600, _RC.inkSecondary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  nilai.toStringAsFixed(1),
                  style: _t(12.5, FontWeight.w800, fg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: (nilai / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: _RC.surfaceDim,
              valueColor: AlwaysStoppedAnimation<Color>(bar),
            ),
          ),
        ],
      ),
    );
  }
}
