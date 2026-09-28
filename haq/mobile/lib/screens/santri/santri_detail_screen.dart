import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';

/// Palet sama persis dengan `_WC` di dashboard_screen.dart.
class _DC {
  _DC._();

  static const primary = Color(0xFF0F3A2E);
  static const primaryGradientEnd = Color(0xFF164E3D);
  static const gold = Color(0xFFC5A059);
  static const goldSurface = Color(0xFFFAF5EC);
  static const mint = Color(0xFFD2E4DC);
  static const sage = Color(0xFFE2ECE9);

  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF5F4EE);

  static const ink = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const border = Color(0xFFEAE6DC);

  static const errorBg = Color(0xFFFEE2E2);
  static const errorText = Color(0xFF991B1B);
}

class SantriDetailScreen extends StatefulWidget {
  final String santriId;
  const SantriDetailScreen({super.key, required this.santriId});

  @override
  State<SantriDetailScreen> createState() => _SantriDetailScreenState();
}

class _SantriDetailScreenState extends State<SantriDetailScreen> {
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    // _data sengaja TIDAK di-null-kan, supaya pull-to-refresh
    // tidak mengosongkan layar. Loading penuh hanya di pemuatan pertama.
    setState(() => _error = null);
    try {
      final api = AppScope.of(context).api;
      final res = await api.get('${ApiUrl.santri}/${widget.santriId}');
      if (mounted) setState(() => _data = res as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat detail.');
    }
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------
  String _str(dynamic v, [String fallback = '-']) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? fallback : s;
  }

  String _jk(dynamic v) {
    final s = v?.toString().toUpperCase();
    if (s == 'L') return 'Laki-laki';
    if (s == 'P') return 'Perempuan';
    return _str(v);
  }

  /// "2026-09-28T..." -> "28/09/2026". Aman kalau formatnya tak terduga.
  String _tgl(dynamic v) {
    final dt = DateTime.tryParse(v?.toString() ?? '');
    if (dt == null) return '';
    final l = dt.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
  }

  // ---------------------------------------------------------------------
  // Building blocks
  // ---------------------------------------------------------------------
  Widget _backButton({bool onDark = true}) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: onDark ? Colors.white.withOpacity(0.12) : _DC.sage,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.arrow_back_rounded, size: 20, color: onDark ? Colors.white : _DC.primary),
      ),
    );
  }

  Widget _pill(String label, {required Color bg, required Color fg, Color? border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _hero(Map<String, dynamic> d) {
    final nama = _str(d['nama'], 'Santri');
    final nis = _str(d['nis']);
    final kelas = (d['kelas'] as Map?)?['namaKelas']?.toString();
    final inisial = nama.isNotEmpty ? nama[0].toUpperCase() : '?';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_DC.primary, _DC.primaryGradientEnd],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: _DC.primary.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(color: _DC.gold.withOpacity(0.10), shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _backButton(),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _DC.gold.withOpacity(0.5)),
                      ),
                      child: const Text(
                        'DETAIL SANTRI',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: _DC.gold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _DC.mint,
                        shape: BoxShape.circle,
                        border: Border.all(color: _DC.gold.withOpacity(0.6), width: 1.5),
                      ),
                      child: Text(inisial,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _DC.primary)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nama,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700, height: 1.2, color: Colors.white)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _pill('NIS $nis', bg: Colors.white.withOpacity(0.12), fg: Colors.white),
                              if (kelas != null) _pill(kelas, bg: _DC.mint, fg: _DC.primary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required List<Widget> children,
    String? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DC.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(color: _DC.sage, shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: _DC.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _DC.ink)),
              ),
              if (trailing != null) _pill(trailing, bg: _DC.sage, fg: _DC.primary),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: _DC.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12, color: _DC.inkSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _DC.ink)),
          ),
        ],
      ),
    );
  }

  Widget _emptyRow(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _DC.inkSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, color: _DC.inkSecondary))),
      ],
    );
  }

  Widget _tahfidzItem(Map<String, dynamic> c) {
    final catatan = _str(c['catatanUstadz'], '');
    final tgl = _tgl(c['tanggalSetor']);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _DC.surfaceDim, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: _DC.goldSurface, shape: BoxShape.circle),
            child: const Icon(Icons.menu_book, size: 17, color: _DC.gold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Juz ${_str(c['juz'])} • Halaman ${_str(c['halaman'])}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _DC.ink)),
                if (catatan.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(catatan,
                      style: const TextStyle(fontSize: 11.5, color: _DC.inkSecondary, height: 1.35)),
                ],
              ],
            ),
          ),
          if (tgl.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(tgl, style: const TextStyle(fontSize: 11, color: _DC.inkSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _pelanggaranItem(Map<String, dynamic> p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _DC.surfaceDim, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: _DC.errorBg, shape: BoxShape.circle),
            child: const Icon(Icons.gavel, size: 17, color: _DC.errorText),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_str(p['jenisPelanggaran']),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _DC.ink)),
          ),
          const SizedBox(width: 8),
          _pill('${_str(p['poin'], '0')} poin', bg: _DC.errorBg, fg: _DC.errorText),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  Widget _content(Map<String, dynamic> d) {
    final tahfidz = ((d['capaianTahfidzs'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final pelanggaran = ((d['pelanggarans'] as List?) ?? const []).cast<Map<String, dynamic>>();

    return RefreshIndicator(
      color: _DC.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _hero(d),
          const SizedBox(height: 16),
          _card(
            title: 'Identitas',
            icon: Icons.badge,
            children: [
              _row('NIS', _str(d['nis'])),
              _row('Nama', _str(d['nama'])),
              _row('Jenis Kelamin', _jk(d['jenisKelamin'])),
              _row('Kelas', _str((d['kelas'] as Map?)?['namaKelas'])),
              _row('Tahun Masuk', _str(d['tahunMasuk'])),
              _row('Wali', _str((d['wali'] as Map?)?['nama']), last: true),
            ],
          ),
          const SizedBox(height: 12),
          _card(
            title: 'Capaian Tahfidz',
            icon: Icons.menu_book,
            trailing: tahfidz.isEmpty ? null : '${tahfidz.length} Setoran',
            children: tahfidz.isEmpty
                ? [_emptyRow('Belum ada capaian tahfidz.', Icons.inbox_outlined)]
                : [for (final c in tahfidz) _tahfidzItem(c)],
          ),
          const SizedBox(height: 12),
          _card(
            title: 'Pelanggaran',
            icon: Icons.gavel,
            children: pelanggaran.isEmpty
                ? [_emptyRow('Tidak ada pelanggaran.', Icons.check_circle_outline)]
                : [for (final p in pelanggaran) _pelanggaranItem(p)],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_data != null) {
      body = _content(_data!);
    } else {
      // Loading / error pertama kali: tampilkan tombol kembali + status.
      body = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Align(alignment: Alignment.centerLeft, child: _backButton(onDark: false)),
          ),
          Expanded(child: _error != null ? errorView(_error!, _load) : loadingView()),
        ],
      );
    }

    return Scaffold(
      backgroundColor: _DC.background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: body,
          ),
        ),
      ),
    );
  }
}