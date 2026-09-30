import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/app_scope.dart';
import '../ui_utils.dart';
import 'santri_ui.dart';

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

  List<Map<String, dynamic>> _list(dynamic v) => ((v as List?) ?? const [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  // ---------------------------------------------------------------------
  // Hero + statistik
  // ---------------------------------------------------------------------
  Widget _hero(Map<String, dynamic> d, {required int setoran, required int poin}) {
    final nama = _str(d['nama'], 'Santri');
    final nis = _str(d['nis']);
    final kelas = (d['kelas'] as Map?)?['namaKelas']?.toString();
    final status = d['status'] is String ? (d['status'] as String) : null;
    final top = MediaQuery.of(context).padding.top + 12;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: HeroShell(
            top: top,
            bottom: 62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const HeroBackButton(),
                    const SizedBox(width: 12),
                    Text('Profil santri', style: sty(16, FontWeight.w800, Colors.white)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    SantriAvatar(
                        name: nama, gender: d['jenisKelamin']?.toString(), size: 68, onDark: true, badge: true),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nama,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: sty(20, FontWeight.w800, Colors.white, h: 1.2)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              SPill('NIS $nis',
                                  icon: Icons.tag_rounded,
                                  bg: Colors.white.withOpacity(0.14),
                                  fg: Colors.white),
                              if (kelas != null && kelas.trim().isNotEmpty)
                                SPill(kelas, icon: Icons.class_outlined, bg: SC.mint, fg: SC.primary),
                              if (status != null && status.isNotEmpty)
                                SPill(status,
                                    bg: statusColors(status).bg, fg: statusColors(status).fg),
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
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: SC.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SC.border),
              boxShadow: const [
                BoxShadow(color: Color(0x1A0F3A2E), blurRadius: 18, offset: Offset(0, 8)),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _stat(Icons.event_available_outlined, _str(d['tahunMasuk']), 'Tahun masuk', SC.primary),
                  Container(width: 1, color: SC.border),
                  _stat(Icons.menu_book_rounded, '$setoran', 'Setoran tahfidz', SC.goldDark),
                  Container(width: 1, color: SC.border),
                  _stat(Icons.gavel_rounded, '$poin', 'Poin pelanggaran',
                      poin > 0 ? SC.errorText : SC.successText),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 5),
              Text(value, style: sty(19, FontWeight.w800, color)),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: sty(10.5, FontWeight.w600, SC.inkSecondary)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Kartu & baris
  // ---------------------------------------------------------------------
  Widget _card({
    required String title,
    required IconData icon,
    required List<Widget> children,
    String? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SC.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SC.border),
        boxShadow: softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: SC.sage, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 19, color: SC.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: sty(15, FontWeight.w800, SC.ink))),
              if (trailing != null) SPill(trailing, bg: SC.goldSurface, fg: SC.goldDark, border: SC.gold.withOpacity(0.4)),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: SC.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: SC.inkMuted),
          const SizedBox(width: 10),
          SizedBox(width: 96, child: Text(label, style: sty(12, FontWeight.w500, SC.inkSecondary))),
          Expanded(
            child: Text(value, style: sty(13, FontWeight.w700, SC.ink, h: 1.3)),
          ),
        ],
      ),
    );
  }

  Widget _emptyRow(String text, IconData icon, {Color color = SC.inkSecondary}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: SC.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SC.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: sty(12.5, FontWeight.w600, SC.inkSecondary))),
        ],
      ),
    );
  }

  Widget _tahfidzItem(Map<String, dynamic> c) {
    final catatan = _str(c['catatanUstadz'], '');
    final tgl = _tgl(c['tanggalSetor']);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SC.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SC.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: SC.goldSurface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: SC.gold.withOpacity(0.45)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('JUZ', style: sty(8.5, FontWeight.w800, SC.goldDark, ls: 0.6)),
                Text(_str(c['juz']), style: sty(17, FontWeight.w800, SC.goldDark, h: 1.05)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Halaman ${_str(c['halaman'])}',
                          style: sty(13.5, FontWeight.w800, SC.ink)),
                    ),
                    if (tgl.isNotEmpty)
                      Text(tgl, style: sty(11, FontWeight.w600, SC.inkSecondary)),
                  ],
                ),
                if (catatan.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(catatan, style: sty(12, FontWeight.w500, SC.inkSecondary, h: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pelanggaranItem(Map<String, dynamic> p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SC.errorBg.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SC.errorText.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(color: SC.errorBg, shape: BoxShape.circle),
            child: const Icon(Icons.gavel_rounded, size: 18, color: SC.errorText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_str(p['jenisPelanggaran']),
                style: sty(13.5, FontWeight.w700, SC.ink, h: 1.3)),
          ),
          const SizedBox(width: 8),
          SPill('${_str(p['poin'], '0')} poin', bg: SC.surface, fg: SC.errorText, border: SC.errorText.withOpacity(0.25)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  Widget _content(Map<String, dynamic> d) {
    final tahfidz = _list(d['capaianTahfidzs']);
    final pelanggaran = _list(d['pelanggarans']);
    final totalPoin = pelanggaran.fold<int>(
        0, (sum, p) => sum + (num.tryParse(p['poin']?.toString() ?? '')?.toInt() ?? 0));
    final asrama = _str(d['asrama'], '');

    return RefreshIndicator(
      color: SC.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 28 + MediaQuery.of(context).padding.bottom),
        children: [
          _hero(d, setoran: tahfidz.length, poin: totalPoin),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _card(
                  title: 'Identitas',
                  icon: Icons.badge_rounded,
                  children: [
                    _row(Icons.tag_rounded, 'NIS', _str(d['nis'])),
                    _row(Icons.person_outline, 'Nama', _str(d['nama'])),
                    _row(Icons.wc_rounded, 'Jenis kelamin', _jk(d['jenisKelamin'])),
                    _row(Icons.class_outlined, 'Kelas', _str((d['kelas'] as Map?)?['namaKelas'])),
                    if (asrama.isNotEmpty) _row(Icons.bed_outlined, 'Asrama', asrama),
                    _row(Icons.event_available_outlined, 'Tahun masuk', _str(d['tahunMasuk'])),
                    _row(Icons.people_outline, 'Wali', _str((d['wali'] as Map?)?['nama']),
                        last: true),
                  ],
                ),
                const SizedBox(height: 14),
                _card(
                  title: 'Capaian tahfidz',
                  icon: Icons.menu_book_rounded,
                  trailing: tahfidz.isEmpty ? null : '${tahfidz.length} setoran',
                  children: tahfidz.isEmpty
                      ? [_emptyRow('Belum ada capaian tahfidz.', Icons.inbox_outlined)]
                      : [for (final c in tahfidz) _tahfidzItem(c)],
                ),
                const SizedBox(height: 14),
                _card(
                  title: 'Pelanggaran',
                  icon: Icons.gavel_rounded,
                  trailing: pelanggaran.isEmpty ? null : '$totalPoin poin',
                  children: pelanggaran.isEmpty
                      ? [
                          _emptyRow('Tidak ada pelanggaran. Pertahankan!',
                              Icons.check_circle_outline,
                              color: SC.successText)
                        ]
                      : [for (final p in pelanggaran) _pelanggaranItem(p)],
                ),
              ],
            ),
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
      // Loading / error pertama kali: tombol kembali + status.
      body = SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(alignment: Alignment.centerLeft, child: HeroBackButton(onDark: false)),
            ),
            Expanded(child: _error != null ? errorView(_error!, _load) : loadingView()),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: SC.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: body,
        ),
      ),
    );
  }
}